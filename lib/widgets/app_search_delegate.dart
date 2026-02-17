import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/student_model.dart';
import '../core/models/section_model.dart';
import '../core/models/transaction_model.dart';
import '../core/services/student_service_api.dart';
import '../core/services/section_service_api.dart';
import '../core/services/transaction_service_api.dart';
import '../screens/student/student_detail_screen.dart';
import '../screens/sections/section_detail_screen.dart';
import '../screens/transactions/transaction_detail_screen.dart';

/// Global search delegate for searching across the app
class AppSearchDelegate extends SearchDelegate<String> {
  final BuildContext context;
  
  AppSearchDelegate(this.context);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a search term'),
      );
    }

    return _SearchResults(query: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSearchHistory();
    }

    return _SearchResults(query: query);
  }

  Widget _buildSearchHistory() {
    // TODO: Implement search history from SharedPreferences
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Search Students, Transactions, Sections',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatefulWidget {
  final String query;

  const _SearchResults({required this.query});

  @override
  State<_SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<_SearchResults> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<StudentModel> _students = [];
  List<TransactionModel> _transactions = [];
  List<SectionModel> _sections = [];
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _performSearch();
  }

  @override
  void didUpdateWidget(_SearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    if (widget.query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);

      // Search students
      final studentsData = await studentService.getStudents();
      _students = studentsData
          .map((data) => StudentModel.fromMap(data))
          .where((s) => s.fullName.toLowerCase().contains(widget.query.toLowerCase()))
          .toList();

      // Search transactions
      final transactionsData = await transactionService.getTransactions();
      _transactions = transactionsData
          .map((data) => TransactionModel.fromMap(data))
          .where((t) =>
              t.category.toLowerCase().contains(widget.query.toLowerCase()) ||
              (t.description?.toLowerCase().contains(widget.query.toLowerCase()) ?? false))
          .toList();

      // Search sections
      final sectionsData = await sectionService.getSections();
      _sections = sectionsData
          .map((data) => SectionModel.fromMap(data))
          .where((s) => s.sectionName.toLowerCase().contains(widget.query.toLowerCase()))
          .toList();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    final totalResults = _students.length + _transactions.length + _sections.length;

    if (totalResults == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results found for "${widget.query}"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Students (${_students.length})'),
            Tab(text: 'Transactions (${_transactions.length})'),
            Tab(text: 'Sections (${_sections.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStudentsList(),
              _buildTransactionsList(),
              _buildSectionsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList() {
    if (_students.isEmpty) {
      return const Center(child: Text('No students found'));
    }

    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(student.fullName),
          subtitle: Text('ID: ${student.prettyId ?? student.id}'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentDetailScreen(student: student),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions found'));
    }

    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final isCredit = transaction.transactionType == TransactionType.credit;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isCredit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
          title: Text(transaction.category),
          subtitle: Text(transaction.description ?? 'No description'),
          trailing: Text(
            '₦${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isCredit ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(transaction: transaction),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionsList() {
    if (_sections.isEmpty) {
      return const Center(child: Text('No sections found'));
    }

    return ListView.builder(
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.class_)),
          title: Text(section.sectionName),
          subtitle: Text('ID: ${section.id}'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SectionDetailScreen(section: section),
              ),
            );
          },
        );
      },
    );
  }
}
