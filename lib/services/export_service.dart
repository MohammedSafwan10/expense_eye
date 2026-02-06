import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:expense_eye/models/expense.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class ExportService {
  // Shares the details of a single expense as plain text.
  static Future<void> shareExpense(Expense expense) async {
    final details = _formatExpenseDetails(expense);
    await SharePlus.instance.share(ShareParams(text: details));
  }

  // Exports the details of a single expense as a text file.
  // Handles different behavior for web and mobile platforms.
  static Future<void> exportAsText(Expense expense) async {
    final details = _formatExpenseDetails(expense);

    if (kIsWeb) {
      // For web, create a downloadable text file.
      final bytes = utf8.encode(details);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'expense_${expense.id}.txt';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile, save the text to a file and then share it.
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/expense_${expense.id}.txt');
      await file.writeAsString(details);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Expense Details'),
      );
    }
  }

  // Exports the details of a single expense as a PDF file.
  // Handles different behavior for web and mobile platforms.
  static Future<void> exportAsPDF(Expense expense) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Expense Details',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  )),
              pw.SizedBox(height: 20),
              pw.Text('Title: ${expense.title}'),
              pw.Text('Amount: ₹${expense.amount.toStringAsFixed(2)}'),
              pw.Text('Category: ${expense.category.name.toUpperCase()}'),
              pw.Text(
                  'Date: ${DateFormat('MMMM dd, yyyy').format(expense.date)}'),
              pw.Text(
                  'Payment Method: ${expense.paymentMethod.name.toUpperCase()}'),
              if (expense.note != null && expense.note!.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text('Note: ${expense.note}'),
              ],
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      // For web, create a downloadable PDF file.
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'expense_${expense.id}.pdf';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile, save the PDF to a file and then share it.
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/expense_${expense.id}.pdf');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Expense Details PDF'),
      );
    }
  }

  // Formats the details of an expense into a readable string.
  static String _formatExpenseDetails(Expense expense) {
    return '''
Expense Details:
Title: ${expense.title}
Amount: ₹${expense.amount.toStringAsFixed(2)}
Category: ${expense.category.name.toUpperCase()}
Date: ${DateFormat('MMMM dd, yyyy').format(expense.date)}
Payment Method: ${expense.paymentMethod.name.toUpperCase()}
${expense.note != null ? 'Note: ${expense.note}' : ''}''';
  }
}
