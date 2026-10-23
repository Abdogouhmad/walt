import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import 'package:walt/data/local/account_dao.dart';
import 'package:walt/data/local/budget_dao.dart';
import 'package:walt/data/local/database_helper.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:walt/data/models/walt_account.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/data/services/pdf_export_service.dart';
import 'package:walt/features/settings/services/appinfo.dart';

/// The result of writing an export or a backup.
class DataTransferSummary {
  const DataTransferSummary({required this.transactionCount});

  final int transactionCount;
}

/// A backup file that has been read and validated but not applied yet.
///
/// Parsing everything up front means the confirmation dialog can describe the
/// file truthfully, and a malformed backup is rejected before any current data
/// is touched.
class BackupPreview {
  const BackupPreview({
    required this.path,
    required this.fileName,
    required this.createdAt,
    required this.appVersion,
    required this.tables,
    required this.settings,
    required this.categories,
    required this.files,
  });

  final String path;
  final String fileName;
  final DateTime? createdAt;
  final String? appVersion;

  /// Raw rows for every table in the backup, keyed by table name.
  final Map<String, List<Map<String, dynamic>>> tables;

  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> categories;

  /// Documents-relative path to base64 bytes for user-created artwork.
  final Map<String, String> files;

  int get transactionCount => tables['transactions']?.length ?? 0;
  int get accountCount => tables['accounts']?.length ?? 0;
  int get budgetCount => tables['budgets']?.length ?? 0;
  int get categoryCount => categories.length;

  String get createdLabel => createdAt == null
      ? 'Unknown date'
      : DateFormat('d MMM yyyy, HH:mm').format(createdAt!);

  String get summary {
    final parts = <String>[
      _plural(transactionCount, 'transaction'),
      if (accountCount > 0) _plural(accountCount, 'account'),
      if (budgetCount > 0) _plural(budgetCount, 'budget'),
      if (categoryCount > 0) _plural(categoryCount, 'category'),
    ];
    return parts.join(' · ');
  }

  static String _plural(int count, String singular) =>
      count == 1 ? '1 $singular' : '$count ${singular}s';
}

/// A completed restore.
class RestoreResult {
  const RestoreResult({
    required this.transactionCount,
    required this.filesRestored,
    required this.safetyBackupPath,
    required this.safetyBackupFileName,
  });

  final int transactionCount;
  final int filesRestored;

  /// A full backup of the data that was replaced, written before the restore.
  final String safetyBackupPath;
  final String safetyBackupFileName;
}

/// A user-facing failure while reading or applying a backup.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Produces portable copies of the user's data, and applies them back.
///
/// Walt keeps its data in two places: SQLite (transactions, accounts, budgets
/// and period snapshots) and Hive (settings and categories). A database-only
/// backup would silently drop categories and preferences, so the JSON backup
/// reads both stores. Files are written inside the app's documents directory —
/// never uploaded — and then opened in the share sheet so the user can save or
/// send them wherever they prefer.
class DataTransferService {
  final TransactionDao _transactionDao = TransactionDao();
  final AccountDao _accountDao = AccountDao();
  final BudgetDao _budgetDao = BudgetDao();
  final HiveService _hiveService = HiveService.instance;

  /// Every SQLite table that holds user data. Backups read these as raw rows so
  /// a column added later is not lost to a model that has not learned it yet.
  static const List<String> _tables = <String>[
    'categories',
    'accounts',
    'budgets',
    'budget_period_snapshots',
    'transactions',
  ];

  /// Deleting children first keeps a restore safe even if a build enables
  /// SQLite's foreign-key enforcement.
  static const List<String> _deleteOrder = <String>[
    'transactions',
    'budget_period_snapshots',
    'budgets',
    'accounts',
    'categories',
  ];

  static const int _backupFormatVersion = 1;

  static const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

