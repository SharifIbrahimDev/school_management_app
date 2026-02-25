import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/student_model.dart';
import '../../core/models/fee_model.dart';
import '../../core/services/student_service_api.dart';
import '../../core/services/fee_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';

class ParentReportScreen extends StatefulWidget {
  final String parentId;
  final String schoolId;
  final String sectionId;

  const ParentReportScreen({
    super.key,
    required this.parentId,
    required this.schoolId,
    required this.sectionId,
  });

  @override
  State<ParentReportScreen> createState() => _ParentReportScreenState();
}

class _ParentReportScreenState extends State<ParentReportScreen> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;
  late Future<List<Map<String, dynamic>>> _allFeesFuture;

  @override
  void initState() {
    super.initState();
    final studentService = Provider.of<StudentServiceApi>(context, listen: false);
    final feeService = Provider.of<FeeServiceApi>(context, listen: false);

    _studentsFuture = studentService.getStudents(parentId: int.parse(widget.parentId));
    _allFeesFuture = feeService.getFees(sectionId: int.parse(widget.sectionId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Financial Report'),
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _studentsFuture,
          builder: (context, studentSnapshot) {
            if (studentSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator(message: 'Loading students...');
            }
            if (studentSnapshot.hasError) {
              return Center(child: Text('Error: ${studentSnapshot.error}', style: TextStyle(color: theme.colorScheme.error)));
            }

            final studentsData = studentSnapshot.data ?? [];
            final students = studentsData.map((data) => StudentModel.fromMap(data)).toList();

            if (students.isEmpty) {
              return const Center(child: Text('No students assigned.'));
            }

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _allFeesFuture,
              builder: (context, feeSnapshot) {
                if (feeSnapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Calculating totals...');
                }
                if (feeSnapshot.hasError) {
                  return Center(child: Text('Error: ${feeSnapshot.error}', style: TextStyle(color: theme.colorScheme.error)));
                }

                final allFeesData = feeSnapshot.data ?? [];
                final studentIds = students.map((s) => s.id).toSet();
                final allFees = allFeesData
                    .map((data) => FeeModel.fromMap(data))
                    .where((f) => f.studentId != null && studentIds.contains(f.studentId))
                    .toList();

                final totalAssigned = allFees.fold(0.0, (sum, fee) => sum + fee.amount);
                final totalPaid = allFees.fold(0.0, (sum, fee) => sum + (fee.amount - fee.balance));
                final totalOutstanding = totalAssigned - totalPaid;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          DashboardCard(
                            title: 'Total Fees',
                            value: Formatters.formatCurrency(totalAssigned),
                            icon: Icons.account_balance_wallet_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          DashboardCard(
                            title: 'Paid',
                            value: Formatters.formatCurrency(totalPaid),
                            icon: Icons.check_circle_rounded,
                            color: AppTheme.successColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DashboardCard(
                        title: 'Total Outstanding',
                        value: Formatters.formatCurrency(totalOutstanding),
                        icon: Icons.warning_rounded,
                        color: totalOutstanding > 0 ? AppTheme.warningColor : AppTheme.successColor,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Student Breakdown',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...students.map((student) {
                        final studentFees = allFees.where((f) => f.studentId == student.id).toList();
                        final studentAssigned = studentFees.fold<double>(0, (sum, fee) => sum + fee.amount);
                        final studentPaid = studentFees.fold<double>(0, (sum, fee) => sum + fee.amountPaid);
                        final studentOutstanding = studentAssigned - studentPaid;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: AppTheme.glassDecoration(
                            context: context,
                            opacity: 0.7,
                            borderRadius: 20,
                            hasGlow: studentOutstanding > 0,
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: Text(
                              student.fullName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSummaryItem('Due', studentAssigned, theme.colorScheme.primary),
                                  _buildSummaryItem('Paid', studentPaid, AppTheme.successColor),
                                  _buildSummaryItem('Bal', studentOutstanding, studentOutstanding > 0 ? AppTheme.warningColor : AppTheme.successColor),
                                ],
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: studentFees.map((fee) {
                                    final feeOutstanding = fee.amount - fee.amountPaid;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(fee.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text('Type: ${fee.feeType}', style: theme.textTheme.bodySmall),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(Formatters.formatCurrency(fee.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text(
                                                feeOutstanding > 0 ? 'Due' : 'Paid',
                                                style: TextStyle(
                                                  color: feeOutstanding > 0 ? AppTheme.warningColor : AppTheme.successColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textHintColor)),
        Text(
          Formatters.formatCurrency(value),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
