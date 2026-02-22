import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/student_service_api.dart';
import '../core/services/transaction_service_api.dart';
import '../core/utils/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/models/student_model.dart';
import '../core/models/transaction_model.dart';
import 'loading_indicator.dart';
import 'empty_state_widget.dart';
import '../screens/student/student_detail_screen.dart';
import '../screens/transactions/transaction_detail_screen.dart';

class GlobalSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search for students or transactions'));
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final studentService = Provider.of<StudentServiceApi>(context, listen: false);
    final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);

    return FutureBuilder(
      future: Future.wait([
        studentService.searchStudents(query),
        transactionService.getTransactions(search: query),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final studentsData = (snapshot.data?[0] ?? []) as List<Map<String, dynamic>>;
        final transactionsData = (snapshot.data?[1] ?? []) as List<Map<String, dynamic>>;

        final students = studentsData.map((s) => StudentModel.fromMap(s)).toList();
        final transactions = transactionsData.map((t) => TransactionModel.fromMap(t)).toList();

        if (students.isEmpty && transactions.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.search_off,
            title: 'No results found',
            message: 'Try a different search term',
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            if (students.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Students (${students.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...students.map((student) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(student.fullName[0], style: const TextStyle(color: AppTheme.primaryColor)),
                ),
                title: Text(student.fullName),
                subtitle: Text('ID: ${student.admissionNumber ?? student.id}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDetailScreen(student: student),
                    ),
                  );
                },
              )),
            ],
            if (transactions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Transactions (${transactions.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...transactions.map((transaction) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction.transactionType == TransactionType.credit
                      ? Colors.green.withValues(alpha: 0.1) 
                      : Colors.red.withValues(alpha: 0.1),
                  child: Icon(
                    transaction.transactionType == TransactionType.credit ? Icons.arrow_downward : Icons.arrow_upward, 
                    color: transaction.transactionType == TransactionType.credit ? Colors.green : Colors.red,
                    size: 18,
                  ),
                ),
                title: Text(transaction.category ?? transaction.type),
                subtitle: Text(Formatters.formatDate(transaction.transactionDate)),
                trailing: Text(
                  Formatters.formatCurrency(transaction.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailScreen(transaction: transaction),
                    ),
                  );
                },
              )),
            ],
          ],
        );
      },
    );
  }
}
