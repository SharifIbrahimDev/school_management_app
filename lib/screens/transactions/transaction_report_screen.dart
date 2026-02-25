import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/section_model.dart';
import '../../core/models/term_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/session_service_api.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../../core/services/transaction_service_api.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import 'transaction_detail_screen.dart';
import '../../core/services/receipt_service.dart';
import '../../core/services/school_service_api.dart';
import '../../core/services/student_service_api.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/responsive_widgets.dart';
import '../../widgets/app_snackbar.dart';

class TransactionReportScreen extends StatefulWidget {
  final String? sectionId;
  final String? sessionId;
  final String? termId;

  const TransactionReportScreen({
    super.key,
    this.sectionId,
    this.sessionId,
    this.termId,
  });

  @override
  State<TransactionReportScreen> createState() => _TransactionReportScreenState();
}

class _TransactionReportScreenState extends State<TransactionReportScreen> {
  List<SectionModel> _sections = [];
  List<AcademicSessionModel> _sessions = [];
  List<TermModel> _terms = [];
  
  String? _selectedSectionId;
  String? _selectedSessionId;
  String? _selectedTermId;
  String? _selectedTransactionType;
  String? _selectedPaymentMethod;
  DateTime? _startDate;
  DateTime? _endDate;
  
  Map<String, double> _reportSummary = {
    'totalCredits': 0.0,
    'totalDebits': 0.0,
    'netBalance': 0.0,
  };
  
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  bool _isPrinting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSectionId = widget.sectionId;
    _selectedSessionId = widget.sessionId;
    _selectedTermId = widget.termId;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthServiceApi>(context, listen: false);
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);

      final userMap = authService.currentUser;
      final user = userMap != null ? UserModel.fromMap(userMap) : null;
      
      if (user == null) throw Exception('User not authenticated');

      // Load sections
      final sectionsData = await sectionService.getSections(isActive: true);
      final allSections = sectionsData.map((data) => SectionModel.fromMap(data)).toList();

      // Filter sections based on user role
      if (user.role == UserRole.proprietor) {
        _sections = allSections;
      } else {
        _sections = allSections.where((s) => user.assignedSections.contains(s.id)).toList();
      }

      if (_sections.isNotEmpty && _selectedSectionId == null) {
        _selectedSectionId = _sections.first.id;
      }

      await _loadSessionsAndTerms();
      await _loadTransactions();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading report: $e';
        });
      }
    }
  }

  Future<void> _loadSessionsAndTerms() async {
    if (_selectedSectionId == null) return;

    try {
      final sessionService = Provider.of<SessionServiceApi>(context, listen: false);
      final termService = Provider.of<TermServiceApi>(context, listen: false);

      // Load sessions
      final sessionsData = await sessionService.getSessions(sectionId: int.tryParse(_selectedSectionId!));
      _sessions = sessionsData.map((data) => AcademicSessionModel.fromMap(data)).toList();

      if (_sessions.isNotEmpty && _selectedSessionId == null) {
        final activeSession = _sessions.firstWhere((s) => s.isActive, orElse: () => _sessions.first);
        _selectedSessionId = activeSession.id;
      }

      // Load terms
      if (_selectedSessionId != null) {
        final termsData = await termService.getTerms(
          sectionId: int.tryParse(_selectedSectionId!),
          sessionId: int.tryParse(_selectedSessionId!),
        );
        _terms = termsData.map((data) => TermModel.fromMap(data)).toList();

        if (_terms.isNotEmpty && _selectedTermId == null) {
          final activeTerm = _terms.firstWhere((t) => t.isActive, orElse: () => _terms.first);
          _selectedTermId = activeTerm.id;
        }
      } else {
        _terms = [];
      }
    } catch (e) {
      debugPrint('Error loading sessions/terms: $e');
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);

      final transactionsData = await transactionService.getTransactions(
        sectionId: _selectedSectionId != null ? int.tryParse(_selectedSectionId!) : null,
        sessionId: _selectedSessionId != null ? int.tryParse(_selectedSessionId!) : null,
        termId: _selectedTermId != null ? int.tryParse(_selectedTermId!) : null,
        transactionType: _selectedTransactionType,
        paymentMethod: _selectedPaymentMethod,
        startDate: _startDate?.toIso8601String(),
        endDate: _endDate?.toIso8601String(),
      );

      _transactions = transactionsData.map((data) => TransactionModel.fromMap(data)).toList();
      _calculateSummary();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading transactions: $e';
        });
      }
    }
  }

  void _calculateSummary() {
    double totalCredits = 0.0;
    double totalDebits = 0.0;

    for (var t in _transactions) {
      if (t.transactionType == TransactionType.credit) {
        totalCredits += t.amount;
      } else {
        totalDebits += t.amount;
      }
    }

    _reportSummary = {
      'totalCredits': totalCredits,
      'totalDebits': totalDebits,
      'netBalance': totalCredits - totalDebits,
    };
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('Transaction Report')),
          pw.Paragraph(text: 'Generated on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
          pw.Paragraph(text: 'Total Credits: ${Formatters.formatCurrency((_reportSummary['totalCredits'] ?? 0.0).toDouble())}'),
          pw.Paragraph(text: 'Total Debits: ${Formatters.formatCurrency((_reportSummary['totalDebits'] ?? 0.0).toDouble())}'),
          pw.Paragraph(text: 'Net Balance: ${Formatters.formatCurrency((_reportSummary['netBalance'] ?? 0.0).toDouble())}'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Category', 'Amount', 'Type', 'Date'],
            data: _transactions.map((t) => [
              t.category,
              Formatters.formatCurrency(t.amount),
              t.transactionTypeDisplayName,
              DateFormat('MMM dd, yyyy').format(t.createdAt.toLocal()),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  Future<void> _printReceipt(TransactionModel t) async {
    setState(() => _isPrinting = true);
    try {
      final schoolService = Provider.of<SchoolServiceApi>(context, listen: false);
      final schoolData = await schoolService.getSchool();
      final schoolName = schoolData['name'] ?? 'School Connect';

      String? studentName;
      if (t.studentId != null) {
        if (!mounted) return;
        final studentService = Provider.of<StudentServiceApi>(context, listen: false);
        final studentData = await studentService.getStudent(int.tryParse(t.studentId!) ?? 0);
        if (studentData != null) {
          studentName = studentData['name'] ?? '${studentData['first_name']} ${studentData['last_name']}';
        }
      }

      if (!mounted) return;
      await ReceiptService.generateAndPrintReceipt(
        transaction: t,
        schoolName: schoolName,
        studentName: studentName,
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.friendlyError(context, error: e);
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Transaction Report',
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _transactions.isEmpty ? null : _exportToPDF,
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/auth_bg_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.accentColor.withValues(alpha: 0.2),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[800], size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: TextStyle(color: Colors.red[800])),
                        TextButton(
                          onPressed: _loadInitialData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : AppTheme.constrainedContent(
                    context: context,
                    child: SingleChildScrollView(
                      padding: AppTheme.responsivePadding(context),
                      child: ResponsiveRowColumn(
                        rowOnMobile: false,
                        rowOnTablet: true,
                        rowOnDesktop: true,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Side / Top: Filters and Summary
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Filters
                                Container(
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: AppTheme.glassDecoration(
                                    context: context,
                                    opacity: 0.7,
                                    borderRadius: 16,
                                    borderColor: theme.dividerColor.withValues(alpha: 0.1),
                                  ),
                                  child: ExpansionTile(
                                    initiallyExpanded: !context.isMobile,
                                    title: const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            if (_sections.isNotEmpty)
                                              DropdownButtonFormField<String>(
                                                initialValue: _selectedSectionId,
                                                decoration: const InputDecoration(labelText: 'Section'),
                                                items: _sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.sectionName))).toList(),
                                                onChanged: (value) async {
                                                  setState(() {
                                                    _selectedSectionId = value;
                                                    _selectedSessionId = null;
                                                    _selectedTermId = null;
                                                  });
                                                  await _loadSessionsAndTerms();
                                                  await _loadTransactions();
                                                },
                                              ),
                                            if (_sessions.isNotEmpty) ...[
                                              const SizedBox(height: 16),
                                              DropdownButtonFormField<String>(
                                                initialValue: _selectedSessionId,
                                                decoration: const InputDecoration(labelText: 'Session'),
                                                items: _sessions.map((s) => DropdownMenuItem(value: s.id, child: Text(s.sessionName))).toList(),
                                                onChanged: (value) async {
                                                  setState(() {
                                                    _selectedSessionId = value;
                                                    _selectedTermId = null;
                                                  });
                                                  await _loadSessionsAndTerms();
                                                  await _loadTransactions();
                                                },
                                              ),
                                            ],
                                            if (_terms.isNotEmpty) ...[
                                              const SizedBox(height: 16),
                                              DropdownButtonFormField<String>(
                                                initialValue: _selectedTermId,
                                                decoration: const InputDecoration(labelText: 'Term'),
                                                items: _terms.map((t) => DropdownMenuItem(value: t.id, child: Text(t.termName))).toList(),
                                                onChanged: (value) {
                                                  setState(() => _selectedTermId = value);
                                                  _loadTransactions();
                                                },
                                              ),
                                            ],
                                            const SizedBox(height: 16),
                                            DropdownButtonFormField<String>(
                                              initialValue: _selectedTransactionType,
                                              decoration: const InputDecoration(labelText: 'Type'),
                                              items: const [
                                                DropdownMenuItem(value: null, child: Text('All')),
                                                DropdownMenuItem(value: 'credit', child: Text('Credit')),
                                                DropdownMenuItem(value: 'debit', child: Text('Debit')),
                                              ],
                                              onChanged: (value) {
                                                setState(() => _selectedTransactionType = value);
                                                _loadTransactions();
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            _buildDateRangePicker(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
          
                                // Summary
                                Text('Summary', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 24),
                                  padding: const EdgeInsets.all(20),
                                  decoration: AppTheme.glassDecoration(
                                    context: context,
                                    opacity: 0.8,
                                    borderRadius: 20,
                                    hasGlow: true,
                                    borderColor: theme.dividerColor.withValues(alpha: 0.1),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildSummaryItem('Total Credits', _reportSummary['totalCredits']!, Colors.green),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(height: 1),
                                      ),
                                      _buildSummaryItem('Total Debits', _reportSummary['totalDebits']!, Colors.red),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(height: 1),
                                      ),
                                      _buildSummaryItem('Net Balance', _reportSummary['netBalance']!, 
                                        _reportSummary['netBalance']! >= 0 ? Colors.green : Colors.red, isBold: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (!context.isMobile) const SizedBox(width: 32),
          
                          // Right Side / Bottom: Transactions List
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Transactions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_transactions.length}',
                                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_transactions.isEmpty)
                                  EmptyStateWidget(
                                    icon: Icons.payments_outlined,
                                    title: 'No Transactions',
                                    message: 'No transactions found for the selected filters.',
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _transactions.length,
                                    itemBuilder: (context, index) {
                                      final t = _transactions[index];
                                      final isCredit = t.transactionType == TransactionType.credit;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: AppTheme.glassDecoration(
                                          context: context,
                                          opacity: 0.6,
                                          borderRadius: 16,
                                          borderColor: theme.dividerColor.withValues(alpha: 0.1),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          leading: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                              color: isCredit ? Colors.green : Colors.red,
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(t.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text(Formatters.formatDate(t.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                Formatters.formatCurrency(t.amount),
                                                style: TextStyle(
                                                  color: isCredit ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (isCredit) ...[
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.print, size: 20),
                                                  onPressed: _isPrinting ? null : () => _printReceipt(t),
                                                  color: AppTheme.primaryColor,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  tooltip: 'Print Receipt',
                                                ),
                                              ],
                                              const SizedBox(width: 4),
                                              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                                            ],
                                          ),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: t)),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, double value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          Formatters.formatCurrency(value),
          style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _startDate = picked.start;
            _endDate = picked.end;
          });
          _loadTransactions();
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date Range',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _startDate == null
              ? 'Select Date Range'
              : '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}',
        ),
      ),
    );
  }
}
