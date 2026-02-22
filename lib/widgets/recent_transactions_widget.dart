import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/transaction_model.dart';
import '../core/services/transaction_service_api.dart';
import '../screens/transactions/transaction_detail_screen.dart';
import '../screens/transactions/transactions_list_screen.dart';
import '../core/utils/formatters.dart';

class RecentTransactionsWidget extends StatelessWidget {
  final String sectionId;
  final String? sessionId;
  final String? termId;
  final String schoolId;
  final String? studentId;
  final String? classId;

  const RecentTransactionsWidget({
    super.key,
    required this.sectionId,
    this.sessionId,
    this.termId,
    required this.schoolId,
    this.studentId,
    this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionsListScreen(
                    sectionId: sectionId,
                    sessionId: sessionId,
                    termId: termId,
                    schoolId: schoolId,
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: transactionService.getTransactions(
            sectionId: int.tryParse(sectionId),
            sessionId: sessionId != null ? int.tryParse(sessionId!) : null,
            termId: termId != null ? int.tryParse(termId!) : null,
            limit: 5,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading transactions',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            try {
              final transactionsData = snapshot.data!;
              final transactions = transactionsData
                  .map((data) => TransactionModel.fromMap(data))
                  .where((t) => t.id != 'error')
                  .toList();

              if (transactions.isEmpty) {
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          size: 48,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
              child: Column(
                children: transactions.map((transaction) {
                  final isCredit = transaction.transactionType == TransactionType.credit;
                  final iconColor = isCredit ? Colors.green : Colors.red;
                  final icon = isCredit ? Icons.arrow_circle_down : Icons.arrow_circle_up;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    title: Text(
                      transaction.category,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${transaction.paymentTypeDisplayName} • ${transaction.createdAt.toString().split(' ')[0]}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: Text(
                      Formatters.formatCurrency(transaction.amount),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCredit ? Colors.green : Colors.red,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionDetailScreen(transaction: transaction),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          } catch (e) {
            return Center(child: Text('Error displaying transactions: $e'));
          }
          },
        ),
      ],
    );
  }
}
