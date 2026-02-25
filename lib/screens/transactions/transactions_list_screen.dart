import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/term_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/session_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../../core/services/transaction_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/loading_indicator.dart';
import 'transaction_detail_screen.dart';
import '../../widgets/custom_app_bar.dart';

class TransactionsListScreen extends StatefulWidget {
  final String schoolId;
  final String? sectionId;
  final String? sessionId;
  final String? termId;
  final String? studentId;

  const TransactionsListScreen({
    super.key,
    required this.schoolId,
    this.sectionId,
    this.sessionId,
    this.termId,
    this.studentId,
  });

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  String? _selectedSessionId;
  String? _selectedTermId;
  String? _selectedStudentId;
  
  List<AcademicSessionModel> _sessions = [];
  List<TermModel> _terms = [];
  List<TransactionModel> _transactions = [];
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSessionId = widget.sessionId;
    _selectedTermId = widget.termId;
    _selectedStudentId = widget.studentId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessionService = Provider.of<SessionServiceApi>(context, listen: false);
      final termService = Provider.of<TermServiceApi>(context, listen: false);
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);

      // Load sessions if sectionId is available
      if (widget.sectionId != null) {
        final sessionsData = await sessionService.getSessions(
          sectionId: int.tryParse(widget.sectionId!),
        );
        _sessions = sessionsData.map((data) => AcademicSessionModel.fromMap(data)).toList();
        
        if (_sessions.isNotEmpty && _selectedSessionId == null) {
          final activeSession = _sessions.firstWhere(
            (s) => s.isActive,
            orElse: () => _sessions.first,
          );
          _selectedSessionId = activeSession.id;
        }
      }

      // Load terms if session is selected
      if (_selectedSessionId != null && widget.sectionId != null) {
        final termsData = await termService.getTerms(
          sectionId: int.tryParse(widget.sectionId!),
          sessionId: int.tryParse(_selectedSessionId!),
        );
        _terms = termsData.map((data) => TermModel.fromMap(data)).toList();
        
        if (_terms.isNotEmpty && _selectedTermId == null) {
          final activeTerm = _terms.firstWhere(
            (t) => t.isActive,
            orElse: () => _terms.first,
          );
          _selectedTermId = activeTerm.id;
        }
      }

      // Load transactions
      final transactionsData = await transactionService.getTransactions(
        sectionId: widget.sectionId != null ? int.tryParse(widget.sectionId!) : null,
        sessionId: _selectedSessionId != null ? int.tryParse(_selectedSessionId!) : null,
        termId: _selectedTermId != null ? int.tryParse(_selectedTermId!) : null,
        studentId: _selectedStudentId != null ? int.tryParse(_selectedStudentId!) : null,
      );
      
      _transactions = transactionsData.map((data) => TransactionModel.fromMap(data)).toList();

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

  Future<void> _onSessionChanged(String? sessionId) async {
    if (sessionId == _selectedSessionId) return;
    
    setState(() {
      _selectedSessionId = sessionId;
      _selectedTermId = null;
      _isLoading = true;
    });

    try {
      final termService = Provider.of<TermServiceApi>(context, listen: false);
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);

      if (sessionId != null && widget.sectionId != null) {
        final termsData = await termService.getTerms(
          sectionId: int.tryParse(widget.sectionId!),
          sessionId: int.tryParse(sessionId),
        );
        _terms = termsData.map((data) => TermModel.fromMap(data)).toList();
        
        if (_terms.isNotEmpty) {
          final activeTerm = _terms.firstWhere(
            (t) => t.isActive,
            orElse: () => _terms.first,
          );
          _selectedTermId = activeTerm.id;
        }
      } else {
        _terms = [];
      }

      final transactionsData = await transactionService.getTransactions(
        sectionId: widget.sectionId != null ? int.tryParse(widget.sectionId!) : null,
        sessionId: _selectedSessionId != null ? int.tryParse(_selectedSessionId!) : null,
        termId: _selectedTermId != null ? int.tryParse(_selectedTermId!) : null,
        studentId: _selectedStudentId != null ? int.tryParse(_selectedStudentId!) : null,
      );
      
      _transactions = transactionsData.map((data) => TransactionModel.fromMap(data)).toList();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error updating filter: $e';
        });
      }
    }
  }

  Future<void> _onTermChanged(String? termId) async {
    if (termId == _selectedTermId) return;
    
    setState(() {
      _selectedTermId = termId;
      _isLoading = true;
    });

    try {
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);

      final transactionsData = await transactionService.getTransactions(
        sectionId: widget.sectionId != null ? int.tryParse(widget.sectionId!) : null,
        sessionId: _selectedSessionId != null ? int.tryParse(_selectedSessionId!) : null,
        termId: _selectedTermId != null ? int.tryParse(_selectedTermId!) : null,
        studentId: _selectedStudentId != null ? int.tryParse(_selectedStudentId!) : null,
      );
      
      _transactions = transactionsData.map((data) => TransactionModel.fromMap(data)).toList();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error updating filter: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Transactions',
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/auth_bg_pattern.png'),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filters
                // Filter Header
                Row(
                  children: [
                    if (_sessions.isNotEmpty)
                      Expanded(
                        child: _buildFilterChip(
                          context,
                          label: _selectedSessionId == null 
                            ? 'Session' 
                            : _sessions.firstWhere((s) => s.id == _selectedSessionId, orElse: () => _sessions.first).sessionName,
                          onTap: () => _showFilterDialog('session'),
                        ),
                      ),
                    const SizedBox(width: 12),
                    if (_terms.isNotEmpty)
                      Expanded(
                        child: _buildFilterChip(
                          context,
                          label: _selectedTermId == null 
                            ? 'Term' 
                            : _terms.firstWhere((t) => t.id == _selectedTermId, orElse: () => _terms.first).termName,
                          onTap: () => _showFilterDialog('term'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? const LoadingIndicator()
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.errorColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _transactions.isEmpty
                          ? Center(
                              child: Text(
                                'No transactions found',
                                style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _transactions[index];
                                final isCredit = transaction.transactionType == TransactionType.credit;
                                final iconColor = isCredit ? AppTheme.neonEmerald : AppTheme.errorColor;
                                final icon = isCredit ? Icons.add_rounded : Icons.remove_rounded;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: AppTheme.glassDecoration(
                                    context: context,
                                    opacity: 0.7,
                                    borderRadius: 24,
                                    hasGlow: isCredit,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: iconColor.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(icon, color: iconColor, size: 24),
                                    ),
                                    title: Text(
                                      transaction.category,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${transaction.paymentMethod.toUpperCase()} • ${Formatters.formatDate(transaction.createdAt)}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isCredit ? "+" : "-"}${Formatters.formatCurrency(transaction.amount)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: iconColor,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        if (transaction.studentId != null)
                                          Text(
                                            'Student ID: ${transaction.studentId}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TransactionDetailScreen(transaction: transaction),
                                      ),
                                    ).then((_) => _loadData()),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    ),
  ),
    );
  }
  Widget _buildFilterChip(BuildContext context, {required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.3,
          borderRadius: 20,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        final List<dynamic> items = type == 'session' ? _sessions : _terms;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select ${type.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 20),
              ...items.map((item) {
                final String name = type == 'session' ? item.sessionName : item.termName;
                final String id = item.id;
                return ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    if (type == 'session') {
                      _onSessionChanged(id);
                    } else {
                      _onTermChanged(id);
                    }
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