  /// Exports every transaction as a spreadsheet-friendly CSV and shares it.
  ///
  /// Category, account and budget names are resolved into readable columns;
  /// ids would only help a machine, and the app's own backup already covers
  /// lossless data.
  Future<DataTransferSummary> exportTransactionsCsv() async {
    await _hiveService.ensureSettingsOpen();
    final transactions = await _transactionDao.getAllTransactions();
    final categories = await _hiveService.getAllCategories();
    final accounts = await _accountDao.getAllAccounts();
    final budgets = await _budgetDao.getAllBudgets();
    final currency = _hiveService.getCurrency();

    final categoryNames = <int, String>{
      for (final category in categories) category.id: category.name,
    };
    final accountNames = <int, String>{
      for (final account in accounts) account.id: account.name,
    };
    final budgetNames = <int, String>{
      for (final budget in budgets)
        budget.id: _budgetName(budget, categoryNames),
    };
    final budgetsByCategory = <int, List<String>>{};
    for (final budget in budgets) {
      final name = budgetNames[budget.id]!;
      for (final categoryId in budget.effectiveCategoryIds) {
        budgetsByCategory.putIfAbsent(categoryId, () => <String>[]).add(name);
      }
    }

    final csv = StringBuffer()
      // Excel only detects UTF-8 automatically when the BOM is present, which
      // matters for accents and non-Latin category names.
      ..write('\uFEFF')
      ..write('Date,Type,Amount,Currency,Category,Account,Budget,Merchant,Note')
      ..write('\r\n');

    for (final transaction in transactions) {
      csv
        ..write(
          <String>[
            _csv(DateFormat('yyyy-MM-dd HH:mm').format(transaction.date)),
            _csv(transaction.type),
            // Keep the stored precision: the backup is exact, and a CSV that
            // rounds 12.345 to 12.35 quietly disagrees with the app.
            _csv(transaction.amount.toString()),
            _csv(currency),
            _csv(
              categoryNames[transaction.categoryId] ??
                  'Category ${transaction.categoryId}',
            ),
            _csv(_accountLabel(transaction, accountNames)),
            _csv(_budgetLabel(transaction, budgetNames, budgetsByCategory)),
            _csv(transaction.merchant ?? ''),
            _csv(transaction.note ?? ''),
          ].join(','),
        )
        ..write('\r\n');
    }

    final fileName = 'walt-transactions-${_stamp()}.csv';
    final file = await _writeExport('exports', fileName, csv.toString());

    await _share(
      file,
      mimeType: 'text/csv',
      subject: 'Walt transaction export',
      text: 'Walt transactions exported on ${_displayDate()}.',
    );

    return DataTransferSummary(transactionCount: transactions.length);
  }

  /// Exports every transaction as a printable PDF and shares it.
  Future<DataTransferSummary> exportTransactionsPdf() async {
    final count = await PdfExportService().exportAllToPdf();
    return DataTransferSummary(transactionCount: count);
  }

  /// Writes a complete JSON backup of both stores and shares it.
  Future<DataTransferSummary> createBackup() async {
    final backup = await _writeCurrentDataBackup(prefix: 'walt-backup');

    await _share(
      backup.file,
      mimeType: 'application/json',
      subject: 'Walt backup',
      text:
          'Walt backup from ${_displayDate()} — '
          '${backup.transactionCount} transactions.',
    );

    return DataTransferSummary(transactionCount: backup.transactionCount);
  }

