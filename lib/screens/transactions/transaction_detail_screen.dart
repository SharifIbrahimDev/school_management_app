import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/transaction_service_api.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../core/services/receipt_service.dart';
import '../../core/services/school_service_api.dart';
import '../../core/services/student_service_api.dart';
import '../../widgets/custom_app_bar.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isDeleting = false;
  bool _isGeneratingReceipt = false;
  UserModel? _currentUser;
  String? _studentName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final userMap = authService.currentUser;
    if (userMap != null) {
      setState(() {
        _currentUser = UserModel.fromMap(userMap);
      });
      _loadStudentName();
    }
  }

  Future<void> _loadStudentName() async {
    if (widget.transaction.studentId == null) return;
    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final studentData = await studentService.getStudent(int.tryParse(widget.transaction.studentId!) ?? 0);
      if (mounted && studentData != null) {
        setState(() {
          _studentName = studentData['name'] ?? '${studentData['first_name']} ${studentData['last_name']}';
        });
      }
    } catch (e) {
      debugPrint('Error loading student name: $e');
    }
  }

  Future<void> _generateReceipt() async {
    setState(() => _isGeneratingReceipt = true);
    try {
      final schoolService = Provider.of<SchoolServiceApi>(context, listen: false);
      final schoolData = await schoolService.getSchool();
      final schoolName = schoolData['name'] ?? 'School Connect';

      if (!mounted) return;
      await ReceiptService.generateAndPrintReceipt(
        transaction: widget.transaction,
        schoolName: schoolName,
        studentName: _studentName,
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error generating receipt: $e');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingReceipt = false);
    }
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      
      try {
        final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
        await transactionService.deleteTransaction(int.tryParse(widget.transaction.id) ?? 0);
        
        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Transaction deleted successfully');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          AppSnackbar.showError(context, message: 'Error deleting transaction: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _currentUser?.role == UserRole.proprietor || 
                      _currentUser?.role == UserRole.bursar ||
                      _currentUser?.role == UserRole.principal;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Transaction Details',
        actions: [
          if (canDelete)
            IconButton(
              icon: _isDeleting 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Icon(Icons.delete, color: Colors.white),
              onPressed: _isDeleting ? null : _deleteTransaction,
            ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailCard(),
                const SizedBox(height: 24),
                if (widget.transaction.transactionType == TransactionType.credit)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingReceipt ? null : _generateReceipt,
                      icon: _isGeneratingReceipt 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.receipt_long_rounded),
                      label: const Text('Generate Professional Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderRadius: 20,
        hasGlow: true,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildItem(
            icon: Icons.category_outlined,
            title: 'Category',
            value: widget.transaction.category,
            iconColor: Colors.blue,
          ),
          const Divider(height: 32),
          _buildItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Amount',
            value: Formatters.formatCurrency(widget.transaction.amount),
            iconColor: Colors.green,
            valueColor: widget.transaction.transactionType == TransactionType.credit ? Colors.green : Colors.red,
            isBold: true,
          ),
          const Divider(height: 32),
          _buildItem(
            icon: Icons.swap_horiz_outlined,
            title: 'Type',
            value: widget.transaction.transactionTypeDisplayName,
            iconColor: Colors.orange,
          ),
          const Divider(height: 32),
          _buildItem(
            icon: Icons.payment_outlined,
            title: 'Payment Method',
            value: widget.transaction.paymentTypeDisplayName,
            iconColor: Colors.purple,
          ),
          const Divider(height: 32),
          _buildItem(
            icon: Icons.description_outlined,
            title: 'Description',
            value: widget.transaction.description ?? 'No description',
            iconColor: Colors.teal,
          ),
          const Divider(height: 32),
          _buildItem(
            icon: Icons.calendar_today_outlined,
            title: 'Date',
            value: Formatters.formatDate(widget.transaction.createdAt),
            iconColor: Colors.blueGrey,
          ),
          const Divider(height: 32),
          _buildItem(
            icon: Icons.class_outlined,
            title: 'Section ID',
            value: widget.transaction.sectionId,
            iconColor: Colors.indigo,
          ),
          if (widget.transaction.studentId != null) ...[
            const Divider(height: 32),
            _buildItem(
              icon: Icons.person_outline,
              title: 'Student ID',
              value: widget.transaction.studentId!,
              iconColor: Colors.deepOrange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
