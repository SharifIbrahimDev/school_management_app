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
import 'package:url_launcher/url_launcher.dart';

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
  bool _isVerifying = false;
  final TextEditingController _rejectionController = TextEditingController();

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

      if (!context.mounted) return;
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
    if (!mounted) return;
    if (confirm == true) {
      setState(() => _isDeleting = true);
      
      try {
        final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
        await transactionService.deleteTransaction(int.tryParse(widget.transaction.id) ?? 0);
        
        if (!mounted) return;
        AppSnackbar.showSuccess(context, message: 'Transaction deleted successfully');
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isDeleting = false);
        AppSnackbar.showError(context, message: 'Error deleting transaction: $e');
      }
    }
  }

  Future<void> _verifyTransaction(TransactionStatus status) async {
    String? reason;
    
    if (status == TransactionStatus.rejected) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection (optional):'),
              const SizedBox(height: 16),
              TextField(
                controller: _rejectionController,
                decoration: const InputDecoration(
                  hintText: 'Reason for rejection',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
      reason = _rejectionController.text.trim();
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve Transaction'),
          content: const Text('Are you sure you want to approve this manual payment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approve', style: TextStyle(color: AppTheme.neonEmerald)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isVerifying = true);
    try {
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
      await transactionService.verifyTransaction(
        int.parse(widget.transaction.id),
        status: status.name,
        rejectionReason: reason,
      );
      
      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Transaction ${status == TransactionStatus.approved ? "approved" : "rejected"} successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        AppSnackbar.showError(context, message: 'Verification failed: $e');
      }
    }
  }

  Future<void> _viewProof() async {
    if (widget.transaction.proofUrl == null) return;
    final url = Uri.parse(widget.transaction.proofUrl!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Could not open proof of payment URL');
      }
    }
  }

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
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
                if (widget.transaction.transactionType == TransactionType.credit && 
                    widget.transaction.status == TransactionStatus.approved)
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

                if (widget.transaction.status == TransactionStatus.pending && 
                    (UserRole.proprietor == _currentUser?.role || 
                     UserRole.bursar == _currentUser?.role || 
                     UserRole.principal == _currentUser?.role)) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isVerifying ? null : () => _verifyTransaction(TransactionStatus.rejected),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isVerifying ? null : () => _verifyTransaction(TransactionStatus.approved),
                          icon: _isVerifying 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_rounded),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonEmerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
          if (widget.transaction.proofUrl != null) ...[
            const Divider(height: 32),
            _buildItem(
              icon: Icons.image_search_rounded,
              title: 'Proof of Payment',
              value: 'Tap to view document',
              iconColor: AppTheme.neonBlue,
              isAction: true,
              onTap: _viewProof,
            ),
          ],
          if (widget.transaction.status != TransactionStatus.approved) ...[
            const Divider(height: 32),
            _buildItem(
              icon: Icons.info_outline_rounded,
              title: 'Verification Status',
              value: widget.transaction.status.name.toUpperCase(),
              iconColor: widget.transaction.status == TransactionStatus.pending ? Colors.amber : Colors.red,
              isBold: true,
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
    bool isAction = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isAction ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Row(
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
        if (isAction)
          const Icon(Icons.open_in_new_rounded, size: 18, color: AppTheme.neonBlue),
        ],
      ),
    );
  }
}
