import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:walt/data/local/account_dao.dart';
import 'package:walt/data/local/budget_dao.dart';
import 'package:walt/data/local/database_helper.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:walt/data/models/walt_account.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/features/settings/services/appinfo.dart';

/// A file that has been written and handed to the platform share sheet.
class DataExportSummary {
  const DataExportSummary({
    required this.fileName,
    required this.transactionCount,
  });

  final String fileName;
  final int transactionCount;
}

/// Produces portable copies of the user's data.
///
/// Walt keeps its data in two places: SQLite (transactions, accounts, budgets
/// and period snapshots) and Hive (settings and categories). A database-only
/// backup would silently drop categories and preferences, so the JSON backup
/// reads both stores. Files are written inside the app's documents directory —
/// never uploaded — and then opened in the share sheet so the user can save or
/// send them wherever they prefer.
class DataExportService {
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

  static const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

  /// Exports every transaction as a spreadsheet-friendly CSV and shares it.
  ///
  /// Category, account and budget names are resolved into readable columns;
  /// ids would only help a machine, and the app's own backup already covers
  /// lossless data.
  Future<DataExportSummary> exportTransactionsCsv() async {
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
            _csv(transaction.amount.toStringAsFixed(2)),
            _csv(currency),
            _csv(
              categoryNames[transaction.categoryId] ??
                  'Category ${transaction.categoryId}',
            ),
            _csv(_accountLabel(transaction, accountNames)),
            _csv(_budgetLabel(transaction, budgetNames)),
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

    return DataExportSummary(
      fileName: fileName,
      transactionCount: transactions.length,
    );
  }

  /// Writes a complete JSON backup of both stores and shares it.
  ///
  /// The envelope is self-describing (`format` + `formatVersion`) so a restore
  /// flow can validate a file before touching any data, and it records the
  /// database and app versions that produced it. Custom category artwork and
  /// the profile picture are embedded as base64 under documents-relative paths
  /// so the backup is not left pointing at files on one device.
  Future<DataExportSummary> createBackup() async {
    await _hiveService.ensureSettingsOpen();
    final db = await DatabaseHelper.instance.database;
    final documents = await getApplicationDocumentsDirectory();
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
    final versionRows = await db.rawQuery('PRAGMA user_version');
    final databaseVersion =
        (versionRows.first['user_version'] as num?)?.toInt() ?? 0;

    final payload = <String, dynamic>{
      'format': 'walt.backup',
      'formatVersion': 1,
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

    final fileName = 'walt-backup-${_stamp()}.json';
    final file = await _writeExport(
      'backups',
      fileName,
      _prettyJson.convert(payload),
    );

    await _share(
      file,
      mimeType: 'application/json',
      subject: 'Walt backup',
      text:
          'Walt backup from ${_displayDate()} — '
          '$transactionCount transactions.',
    );

    return DataExportSummary(
      fileName: fileName,
      transactionCount: transactionCount,
    );
  }

  String _accountLabel(
    WaltTransaction transaction,
    Map<int, String> accountNames,
  ) {
    final id = transaction.accountId;
    if (id == null) return '';
    return accountNames[id] ?? 'Account $id';
  }

  String _budgetLabel(
    WaltTransaction transaction,
    Map<int, String> budgetNames,
  ) {
    final id = transaction.budgetId;
    if (id == null) return '';
    return budgetNames[id] ?? '';
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

  String? _relativeToDocuments(String path, String documentsPath) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;

    final normalized = p.normalize(trimmed);
    if (!p.isAbsolute(normalized)) return normalized;

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
      debugPrint('DataExportService: app version unavailable — $error');
      return 'unknown';
    }
  }
}
