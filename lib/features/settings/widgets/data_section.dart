import 'package:flutter/material.dart';

import 'package:walt/data/services/data_export_service.dart';
import 'package:walt/features/settings/widgets/settings_leading.dart';
import 'package:walt_ui/walt_ui.dart';

/// Export and backup actions.
///
/// Both actions write a file on-device and then hand it to the share sheet, so
/// the user decides where a copy goes. Nothing is uploaded by Walt itself.
class DataSection extends StatefulWidget {
  const DataSection({super.key});

  @override
  State<DataSection> createState() => _DataSectionState();
}

enum _DataAction { transactions, backup }

class _DataSectionState extends State<DataSection> {
  final DataExportService _service = DataExportService();
  _DataAction? _running;

  bool get _busy => _running != null;

  Future<void> _run(_DataAction action) async {
    if (_busy) return;
    setState(() => _running = action);

    try {
      final summary = switch (action) {
        _DataAction.transactions => await _service.exportTransactionsCsv(),
        _DataAction.backup => await _service.createBackup(),
      };
      if (!mounted) return;
      _showMessage(_successMessage(action, summary));
    } catch (error, stackTrace) {
      debugPrint('DataSection: ${action.name} failed — $error\n$stackTrace');
      if (!mounted) return;
      _showMessage(
        action == _DataAction.transactions
            ? 'Could not export transactions. Please try again.'
            : 'Could not create the backup. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  String _successMessage(_DataAction action, DataExportSummary summary) {
    final count = summary.transactionCount;
    final transactions = count == 1 ? '1 transaction' : '$count transactions';
    return switch (action) {
      _DataAction.transactions => 'Exported $transactions.',
      _DataAction.backup => 'Backup ready · $transactions.',
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
              title: 'Export transactions',
              subtitle: 'A CSV spreadsheet of your full history',
              isBusy: _running == _DataAction.transactions,
              onTap: _busy ? null : () => _run(_DataAction.transactions),
            ),
            _DataActionTile(
              icon: Icons.backup_rounded,
              title: 'Back up data',
              subtitle: 'All records, categories and settings',
              isBusy: _running == _DataAction.backup,
              onTap: _busy ? null : () => _run(_DataAction.backup),
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
            'Walt never uploads your data.',
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
    required this.title,
    required this.subtitle,
    required this.isBusy,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isBusy;
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
            : Icon(Icons.download_rounded, color: scheme.onSurfaceVariant),
      ),
      onTap: onTap,
    );
  }
}
