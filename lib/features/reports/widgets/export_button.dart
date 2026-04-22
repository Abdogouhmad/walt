import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/data/services/pdf_export_service.dart';
import 'package:walt/shared/text_ui.dart';

class ExportPdfButton extends ConsumerWidget {
  const ExportPdfButton({super.key});

  Future<void> _selectMonthAndExport(BuildContext context) async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = now.year;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Month & Year'),
              content: SizedBox(
                width: 300,
                height: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Year: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<int>(
                          value: selectedYear,
                          items:
                              List.generate(11, (index) => now.year - 5 + index)
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text(y.toString()),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (y) => setState(() => selectedYear = y!),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.5,
                            ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final date = DateTime(selectedYear, month);
                          final isFuture = date.isAfter(now);
                          final monthName = DateFormat('MMM').format(date);

                          return TextButton(
                            onPressed: isFuture
                                ? null
                                : () => Navigator.pop(
                                    context,
                                    DateTime(selectedYear, month),
                                  ),
                            child: Text(
                              monthName,
                              style: TextStyle(
                                color: isFuture ? Colors.grey : null,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colorAppScheme.primaryContainer,
          content: UiText(
            text:
                'Generating PDF for ${DateFormat('MMMM yyyy').format(picked)}...',
            type: UiTextType.bodyMedium,
            style: TextStyle(color: context.colorAppScheme.primary),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      try {
        await PdfExportService().exportMonthToPdf(picked.year, picked.month);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.colorAppScheme.primaryContainer,
            content: UiText(
              text: 'Error generating PDF: $e',
              type: UiTextType.bodyMedium,
              style: TextStyle(color: context.colorAppScheme.primary),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton.filledTonal(
      autofocus: false,
      icon: const Icon(Icons.share_rounded),
      tooltip: 'Export to PDF',
      onPressed: () => _selectMonthAndExport(context),
    );
  }
}