  /// Opens the platform file picker and validates the chosen backup.
  ///
  /// Returns null when the user cancels. Throws [BackupException] with a
  /// user-facing message when the file is not a usable Walt backup.
  Future<BackupPreview?> pickBackup() async {
    const typeGroup = XTypeGroup(
      label: 'Walt backup',
      extensions: <String>['json'],
      mimeTypes: <String>['application/json'],
      uniformTypeIdentifiers: <String>['public.json'],
    );

    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[typeGroup],
      confirmButtonText: 'Restore',
    );
    if (file == null) return null;
    return readBackup(file.path);
  }

  /// Parses and validates a backup without modifying anything.
  Future<BackupPreview> readBackup(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const BackupException('That file is no longer available.');
    }

    final Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        throw const FormatException('Backup root is not an object');
      }
      payload = Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw const BackupException('That file is not a Walt backup.');
    } on FileSystemException {
      throw const BackupException('Could not read that file.');
    }

    if (payload['format'] != 'walt.backup') {
      throw const BackupException('That file is not a Walt backup.');
    }

    final formatVersion = payload['formatVersion'];
    if (formatVersion is! int || formatVersion < 1) {
      throw const BackupException('That backup is missing its format version.');
    }
    if (formatVersion > _backupFormatVersion) {
      throw const BackupException(
        'This backup was made by a newer version of Walt. '
        'Update the app before restoring it.',
      );
    }

    final tablesRaw = payload['tables'];
    final hiveRaw = payload['hive'];
    if (tablesRaw is! Map || hiveRaw is! Map) {
      throw const BackupException('That backup is missing its data.');
    }

    final hive = Map<String, dynamic>.from(hiveRaw);
    final settingsRaw = hive['settings'];
    final categoriesRaw = hive['categories'];
    if (settingsRaw is! Map || categoriesRaw is! List) {
      throw const BackupException('That backup is missing its settings.');
    }

    final settings = Map<String, dynamic>.from(settingsRaw);
    final categories = <Map<String, dynamic>>[];
    for (final item in categoriesRaw) {
      if (item is! Map) {
        throw const BackupException('That backup has damaged category data.');
      }
      final json = Map<String, dynamic>.from(item);
      try {
        WaltCategory.fromJson(json);
      } catch (_) {
        throw const BackupException('That backup has damaged category data.');
      }
      categories.add(json);
    }

    final tables = <String, List<Map<String, dynamic>>>{};
    for (final table in _tables) {
      final rawRows = tablesRaw[table];
      if (rawRows is! List) {
        throw BackupException('That backup is missing its $table data.');
      }
      final rows = <Map<String, dynamic>>[];
      for (final row in rawRows) {
        if (row is! Map) {
          throw BackupException('That backup has damaged $table data.');
        }
        rows.add(Map<String, dynamic>.from(row));
      }
      tables[table] = rows;
    }

    // A newer schema can contain columns this build does not know how to write.
    // Reject it instead of silently dropping data during the restore.
    final backupDbVersion = payload['databaseVersion'];
    if (backupDbVersion is int) {
      final currentDbVersion = await _databaseVersion();
      if (backupDbVersion > currentDbVersion) {
        throw const BackupException(
          'This backup was made by a newer version of Walt. '
          'Update the app before restoring it.',
        );
      }
    }

    final files = <String, String>{};
    final filesRaw = payload['files'];
    if (filesRaw != null) {
      if (filesRaw is! Map) {
        throw const BackupException('That backup has damaged image data.');
      }
      for (final entry in filesRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! String || !_isSafeRelativePath(key)) {
          throw const BackupException('That backup has an unsafe file path.');
        }
        files[key] = value;
      }
      // Decode every payload now, while the file is only a preview. A damaged
      // image is then a reason to refuse the backup, not a surprise halfway
      // through replacing the real data.
      for (final value in files.values) {
        _decodeBase64(value);
      }
    }

    final createdAtRaw = payload['createdAt'];
    final appVersion = payload['appVersion'];

    return BackupPreview(
      path: path,
      fileName: p.basename(path),
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw)
          : null,
      appVersion: appVersion is String ? appVersion : null,
      tables: tables,
      settings: settings,
      categories: categories,
      files: files,
    );
  }

  /// Replaces all current data with [preview].
  ///
  /// A full safety backup of what is being replaced is written first. The
  /// SQLite restore runs in one transaction, so a bad row cannot leave a
  /// half-deleted ledger. Hive and the referenced images are applied after the
  /// database succeeds.
  Future<RestoreResult> restoreBackup(BackupPreview preview) async {
    await _hiveService.ensureSettingsOpen();
    final documents = await getApplicationDocumentsDirectory();

    // Snapshot before the first destructive write. This is what makes a wrong
    // file recoverable, and it is shared from the completion dialog so the
    // user can keep a copy outside the app sandbox.
    final safety = await _writeCurrentDataBackup(prefix: 'walt-pre-restore');

    final settings = Map<String, dynamic>.from(preview.settings);
    final categories = <WaltCategory>[
      for (final json in preview.categories)
        WaltCategory.fromJson(Map<String, dynamic>.from(json)),
    ];
    final tables = <String, List<Map<String, dynamic>>>{
      for (final entry in preview.tables.entries)
        entry.key: <Map<String, dynamic>>[
          for (final row in entry.value) Map<String, dynamic>.from(row),
        ],
    };
    final files = Map<String, String>.from(preview.files);

    _rerootFilePaths(
      settings: settings,
      categories: categories,
      accounts: tables['accounts'] ?? const <Map<String, dynamic>>[],
      availableFiles: files.keys.toSet(),
      documentsPath: documents.path,
    );

    final db = await DatabaseHelper.instance.database;
    final schema = await _readSchema(db);

    try {
      await db.transaction((txn) async {
        for (final table in _deleteOrder) {
          await txn.delete(table);
        }

        for (final table in _tables) {
          final rows = tables[table] ?? const <Map<String, dynamic>>[];
          final tableSchema = schema[table];
          if (tableSchema == null) continue;

          for (final row in rows) {
            final values = <String, Object?>{};
            for (final entry in row.entries) {
              if (!tableSchema.columns.contains(entry.key)) continue;
              values[entry.key] =
                  tableSchema.blobColumns.contains(entry.key) &&
                      entry.value is String
                  ? _decodeBase64(entry.value! as String)
                  : entry.value;
            }
            if (values.isEmpty) continue;
            await txn.insert(
              table,
              values,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
    } catch (error, stackTrace) {
      debugPrint(
        'DataTransferService: database restore failed — $error\n$stackTrace',
      );
      throw const BackupException(
        'That backup could not be restored. Your current data was not changed.',
      );
    }

    try {
      final settingsBox = _hiveService.settingsBox;
      await settingsBox.clear();
      await settingsBox.putAll(settings);
      // The backup was written after migration, but normalising again keeps a
      // hand-edited or older file from resurrecting removed keys.
      await _hiveService.migrateThemeSettings();
      await _hiveService.saveCategories(categories);
    } catch (error, stackTrace) {
      debugPrint(
        'DataTransferService: settings restore failed — $error\n$stackTrace',
      );
      throw const BackupException(
        'The records were restored, but your settings could not be. '
        'A safety copy of the previous data was saved first.',
      );
    }

    // Images are written after the stores succeed. The backup was validated
    // before the confirmation dialog, so a rejected restore never overwrites
    // the artwork that the current data still points at.
    int filesRestored;
    try {
      filesRestored = await _restoreFiles(files, documents);
    } on BackupException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint(
        'DataTransferService: image restore failed — $error\n$stackTrace',
      );
      throw const BackupException(
        'Your records were restored, but some images could not be. '
        'A safety copy of the previous data was saved first.',
      );
    }

    return RestoreResult(
      transactionCount: tables['transactions']?.length ?? 0,
      filesRestored: filesRestored,
      safetyBackupPath: safety.file.path,
      safetyBackupFileName: p.basename(safety.file.path),
    );
  }

  /// Shares a backup that the app wrote itself, such as a safety copy.
  Future<void> shareLocalBackup(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const BackupException('That safety copy is no longer available.');
    }
    await _share(
      file,
      mimeType: 'application/json',
      subject: 'Walt safety backup',
      text: 'Walt safety backup of your previous data.',
    );
  }

  Future<_LocalBackup> _writeCurrentDataBackup({required String prefix}) async {
    await _hiveService.ensureSettingsOpen();
    final db = await DatabaseHelper.instance.database;
    final documents = await getApplicationDocumentsDirectory();
    final payload = await _buildBackupPayload(db: db, documents: documents);

    final fileName = '$prefix-${_stamp()}.json';
    final file = await _writeExport(
      'backups',
      fileName,
      _prettyJson.convert(payload),
    );
    return _LocalBackup(
      file: file,
      transactionCount: (payload['transactionCount'] as int?) ?? 0,
    );
  }

  Future<Map<String, dynamic>> _buildBackupPayload({
    required Database db,
    required Directory documents,
  }) async {
    final categories = await _hiveService.getAllCategories();
    final accounts = await _accountDao.getAllAccounts();

    final tables = <String, List<Map<String, dynamic>>>{};
    for (final table in _tables) {
      final rows = await db.query(table);
      tables[table] = <Map<String, dynamic>>[
        for (final row in rows) _encodeRow(row),
      ];
    }

    final transactionCount = tables['transactions']?.length ?? 0;
    final files = await _readReferencedFiles(
      documents: documents,
      categories: categories,
      accounts: accounts,
    );
    final databaseVersion = await _databaseVersionFrom(db);

    return <String, dynamic>{
      'format': 'walt.backup',
      'formatVersion': _backupFormatVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'appVersion': _appVersion(),
      'databaseVersion': databaseVersion,
      'transactionCount': transactionCount,
      'counts': <String, dynamic>{
        for (final entry in tables.entries) entry.key: entry.value.length,
        'categories': categories.length,
      },
      'tables': tables,
      'hive': <String, dynamic>{
        'settings': _encodeMap(_hiveService.settingsBox.toMap()),
        'categories': <dynamic>[
          for (final category in categories) _encodeValue(category),
        ],
      },
      if (files.isNotEmpty) 'files': files,
    };
  }

  String _accountLabel(
    WaltTransaction transaction,
    Map<int, String> accountNames,
  ) {
    final id = transaction.accountId;
    if (id == null) return '';
    return accountNames[id] ?? 'Account $id';
  }

  /// The explicitly linked budget, or every category-matched budget for legacy
  /// transactions that were recorded before explicit links existed.
  String _budgetLabel(
    WaltTransaction transaction,
    Map<int, String> budgetNames,
    Map<int, List<String>> budgetsByCategory,
  ) {
    final id = transaction.budgetId;
    if (id != null) return budgetNames[id] ?? '';
    return budgetsByCategory[transaction.categoryId]?.join(' / ') ?? '';
  }

  static String _budgetName(WaltBudget budget, Map<int, String> categoryNames) {
    final name = budget.name.trim();
    if (name.isNotEmpty) return name;

    final names = <String>[];
    for (final id in budget.effectiveCategoryIds) {
      final categoryName = categoryNames[id];
      if (categoryName != null) names.add(categoryName);
    }

    return names.isEmpty ? 'Budget ${budget.id}' : names.join(' · ');
  }

  /// RFC 4180 field escaping: quote only when the value would break the row.
  static String _csv(String value) {
    final needsQuotes =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  Future<File> _writeExport(
    String folder,
    String fileName,
    String contents,
  ) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'walt', folder));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(contents, flush: true);
    return file;
  }

  Future<void> _share(
    File file, {
    required String mimeType,
    required String subject,
    required String text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: mimeType)],
        subject: subject,
        text: text,
      ),
    );
  }

  Map<String, dynamic> _encodeRow(Map<String, Object?> row) {
    return <String, dynamic>{
      for (final entry in row.entries)
        entry.key: entry.value is List<int>
            ? base64Encode(entry.value! as List<int>)
            : entry.value,
    };
  }

  Map<String, dynamic> _encodeMap(Map<dynamic, dynamic> source) {
    return <String, dynamic>{
      for (final entry in source.entries)
        entry.key.toString(): _encodeValue(entry.value),
    };
  }

  /// Converts Hive's untyped values into something `jsonEncode` accepts.
  dynamic _encodeValue(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is WaltCategory) return value.toJson();
    if (value is Enum) return value.name;
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) return _encodeMap(value);
    if (value is Iterable) {
      return <dynamic>[for (final item in value) _encodeValue(item)];
    }
    return value.toString();
  }

  /// Reads the user-created images that the data references.
  ///
  /// Only files inside the documents directory are embedded: an absolute path
  /// outside it belongs to a picker cache and would not survive a reinstall
  /// anyway. Keys are documents-relative so a restore can re-root them.
  Future<Map<String, String>> _readReferencedFiles({
    required Directory documents,
    required List<WaltCategory> categories,
    required List<WaltAccount> accounts,
  }) async {
    final paths = <String>{};

    for (final category in categories) {
      if (category.imageSource == CategoryImageSource.file &&
          category.hasImage) {
        final relative = _relativeToDocuments(
          category.imagePath!,
          documents.path,
        );
        if (relative != null) paths.add(relative);
      }
    }

    final profile = _hiveService.getProfilePicPath();
    if (profile != null && profile.trim().isNotEmpty) {
      final relative = _relativeToDocuments(profile, documents.path);
      if (relative != null) paths.add(relative);
    }

    for (final account in accounts) {
      final picture = account.profilePic;
      if (picture == null || picture.trim().isEmpty) continue;
      final relative = _relativeToDocuments(picture, documents.path);
      if (relative != null) paths.add(relative);
    }

    final files = <String, String>{};
    for (final relative in paths) {
      final absolute = p.isAbsolute(relative)
          ? relative
          : p.join(documents.path, relative);
      final file = File(absolute);
      if (!await file.exists()) continue;
      files[relative] = base64Encode(await file.readAsBytes());
    }
    return files;
  }

  /// Rewrites document paths in the backup to the current sandbox.
  ///
  /// A backup may have been made before a reinstall, when the app's documents
  /// directory had a different absolute prefix. Categories already store a
  /// relative path; the profile picture and account pictures store absolute
  /// ones, so they are matched back to their file entry and re-rooted.
  void _rerootFilePaths({
    required Map<String, dynamic> settings,
    required List<WaltCategory> categories,
    required List<Map<String, dynamic>> accounts,
    required Set<String> availableFiles,
    required String documentsPath,
  }) {
    if (availableFiles.isEmpty) return;

    final profile = settings['profilePicPath'];
    if (profile is String) {
      final key = _matchingFileKey(profile, availableFiles);
      if (key != null) {
        settings['profilePicPath'] = p.join(documentsPath, key);
      }
    }

    for (final account in accounts) {
      final picture = account['profile_pic'];
      if (picture is! String) continue;
      final key = _matchingFileKey(picture, availableFiles);
      if (key != null) {
        account['profile_pic'] = p.join(documentsPath, key);
      }
    }

    for (var i = 0; i < categories.length; i++) {
      final category = categories[i];
      if (category.imageSource != CategoryImageSource.file ||
          !category.hasImage) {
        continue;
      }
      final key = _matchingFileKey(category.imagePath!, availableFiles);
      if (key != null) {
        categories[i] = category.copyWith(imagePath: key);
      }
    }
  }

  static String? _matchingFileKey(String stored, Set<String> keys) {
    final normalized = p.normalize(stored.trim());
    if (normalized.isEmpty) return null;

    for (final key in keys) {
      final normalizedKey = p.normalize(key);
      if (normalized == normalizedKey ||
          normalized.endsWith('${p.separator}$normalizedKey')) {
        return key;
      }
    }
    return null;
  }

  Future<int> _restoreFiles(
    Map<String, String> files,
    Directory documents,
  ) async {
    // Decode every image before writing the first one. A backup with one
    // damaged payload then fails while the current data and images are still
    // untouched, instead of stopping halfway through the set.
    final decoded = <String, List<int>>{};
    for (final entry in files.entries) {
      if (!_isSafeRelativePath(entry.key)) {
        throw const BackupException('That backup has an unsafe file path.');
      }

      final target = p.normalize(p.join(documents.path, entry.key));
      if (!p.isWithin(documents.path, target)) {
        throw const BackupException('That backup has an unsafe file path.');
      }

      decoded[entry.key] = _decodeBase64(entry.value);
    }

    var restored = 0;
    for (final entry in decoded.entries) {
      final file = File(p.normalize(p.join(documents.path, entry.key)));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value, flush: true);
      restored++;
    }
    return restored;
  }

  static List<int> _decodeBase64(String value) {
    try {
      return base64Decode(value);
    } on FormatException {
      throw const BackupException(
        'A file inside that backup is damaged and cannot be restored.',
      );
    }
  }

  static bool _isSafeRelativePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || p.isAbsolute(trimmed)) return false;

    final normalized = p.normalize(trimmed);
    return normalized != '..' &&
        !normalized.startsWith('..${p.separator}') &&
        !p.isAbsolute(normalized);
  }

  Future<Map<String, _TableSchema>> _readSchema(Database db) async {
    final schema = <String, _TableSchema>{};
    for (final table in _tables) {
      final rows = await db.rawQuery('PRAGMA table_info($table)');
      final columns = <String>{};
      final blobColumns = <String>{};
      for (final row in rows) {
        final name = row['name'];
        if (name is! String) continue;
        columns.add(name);
        final type = row['type'];
        if (type is String && type.toUpperCase().contains('BLOB')) {
          blobColumns.add(name);
        }
      }
      schema[table] = _TableSchema(columns: columns, blobColumns: blobColumns);
    }
    return schema;
  }

  Future<int> _databaseVersion() async {
    final db = await DatabaseHelper.instance.database;
    return _databaseVersionFrom(db);
  }

  static Future<int> _databaseVersionFrom(Database db) async {
    final rows = await db.rawQuery('PRAGMA user_version');
    return (rows.first['user_version'] as num?)?.toInt() ?? 0;
  }

  String? _relativeToDocuments(String path, String documentsPath) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;

    final normalized = p.normalize(trimmed);
    if (!p.isAbsolute(normalized)) {
      // A relative value is expected to live under the documents directory.
      // Refusing traversal here keeps a damaged store from embedding arbitrary
      // files from elsewhere on the device into a backup.
      return _isSafeRelativePath(normalized) ? normalized : null;
    }

    final documents = p.normalize(documentsPath);
    if (!p.isWithin(documents, normalized)) return null;
    return p.relative(normalized, from: documents);
  }

  static String _stamp() =>
      DateFormat('yyyy-MM-dd-HHmmss').format(DateTime.now());

  static String _displayDate() =>
      DateFormat('d MMM yyyy, HH:mm').format(DateTime.now());

  static String _appVersion() {
    try {
      return Appinfo.version;
    } catch (error) {
      debugPrint('DataTransferService: app version unavailable — $error');
      return 'unknown';
    }
  }
}

class _LocalBackup {
  const _LocalBackup({required this.file, required this.transactionCount});

  final File file;
  final int transactionCount;
}

class _TableSchema {
  const _TableSchema({required this.columns, required this.blobColumns});

  final Set<String> columns;
  final Set<String> blobColumns;
}
