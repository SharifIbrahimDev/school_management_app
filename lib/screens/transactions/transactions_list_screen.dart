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

  double _totalIn = 0.0;
  double _totalOut = 0.0;

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

      final transactionsData = await transactionService.getTransactions(
        sectionId: widget.sectionId != null ? int.tryParse(widget.sectionId!) : null,
        sessionId: _selectedSessionId != null ? int.tryParse(_selectedSessionId!) : null,
        termId: _selectedTermId != null ? int.tryParse(_selectedTermId!) : null,
        studentId: _selectedStudentId != null ? int.tryParse(_selectedStudentId!) : null,
      );
      
      _transactions = transactionsData.map((data) => TransactionModel.fromMap(data)).toList();
      
      // Calculate Summary
      _totalIn = 0.0;
      _totalOut = 0.0;
      for (var tx in _transactions) {
        if (tx.transactionType == TransactionType.credit) {
          _totalIn += tx.amount;
        } else {
          _totalOut += tx.amount;
        }
      }

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
    await _loadData();
  }

  Future<void> _onTermChanged(String? termId) async {
    if (termId == _selectedTermId) return;
    setState(() {
      _selectedTermId = termId;
      _isLoading = true;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        title: 'Financial Ledger',
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.mainGradientDecoration(context),
        child: SafeArea(
          child: _isLoading 
            ? const LoadingIndicator(message: 'Auditing ledger...')
            : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummarySection(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _buildHeaderFilterChip(
                        label: _selectedSessionId == null ? 'Session' : _sessions.firstWhere((s) => s.id == _selectedSessionId, orElse: () => _sessions.first).sessionName,
                        icon: Icons.calendar_today_rounded,
                        onTap: () => _showFilterDialog('session'),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderFilterChip(
                        label: _selectedTermId == null ? 'Term' : _terms.firstWhere((t) => t.id == _selectedTermId, orElse: () => _terms.first).termName,
                        icon: Icons.layers_rounded,
                        onTap: () => _showFilterDialog('term'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _errorMessage != null
                      ? _buildErrorPlaceholder()
                      : _transactions.isEmpty
                          ? _buildEmptyPlaceholder()
                          : _buildTransactionList(),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.9, borderRadius: 28, hasGlow: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LEDGER BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[600], letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(
            Formatters.formatCurrency(_totalIn - _totalOut),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: -1),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildCompactStat(Icons.arrow_downward_rounded, 'TOTAL INCOME', _totalIn, AppTheme.neonEmerald),
              const SizedBox(width: 32),
              _buildCompactStat(Icons.arrow_upward_rounded, 'TOTAL EXPENSES', _totalOut, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(IconData icon, String label, double amount, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.formatCurrency(amount),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderFilterChip({required String label, required IconData icon, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.5, borderRadius: 16),
          child: Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.expand_more_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isCredit = tx.transactionType == TransactionType.credit;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.7, borderRadius: 20),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildCategoryIcon(tx.category, isCredit),
            title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${tx.paymentMethod.toUpperCase()} • ${Formatters.formatDate(tx.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? "+" : "-"}${Formatters.formatCurrency(tx.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: isCredit ? AppTheme.neonEmerald : Colors.redAccent,
                  ),
                ),
                if (tx.studentName != null)
                  Text(tx.studentName!, style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: tx)),
            ).then((_) => _loadData()),
          ),
        );
      },
    );
  }

  Widget _buildCategoryIcon(String category, bool isCredit) {
    IconData iconData = isCredit ? Icons.add_chart_rounded : Icons.payments_rounded;
    Color color = isCredit ? AppTheme.neonEmerald : Colors.orangeAccent;
    
    final lowerCat = category.toLowerCase();
    if (lowerCat.contains('fee')) iconData = Icons.school_rounded;
    if (lowerCat.contains('salary') || lowerCat.contains('staff')) iconData = Icons.badge_rounded;
    if (lowerCat.contains('maintenance')) iconData = Icons.build_rounded;
    if (lowerCat.contains('supply') || lowerCat.contains('stationery')) iconData = Icons.inventory_2_rounded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.errorColor)),
          const SizedBox(height: 24),
          TextButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('RETRY AUDIT')),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 80),
            const SizedBox(height: 16),
            const Text('The ledger is currently clear.', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('No transactions recorded for this period.', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final List<dynamic> items = type == 'session' ? _sessions : _terms;
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('SELECT ${type.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final name = type == 'session' ? item.sessionName : item.termName;
                    final isSelected = type == 'session' ? item.id == _selectedSessionId : item.id == _selectedTermId;
                    return ListTile(
                      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.primaryColor : Colors.black)),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor) : null,
                      onTap: () {
                        if (type == 'session') _onSessionChanged(item.id); else _onTermChanged(item.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
