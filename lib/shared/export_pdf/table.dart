import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';

class PdfTable extends pw.StatelessWidget {
  final List<WaltTransaction> transactions;
  final Map<int, WaltCategory> categoryMap;
  final String currency;

  PdfTable({
    required this.transactions,
    required this.categoryMap,
    required this.currency,
  });

  @override
  pw.Widget build(pw.Context context) {
    if (transactions.isEmpty) {
      return pw.Center(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 40),
          child: pw.Text(
            'No transactions recorded for this month.',
            style: pw.TextStyle(
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey500,
            ),
          ),
        ),
      );
    }

    final format = NumberFormat.currency(
      symbol: '$currency ',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd MMM yyyy');

    return pw.Table(
      border: null,
      columnWidths: {
        0: const pw.FixedColumnWidth(70),
        1: const pw.FixedColumnWidth(90),
        2: const pw.FlexColumnWidth(),
        3: const pw.FixedColumnWidth(100),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.blueGrey50,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(4),
              topRight: pw.Radius.circular(4),
            ),
          ),
          children: [
            _buildHeaderCell('Date'),
            _buildHeaderCell('Category'),
            _buildHeaderCell('Note/Merchant'),
            _buildHeaderCell('Amount', align: pw.Alignment.centerRight),
          ],
        ),
        // Rows
        ...transactions.map((tx) {
          final category = categoryMap[tx.categoryId];
          final isIncome = tx.type == 'income';

          return pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey200, width: .5),
              ),
            ),
            children: [
              _buildCell(dateFormat.format(tx.date)),
              _buildCell(category?.name ?? 'Unknown'),
              _buildCell(tx.note ?? tx.merchant ?? '-'),
              _buildCell(
                '${isIncome ? '+' : '-'} ${format.format(tx.amount)}',
                align: pw.Alignment.centerRight,
                color: isIncome ? PdfColors.green800 : PdfColors.red800,
                weight: pw.FontWeight.bold,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildHeaderCell(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildCell(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
    PdfColor color = PdfColors.black,
    pw.FontWeight? weight,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 9, color: color, fontWeight: weight),
        ),
      ),
    );
  }
}
