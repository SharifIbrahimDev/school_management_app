import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/fee_service_api.dart';
import '../../../core/services/student_service_api.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_display_widget.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../../widgets/notification_badge.dart';
import '../../fees/parent_fee_screen.dart';

class ParentFinanceScreen extends StatefulWidget {
  final String parentId;
  final String schoolId;

  const ParentFinanceScreen({
    super.key,
    required this.parentId,
    required this.schoolId,
  });

  @override
  State<ParentFinanceScreen> createState() => _ParentFinanceScreenState();
}

class _ParentFinanceScreenState extends State<ParentFinanceScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<StudentModel> _students = [];
  Map<String, double> _studentBalances = {};
  double _totalGlobalOutstanding = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final feeService = Provider.of<FeeServiceApi>(context, listen: false);

      final studentsData = await studentService.getStudents(
        parentId: int.tryParse(widget.parentId),
      );
      
      _students = studentsData.map((data) => StudentModel.fromMap(data)).toList();

      double globalTotal = 0.0;
      for (var student in _students) {
        final fees = await feeService.getFees(studentId: int.parse(student.id));
        double studentTotal = 0.0;
        for (var fee in fees) {
          final balance = (fee['balance'] ?? fee['amount'] ?? 0).toDouble();
          if (balance > 0) studentTotal += balance;
        }
        _studentBalances[student.id] = studentTotal;
        globalTotal += studentTotal;
      }
      _totalGlobalOutstanding = globalTotal;

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Fees & Payments',
        actions: [
          NotificationBadge(),
        ],
      ),
      body: Container(
        decoration: AppTheme.mainGradientDecoration(context),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
                  ? ErrorDisplayWidget(error: _errorMessage!, onRetry: _loadData)
                  : _students.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'No Children Found',
                          message: 'No student records are linked to your account.',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTotalOutstandingCard(),
                                const SizedBox(height: 32),
                                Text(
                                  "Breakdown by Student",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                ..._students.map((student) => _buildStudentFinanceCard(student)),
                              ],
                            ),
                          ),
                        ),
        ),
      ),
    );
  }

  Widget _buildTotalOutstandingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.1,
        borderRadius: 32,
        hasGlow: _totalGlobalOutstanding > 0,
        borderColor: AppTheme.neonPurple.withValues(alpha: 0.3),
      ).copyWith(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonPurple.withValues(alpha: 0.1),
            AppTheme.neonBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Total Amount Due",
            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(_totalGlobalOutstanding),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: _totalGlobalOutstanding > 0 ? AppTheme.errorColor : AppTheme.neonEmerald,
              letterSpacing: -1.0,
            ),
          ),
          if (_totalGlobalOutstanding > 0) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.payment_rounded),
              label: const Text("Pay All Dues"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentFinanceCard(StudentModel student) {
    final balance = _studentBalances[student.id] ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.05,
        borderRadius: 24,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
            child: Text(student.fullName[0], style: const TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  balance > 0 ? 'Pending Payment' : 'Fully Paid',
                  style: TextStyle(color: balance > 0 ? AppTheme.errorColor : AppTheme.neonEmerald, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatCurrency(balance),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentFeeScreen(
                        studentId: int.parse(student.id),
                        studentName: student.fullName,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Details',
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const DashboardCardSkeletonLoader(),
          const SizedBox(height: 32),
          const ListItemSkeletonLoader(),
          const ListItemSkeletonLoader(),
        ],
      ),
    );
  }
}
