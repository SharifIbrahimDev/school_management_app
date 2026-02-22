import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

/// Service for exporting data to PDF format
/// Currently supports transaction reports with plans to expand
class PdfExportService {
  final currencyFormat = NumberFormat.currency(symbol: 'N', decimalDigits: 2);
  final dateFormat = DateFormat('dd/MM/yyyy');

  /// Generate a PDF report for transactions
  Future<void> exportTransactionReport({
    required String schoolName,
    required List<TransactionModel> transactions,
    String? sectionName,
    String? sessionName,
    String? termName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    // Use a font that supports the Naira symbol
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final ttfStyle = pw.TextStyle(font: font);
    final boldTtfStyle = pw.TextStyle(font: boldFont, fontWeight: pw.FontWeight.bold);

    final pdfCurrencyFormat = NumberFormat.currency(symbol: 'N', decimalDigits: 2); // Fallback to N if font fails
    
    // We'll use the currency format with the actual symbol but ensure font is set
    final nairaSymbol = '₦';

    // Calculate totals
    double totalIncome = 0;
    double totalExpenses = 0;
    
    for (var transaction in transactions) {
      if (transaction.transactionType == TransactionType.credit) {
        totalIncome += transaction.amount;
      } else {
        totalExpenses += transaction.amount;
      }
    }
    
    final netBalance = totalIncome - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        build: (context) => [
          // Header
          _buildHeader(schoolName),
          pw.SizedBox(height: 20),
          
          // Title
          pw.Text(
            'Transaction Report',
            style: pw.TextStyle(
              fontSize: 24,
              font: boldFont,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          
          // Filters applied
          _buildFilters(sectionName, sessionName, termName, startDate, endDate),
          pw.SizedBox(height: 20),
          
          // Summary section
          _buildSummary(totalIncome, totalExpenses, netBalance),
          pw.SizedBox(height: 30),
          
          // Transactions table
          _buildTransactionsTable(transactions),
          
          pw.SizedBox(height: 30),
          
          // Footer
          _buildFooter(),
        ],
      ),
    );

    // Show printing dialog (also allows save)
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Transaction_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Generate a PDF report card for a student
  Future<void> exportReportCard({
    required String schoolName,
    required String studentName,
    required String className,
    required String sectionName,
    required List<dynamic> results,
    String? termName,
    String? sessionName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(schoolName),
          pw.SizedBox(height: 20),
          
          pw.Center(
            child: pw.Text(
              'STUDENT PROGRESS REPORT',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Student Details
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Student Name: $studentName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Class: $className'),
                  pw.Text('Section: $sectionName'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Session: ${sessionName ?? 'N/A'}'),
                  pw.Text('Term: ${termName ?? 'N/A'}'),
                  pw.Text('Date: ${dateFormat.format(DateTime.now())}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          
          // Results Table
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Subject', isHeader: true),
                  _buildTableCell('Score', isHeader: true),
                  _buildTableCell('Grade', isHeader: true),
                  _buildTableCell('Remark', isHeader: true),
                ],
              ),
              ...results.map((res) {
                final score = res['score']?.toString() ?? '-';
                final grade = res['grade']?.toString() ?? '-';
                final remark = res['remark']?.toString() ?? '-';
                final subject = res['exam']?['subject']?['subject_name'] ?? 'Unknown Subject';

                return pw.TableRow(
                  children: [
                    _buildTableCell(subject),
                    _buildTableCell(score),
                    _buildTableCell(grade, isBold: true),
                    _buildTableCell(remark),
                  ],
                );
              }),
            ],
          ),
          
          pw.SizedBox(height: 40),
          
          // Signature Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('Class Teacher', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('Principal', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Report_Card_$studentName.pdf',
    );
  }

  /// Build PDF header with school name
  pw.Widget _buildHeader(String schoolName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          schoolName,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'Financial Management System',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  /// Build filters section
  pw.Widget _buildFilters(
    String? sectionName,
    String? sessionName,
    String? termName,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final filters = <String>[];
    
    if (sectionName != null) filters.add('Section: $sectionName');
    if (sessionName != null) filters.add('Session: $sessionName');
    if (termName != null) filters.add('Term: $termName');
    if (startDate != null) filters.add('From: ${dateFormat.format(startDate)}');
    if (endDate != null) filters.add('To: ${dateFormat.format(endDate)}');
    
    if (filters.isEmpty) {
      return pw.SizedBox.shrink();
    }
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Applied Filters:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            filters.join(' • '),
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Build summary boxes
  pw.Widget _buildSummary(double totalIncome, double totalExpenses, double netBalance) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _buildSummaryCard('Total Income', totalIncome, PdfColors.green),
        _buildSummaryCard('Total Expenses', totalExpenses, PdfColors.red),
        _buildSummaryCard('Net Balance', netBalance, PdfColors.blue),
      ],
    );
  }

  /// Build individual summary card
  pw.Widget _buildSummaryCard(String label, double amount, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            currencyFormat.format(amount),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build transactions table
  pw.Widget _buildTransactionsTable(List<TransactionModel> transactions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FixedColumnWidth(80),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FixedColumnWidth(80),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Payment', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
          ],
        ),
        
        // Data rows
        ...transactions.map((transaction) {
          final isIncome = transaction.transactionType == TransactionType.credit;
          return pw.TableRow(
            children: [
              _buildTableCell(dateFormat.format(transaction.transactionDate)),
              _buildTableCell(transaction.category),
              _buildTableCell(transaction.description ?? '-'),
              _buildTableCell(transaction.paymentType.displayName.toUpperCase()),
              _buildTableCell(
                currencyFormat.format(transaction.amount),
                color: isIncome ? PdfColors.green : PdfColors.red,
                isBold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Build table cell
  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? color,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  /// Build footer
  pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'School Financial App',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
