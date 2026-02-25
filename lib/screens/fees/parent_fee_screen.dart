import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/fee_service_api.dart';
import '../../core/services/payment_service_api.dart';
import '../../core/services/payment_service.dart';
import '../../core/models/payment_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_snackbar.dart';

class ParentFeeScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const ParentFeeScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ParentFeeScreen> createState() => _ParentFeeScreenState();
}

class _ParentFeeScreenState extends State<ParentFeeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _fees = [];
  List<PaymentModel> _payments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize Paystack with a public key
    // plugin.initialize(publicKey: "pk_test_c665607374005937400122244444555556666667"); // TODO: Replace with your actual Public Key from Paystack Dashboard
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final feeService = Provider.of<FeeServiceApi>(context, listen: false);
      final paymentService = Provider.of<PaymentServiceApi>(context, listen: false);
      
      final fees = await feeService.getFees(studentId: widget.studentId);
      final payments = await paymentService.getPayments(studentId: widget.studentId);
      
      if (mounted) {
        setState(() {
          _fees = fees;
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Fees: ${widget.studentName}',
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Outstanding'),
            Tab(text: 'History'),
          ],
        ),
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
        child: SafeArea(
          child: AppTheme.constrainedContent(
            context: context,
            child: _isLoading
                ? const Center(child: LoadingIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOutstandingFees(),
                      _buildPaymentHistory(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutstandingFees() {
    if (_fees.isEmpty) {
      return const Center(child: Text('No outstanding fees found.'));
    }

    return ListView.separated(
      padding: AppTheme.responsivePadding(context),
      itemCount: _fees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final fee = _fees[index];
        final double amount = (fee['amount'] ?? 0).toDouble();
        final double balance = (fee['balance'] ?? amount).toDouble();

        if (balance <= 0) return const SizedBox.shrink();

        return Container(
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.6, borderRadius: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(fee['fee_name'] ?? 'School Fee', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Due Date: ${fee['due_date'] ?? 'N/A'}'),
                if (fee['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(fee['description'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(balance),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _initiatePayment(fee),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    minimumSize: const Size(80, 32),
                  ),
                  child: const Text('Pay Now'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentHistory() {
    if (_payments.isEmpty) {
      return const Center(child: Text('No payment history found.'));
    }

    return ListView.separated(
      padding: AppTheme.responsivePadding(context),
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final isSuccess = payment.status == 'success';

        return Container(
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.4, borderRadius: 16),
          child: ListTile(
            title: Text(payment.feeType ?? 'Payment', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(payment.createdAt)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(payment.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSuccess ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initiatePayment(Map<String, dynamic> fee) async {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);

    final email = authService.currentUserModel?.email;
    if (email == null || email.isEmpty) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'User email not found. Cannot process payment.');
      }
      return;
    }

    final int? feeId = fee['id'] is int ? fee['id'] : int.tryParse(fee['id'].toString());
    final double amount = (fee['balance'] ?? fee['amount'] ?? 0).toDouble();

    if (feeId == null || amount <= 0) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Invalid fee or no balance due.');
      }
      return;
    }

    await PaymentService.processPayment(
      context: context,
      amount: amount,
      email: email,
      studentId: widget.studentId,
      feeId: feeId,
      onSuccess: (reference) {
        _loadData();
      },
    );
  }
}
