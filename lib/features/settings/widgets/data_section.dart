import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/services/data_transfer_service.dart';
import 'package:walt/features/settings/widgets/settings_leading.dart';
import 'package:walt/providers/account_provider.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/theme_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Export, backup and restore actions.
///
/// Exports and backups are written on-device and then handed to the share
/// sheet, so the user decides where a copy goes. Nothing is uploaded by Walt.
/// A restore always writes a safety copy of the replaced data first.
class DataSection extends ConsumerStatefulWidget {
  const DataSection({super.key});

  @override
  ConsumerState<DataSection> createState() => _DataSectionState();
}

enum _DataAction { csv, pdf, backup, restore }

class _DataSectionState extends ConsumerState<DataSection> {
  final DataTransferService _service = DataTransferService();
  _DataAction? _running;
  bool _restoring = false;

  bool get _busy => _running != null || _restoring;

  Future<void> _runExport(_DataAction action) async {
    if (_busy || action == _DataAction.restore) return;
    setState(() => _running = action);

    try {
      final summary = switch (action) {
        _DataAction.csv => await _service.exportTransactionsCsv(),
        _DataAction.pdf => await _service.exportTransactionsPdf(),
        _DataAction.backup => await _service.createBackup(),
        _DataAction.restore => throw StateError('Restore is not an export'),
      };
      if (!mounted) return;
      _showMessage(_successMessage(action, summary));
    } catch (error, stackTrace) {
      debugPrint('DataSection: ${action.name} failed — $error\n$stackTrace');
      if (!mounted) return;
      _showMessage(_failureMessage(action));
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  /// Picks a backup, describes it, and only then replaces any data.
  ///
  /// The preview is fully validated by [DataTransferService.readBackup], so a
  /// wrong or damaged file is rejected before the confirmation dialog appears.
  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _restoring = true);

    try {
      final preview = await _service.pickBackup();
      if (!mounted || preview == null) return;

      final confirmed = await _confirmRestore(preview);
      if (!mounted || confirmed != true) return;

      final result = await _service.restoreBackup(preview);
      if (!mounted) return;

      await _refreshAfterRestore();
      if (!mounted) return;

      await _showRestoreComplete(result);
    } on BackupException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (error, stackTrace) {
      debugPrint('DataSection: restore failed — $error\n$stackTrace');
      if (!mounted) return;
      _showMessage('Could not restore that backup. Please try again.');
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  /// Makes the restored stores visible without restarting the app.
  ///
  /// Every notifier caches what it read at startup, and the theme controller
  /// also keeps the snapshot taken in `main()`. All of them have to be refreshed
  /// or the screen would keep showing the data that was just replaced.
  Future<void> _refreshAfterRestore() async {
    // The selected home account may not exist in the restored data.
    ref.read(homeAccountIdProvider.notifier).state = null;

    await Future.wait<void>([
      ref.read(categoryProvider.notifier).refresh(),
      ref.read(accountProvider.notifier).refresh(),
      ref.read(budgetProvider.notifier).refresh(),
      ref.read(transactionProvider.notifier).refresh(),
      ref.read(themeControllerProvider.notifier).reloadFromStore(),
    ]);

    // Reports and the settings state are cheap to rebuild from their stores.
    ref.invalidate(reportProvider);
    ref.invalidate(settingsProvider);
  }

  Future<bool?> _confirmRestore(BackupPreview preview) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          icon: const Icon(Icons.restore_rounded),
          title: const Text('Restore this backup?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This replaces all current transactions, accounts, budgets, '
                  'categories, images and settings.',
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailRow(label: 'File', value: preview.fileName),
                _DetailRow(label: 'Created', value: preview.createdLabel),
                if (preview.appVersion != null)
                  _DetailRow(label: 'App version', value: preview.appVersion!),
                _DetailRow(label: 'Contents', value: preview.summary),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: scheme.onErrorContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'A safety copy of your current data is saved before '
                          'anything changes.',
                          style: Theme.of(dialogContext).textTheme.bodySmall
                              ?.copyWith(color: scheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRestoreComplete(RestoreResult result) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          icon: Icon(Icons.check_circle_rounded, color: scheme.primary),
          title: const Text('Restore complete'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your data has been replaced with the backup.'),
                const SizedBox(height: AppSpacing.md),
                _DetailRow(
                  label: 'Transactions',
                  value: '${result.transactionCount}',
                ),
                if (result.filesRestored > 0)
                  _DetailRow(label: 'Images', value: '${result.filesRestored}'),
                _DetailRow(
                  label: 'Safety copy',
                  value: result.safetyBackupFileName,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'If anything is missing, restore the safety copy above. '
                  'Sharing it keeps a copy outside the app.',
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _shareSafetyCopy(result);
              },
              child: const Text('Share safety copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareSafetyCopy(RestoreResult result) async {
    try {
      await _service.shareLocalBackup(result.safetyBackupPath);
    } on BackupException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (error, stackTrace) {
      debugPrint(
        'DataSection: sharing safety copy failed — $error\n$stackTrace',
      );
      if (!mounted) return;
      _showMessage('Could not share the safety copy.');
    }
  }

  String _successMessage(_DataAction action, DataTransferSummary summary) {
    final count = summary.transactionCount;
    final transactions = count == 1 ? '1 transaction' : '$count transactions';
    return switch (action) {
      _DataAction.csv => 'Exported $transactions as CSV.',
      _DataAction.pdf => 'Exported $transactions as PDF.',
      _DataAction.backup => 'Backup ready · $transactions.',
      _DataAction.restore => 'Restore complete.',
    };
  }

  String _failureMessage(_DataAction action) {
    return switch (action) {
      _DataAction.csv =>
        'Could not export transactions as CSV. Please try again.',
      _DataAction.pdf =>
        'Could not export transactions as PDF. Please try again.',
      _DataAction.backup => 'Could not create the backup. Please try again.',
      _DataAction.restore => 'Could not restore that backup. Please try again.',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Data'),
        GroupedList(
          children: [
            _DataActionTile(
              icon: Icons.table_chart_rounded,
              trailingIcon: Icons.download_rounded,
              title: 'Export as CSV',
              subtitle: 'Spreadsheet of your full transaction history',
              isBusy: _running == _DataAction.csv,
              onTap: _busy ? null : () => _runExport(_DataAction.csv),
            ),
            _DataActionTile(
              icon: Icons.picture_as_pdf_rounded,
              trailingIcon: Icons.download_rounded,
              title: 'Export as PDF',
              subtitle: 'Printable report of your full history',
              isBusy: _running == _DataAction.pdf,
              onTap: _busy ? null : () => _runExport(_DataAction.pdf),
            ),
            _DataActionTile(
              icon: Icons.backup_rounded,
              trailingIcon: Icons.ios_share_rounded,
              title: 'Back up data',
              subtitle: 'Records, categories, images and settings',
              isBusy: _running == _DataAction.backup,
              onTap: _busy ? null : () => _runExport(_DataAction.backup),
            ),
            _DataActionTile(
              icon: Icons.settings_backup_restore_rounded,
              trailingIcon: Icons.restore_rounded,
              title: 'Restore from backup',
              subtitle: 'Replace all data with a backup file',
              isBusy: _restoring,
              destructive: true,
              onTap: _busy ? null : _restore,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            left: AppSpacing.xs,
            right: AppSpacing.xs,
          ),
          child: Text(
            'Files are created on this device, then opened in the share sheet. '
            'Walt never uploads your data. A restore keeps a safety copy of the '
            'data it replaces.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _DataActionTile extends StatelessWidget {
  const _DataActionTile({
    required this.icon,
    required this.trailingIcon,
    required this.title,
    required this.subtitle,
    required this.isBusy,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final IconData trailingIcon;
  final String title;
  final String subtitle;
  final bool isBusy;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GroupedListTile(
      leading: SettingsLeading(icon: icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: SizedBox(
        width: 24,
        height: 24,
        child: isBusy
            ? Semantics(
                label: '$title in progress',
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Icon(
                trailingIcon,
                color: destructive ? scheme.error : scheme.onSurfaceVariant,
              ),
      ),
      onTap: onTap,
    );
  }
}

/// A label/value pair inside a dialog, able to wrap instead of overflowing.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
