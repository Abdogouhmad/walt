import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/shared/export_pdf/export_ui.dart';

class PdfExportService {
  final TransactionDao _transactionDao = TransactionDao();
  final HiveService _hiveService = HiveService.instance;

  Future<void> exportMonthToPdf(int year, int month) async {
    // 1. Fetch data
    final transactions = await _transactionDao.getTransactionsByMonth(
      year,
      month,
    );
    final categories = await _hiveService.getAllCategories();
    final categoryMap = {for (var c in categories) c.id: c};
    final currency = await _hiveService.getCurrency();

    // Sort transactions by date (descending)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    // 2. Generate PDF
    final pdf = pw.Document();

    final selectedDate = DateTime(year, month);
    final monthName = DateFormat('MMMM yyyy').format(selectedDate);

    // Calculate summaries
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          PdfHeader(monthName: monthName),
          pw.SizedBox(height: 20),
          PdfSummary(
            income: totalIncome,
            expense: totalExpense,
            currency: currency,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Transactions Activity',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 10),
          PdfTable(transactions: transactions, categoryMap: categoryMap, currency: currency),
          pw.SizedBox(height: 20),
          PdfFooter(),
        ],
      ),
    );

    // 3. Save and Share
    final output = await getTemporaryDirectory();
    final fileName =
        "walt_report_${year}_${month.toString().padLeft(2, '0')}.pdf";
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Walt Monthly Report - $monthName',
      subject: 'Monthly Expense Report: $monthName',
    );
  }
}