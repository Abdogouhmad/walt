import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfSummary extends pw.StatelessWidget {
  final double income;
  final double expense;
  final String currency;

  PdfSummary({
    required this.income,
    required this.expense,
    required this.currency,
  });

  @override
  pw.Widget build(pw.Context context) {
    final format = NumberFormat.currency(
      symbol: '$currency ',
      decimalDigits: 2,
    );
    final netBalance = income - expense;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem(
            'Total Income',
            format.format(income),
            PdfColors.green700,
          ),
          pw.Container(width: 1, height: 40, color: PdfColors.grey300),
          _summaryItem(
            'Total Expense',
            format.format(expense),
            PdfColors.red700,
          ),
          pw.Container(width: 1, height: 40, color: PdfColors.grey300),
          _summaryItem(
            'Net Balance',
            format.format(netBalance),
            netBalance >= 0 ? PdfColors.blue800 : PdfColors.orange800,
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryItem(String title, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
// double income, double expense, String currency