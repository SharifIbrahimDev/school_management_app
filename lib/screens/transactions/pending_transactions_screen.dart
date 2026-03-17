import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/transaction_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import 'transaction_detail_screen.dart';

class PendingTransactionsScreen extends StatefulWidget {
  final String schoolId;

  const PendingTransactionsScreen({super.key, required this.schoolId});

  @override
  State<PendingTransactionsScreen> createState() => _PendingTransactionsScreenState();
}

class _PendingTransactionsScreenState extends State<PendingTransactionsScreen> {
  List<TransactionModel> _pendingTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingTransactions();
  }

  Future<void> _loadPendingTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
      final transactionsData = await transactionService.getTransactions(
        status: TransactionStatus.pending.name,
      );
      
      if (mounted) {
        setState(() {
          _pendingTransactions = transactionsData.map((data) => TransactionModel.fromMap(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading pending transactions: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Pending Verifications',
      ),
      body: Container(
        decoration: AppTheme.mainGradientDecoration(context),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadPendingTransactions,
            child: _isLoading 
                ? const LoadingIndicator(message: 'Loading pending transactions...')
                : _errorMessage != null
                    ? _buildErrorState()
                    : _pendingTransactions.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'All Caught Up!',
                            message: 'No pending transactions require verification at this time.',
                          )
                        : _buildTransactionList(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.errorColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPendingTransactions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _pendingTransactions.length,
      itemBuilder: (context, index) {
        final tx = _pendingTransactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.glassDecoration(
            context: context,
            opacity: 0.8,
            borderRadius: 20,
            hasGlow: true,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildStatusIcon(tx),
            title: Text(
              tx.category,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${tx.studentName ?? "N/A"} • ${Formatters.formatDate(tx.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  'Method: ${tx.paymentTypeDisplayName}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                ),
              ],
            ),
            trailing: Text(
              Formatters.formatCurrency(tx.amount),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppTheme.primaryColor,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailScreen(transaction: tx),
                ),
              ).then((_) => _loadPendingTransactions());
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(TransactionModel tx) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.hourglass_empty_rounded, color: Colors.amber, size: 24),
    );
  }
}
