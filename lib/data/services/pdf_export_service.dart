import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/shared/export_pdf/export_ui.dart';

class PdfExportService {
  final TransactionDao _transactionDao = TransactionDao();
  final HiveService _hiveService = HiveService.instance;

  /// Builds and shares a report for one month.
  Future<void> exportMonthToPdf(int year, int month) async {
    final transactions = await _transactionDao.getTransactionsByMonth(
      year,
      month,
    );
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    await _export(
      transactions: transactions,
      fileName: 'walt_report_${year}_${month.toString().padLeft(2, '0')}.pdf',
      title: 'Monthly Report',
      period: monthName,
      emptyMessage: 'No transactions recorded for this month.',
      shareText: 'Walt Monthly Report - $monthName',
      subject: 'Monthly Expense Report: $monthName',
    );
  }

  /// Builds and shares a report covering every transaction.
  ///
  /// Returns the number of transactions included so the Settings screen can
  /// confirm what was exported.
  Future<int> exportAllToPdf() async {
    final transactions = await _transactionDao.getAllTransactions();
    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await _export(
      transactions: transactions,
      fileName: 'walt_report_all_$stamp.pdf',
      title: 'Full History Report',
      period: 'All time',
      emptyMessage: 'No transactions recorded yet.',
      shareText: 'Walt transaction history',
      subject: 'Walt Transaction History',
    );

    return transactions.length;
  }

  Future<void> _export({
    required List<WaltTransaction> transactions,
    required String fileName,
    required String title,
    required String period,
    required String emptyMessage,
    required String shareText,
    required String subject,
  }) async {
    final List<WaltCategory> categories = await _hiveService.getAllCategories();
    final Map<int, WaltCategory> categoryMap = {
      for (final category in categories) category.id: category,
    };
    final String currency = _hiveService.getCurrency();

    // Newest first, so the export reads the same way as the activity list.
    // Sort a copy: the caller's list (a provider snapshot or a DAO result) must
    // not be reordered as a side effect of exporting it.
    final ordered = List<WaltTransaction>.of(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final pdf = pw.Document();

    double totalIncome = 0;
    double totalExpense = 0;
    for (final transaction in ordered) {
      if (transaction.isIncome) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          PdfHeader(title: title, period: period),
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
          PdfTable(
            transactions: ordered,
            categoryMap: categoryMap,
            currency: currency,
            emptyMessage: emptyMessage,
          ),
          pw.SizedBox(height: 20),
          PdfFooter(),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: shareText, subject: subject),
    );
  }
}
