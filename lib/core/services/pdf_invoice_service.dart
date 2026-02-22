import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/fee_model.dart';
import '../models/user_model.dart';

class PdfInvoiceService {
  static Future<void> generateAndPrintInvoice({
    required FeeModel fee,
    required UserModel? student,
    required String schoolName,
  }) async {
    final doc = pw.Document();

    final font = await PdfGoogleFonts.nunitoExtraLight();
    
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(schoolName, font),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              _buildInvoiceDetails(fee, student, font),
              pw.SizedBox(height: 20),
              _buildFeeTable(fee, font),
              pw.SizedBox(height: 20),
              pw.Divider(),
              _buildFooter(font),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  static pw.Widget _buildHeader(String schoolName, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          schoolName,
          style: pw.TextStyle(
            font: font,
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'INVOICE / RECEIPT',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceDetails(FeeModel fee, UserModel? student, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Bill To:', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
            pw.Text(student?.fullName ?? 'Student ID: ${fee.studentId}', style: pw.TextStyle(font: font)),
            pw.Text('Class ID: ${fee.classId}', style: pw.TextStyle(font: font)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Fee Reference:', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
            pw.Text('#${fee.id}', style: pw.TextStyle(font: font)),
            pw.Text('Due Date: ${DateFormat('yyyy-MM-dd').format(fee.dueDate)}', style: pw.TextStyle(font: font)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFeeTable(FeeModel fee, pw.Font font) {
    return pw.TableHelper.fromTextArray(
      border: null,
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
      headers: ['Description', 'Amount'],
      data: [
        [fee.feeType, _formatCurrency(fee.amount)],
        ['Amount Paid', _formatCurrency(fee.amountPaid)],
        ['Balance Due', _formatCurrency(fee.balance)],
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Center(
      child: pw.Text(
        'Thank you for your business.',
        style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey),
      ),
    );
  }

  static String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_NG', symbol: '₦'); // Nigeria Currency
    return format.format(amount);
  }
}
