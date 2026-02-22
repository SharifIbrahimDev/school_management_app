import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/payment_model.dart';

class ReceiptService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦ ',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  /// Generate a professional receipt PDF as bytes
  Future<Uint8List> generateReceipt(PaymentModel payment) async {
    final pdf = pw.Document();

    // Load custom font for better aesthetics
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SCHOOL CONNECT',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 18,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'OFFICIAL RECEIPT',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      height: 40,
                      width: 40,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue100,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'S',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 20,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 20),

                // Transaction Details Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(font, fontBold, 'RECEIPT NO', payment.reference.toUpperCase()),
                    _buildInfoColumn(font, fontBold, 'DATE', _dateFormat.format(payment.createdAt)),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Payer/Category Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildLabelValue(font, fontBold, 'FEE TYPE:', payment.feeType ?? 'General Fee'),
                      pw.SizedBox(height: 8),
                      _buildLabelValue(font, fontBold, 'STATUS:', payment.status.toUpperCase()),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Amount Section
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue200),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL PAID',
                        style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue900),
                      ),
                      pw.Text(
                        _currencyFormat.format(payment.amount),
                        style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blue900),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'This is a computer generated receipt. No signature required.',
                        style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
                      ),
                      pw.Text(
                        'Thank you for your payment!',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate and print receipt for a transaction
  static Future<void> generateAndPrintReceipt({
    required TransactionModel transaction,
    required String schoolName,
    String? studentName,
    String? className,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          schoolName.toUpperCase(),
                          style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blue900),
                        ),
                        pw.Text(
                          'OFFICIAL RECEIPT',
                          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Container(
                      height: 40,
                      width: 40,
                      decoration: const pw.BoxDecoration(color: PdfColors.blue100, shape: pw.BoxShape.circle),
                      child: pw.Center(
                        child: pw.Text('S', style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.blue800)),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(font, fontBold, 'RECEIPT NO', transaction.id.substring(0, 8).toUpperCase()),
                    _buildInfoColumn(font, fontBold, 'DATE', _dateFormat.format(transaction.transactionDate)),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (studentName != null) ...[
                        _buildLabelValue(font, fontBold, 'PAYER / STUDENT:', studentName.toUpperCase()),
                        pw.SizedBox(height: 8),
                      ],
                      if (className != null) ...[
                        _buildLabelValue(font, fontBold, 'CLASS:', className),
                        pw.SizedBox(height: 8),
                      ],
                      _buildLabelValue(font, fontBold, 'CATEGORY:', transaction.category),
                      pw.SizedBox(height: 8),
                      _buildLabelValue(font, fontBold, 'PAYMENT METHOD:', transaction.paymentTypeDisplayName),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
                if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                  pw.Text('REMARKS:', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey600)),
                  pw.Text(transaction.description!, style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.SizedBox(height: 24),
                ],
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue200), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL PAID', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue900)),
                      pw.Text(_currencyFormat.format(transaction.amount), style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blue900)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('This is a computer generated receipt. No signature required.', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500)),
                      pw.Text('Thank you for your payment!', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${transaction.id.substring(0, 8)}.pdf',
    );
  }

  static pw.Widget _buildInfoColumn(pw.Font font, pw.Font fontBold, String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 11)),
      ],
    );
  }

  static pw.Widget _buildLabelValue(pw.Font font, pw.Font fontBold, String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
        ),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 11)),
        ),
      ],
    );
  }
}
