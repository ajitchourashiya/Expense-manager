import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/expense_model.dart';

class ReportExportService {
  static final _money = NumberFormat('#,##0.00');
  static final _date = DateFormat('dd MMM yyyy');
  static Future<File> pdf(List<Expense> expenses, String period) async {
    final document = pw.Document();
    final total = expenses.fold<double>(0, (s, e) => s + e.amount);
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        pw.Text('Expense Report', style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('$period  |  Generated ${_date.format(DateTime.now())}'),
        pw.SizedBox(height: 16),
        pw.Text('Transactions: ${expenses.length}    Total: INR ${_money.format(total)}',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Description', 'Payment', 'Amount (INR)'],
          data: expenses.map((e) => [
            _date.format(e.expenseDate), e.description, e.paymentMethod, _money.format(e.amount),
          ]).toList(),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ));
    final file = File('${(await getTemporaryDirectory()).path}/expense_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await document.save());
    return file;
  }

  static Future<File> excel(List<Expense> expenses, String period) async {
    final book = xl.Excel.createExcel();
    final sheet = book['Expenses'];
    book.delete('Sheet1');
    sheet.appendRow([xl.TextCellValue('Expense Report - $period')]);
    sheet.appendRow([xl.TextCellValue('Date'), xl.TextCellValue('Description'), xl.TextCellValue('Payment'), xl.TextCellValue('Amount (INR)')]);
    for (final e in expenses) {
      sheet.appendRow([xl.TextCellValue(_date.format(e.expenseDate)), xl.TextCellValue(e.description), xl.TextCellValue(e.paymentMethod), xl.DoubleCellValue(e.amount)]);
    }
    sheet.appendRow([xl.TextCellValue('TOTAL'), xl.TextCellValue(''), xl.TextCellValue(''), xl.DoubleCellValue(expenses.fold<double>(0, (s,e)=>s+e.amount))]);
    for (var i = 0; i < 4; i++) { sheet.setColumnWidth(i, [18.0, 38.0, 20.0, 20.0][i]); }
    final bytes = book.encode();
    if (bytes == null) throw StateError('Unable to create Excel report');
    final file = File('${(await getTemporaryDirectory()).path}/expense_report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> share(File file) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Expense report'));
  }
}
