import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/models/fee_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/fee_service_api.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import 'edit_fee_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../../core/utils/storage_helper.dart';
import '../../core/services/pdf_invoice_service.dart';
import '../../core/services/transaction_service_api.dart';
import '../../core/services/student_service_api.dart';
import '../../core/services/payment_service.dart';
import 'payment_success_screen.dart';
import '../../widgets/custom_app_bar.dart';

class FeeDetailScreen extends StatefulWidget {
  final FeeModel fee;

  const FeeDetailScreen({
    super.key,
    required this.fee,
  });

  @override
  State<FeeDetailScreen> createState() => _FeeDetailScreenState();
}

class _FeeDetailScreenState extends State<FeeDetailScreen> {
  late FeeModel _fee;
  UserModel? _currentUser;
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];
  UserModel? _student;

  @override

  void initState() {
    super.initState();
    _fee = widget.fee;
    _loadUser();
    _loadData();
  }
  
  Future<void> _loadData() async {
    await Future.wait([
      _loadTransactions(),
      _loadStudent(),
    ]);
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    setState(() {
      _currentUser = authService.currentUserModel;
    });
  }

  Future<void> _loadStudent() async {
    try {
      if (_fee.studentId.isNotEmpty) {
        final studentService = Provider.of<StudentServiceApi>(context, listen: false);
        final studentMap = await studentService.getStudent(int.parse(_fee.studentId));
        if (studentMap != null && mounted) {
          setState(() {
            _student = UserModel.fromMap(studentMap);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading student: $e');
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
      // Filter by student and try to match some context if possible. 
      // Ideally backend filters by fee_id. 
      // For now we just load student transactions.
      final txs = await transactionService.getTransactions(
        studentId: int.tryParse(_fee.studentId),
      );
      if (mounted) {
        setState(() {
          _transactions = txs;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }

  Future<void> _deleteFee() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fee'),
        content: const Text('Are you sure you want to delete this fee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final feeService = Provider.of<FeeServiceApi>(context, listen: false);
        await feeService.deleteFee(int.tryParse(_fee.id) ?? 0);
        
        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Fee deleted successfully');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, message: 'Error deleting fee: $e');
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _generateInvoice() async {
     try {
       await PdfInvoiceService.generateAndPrintInvoice(
         fee: _fee,
         student: _student,
         schoolName: 'School Management App',
       );
     } catch (e) {
       if (mounted) {
         AppSnackbar.showError(context, message: 'Error generating invoice: $e');
       }
     }
  }

  Future<void> _payOnline() async {
    if (_currentUser?.email == null) {
      AppSnackbar.showError(context, message: 'User email not found');
      return;
    }

    final reference = PaymentService.generateReference();
    
    await PaymentService.chargeCard(
      context: context,
      amount: _fee.balance,
      email: _currentUser!.email,
      reference: reference,
      onSuccess: (ref) async {
        // Record transaction
        try {
          final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
          await transactionService.addTransaction(
            sectionId: _fee.sectionId is int ? _fee.sectionId as int : int.tryParse(_fee.sectionId.toString()) ?? 0,
            termId: int.tryParse(_fee.termId.toString()),
            sessionId: int.tryParse(_fee.sessionId.toString()),
            studentId: int.tryParse(_fee.studentId),
            transactionType: 'credit',
            amount: _fee.balance,
            paymentMethod: 'paystack',
            category: 'Tuition Fee',
            description: 'Online Payment for ${_fee.name}',
            referenceNumber: ref,
            feeId: int.tryParse(_fee.id),
            transactionDate: DateTime.now().toIso8601String(),
          );
          
          if (mounted) {
             Navigator.pushReplacement(
               context,
               MaterialPageRoute(
                 builder: (_) => PaymentSuccessScreen(
                   transactionId: ref,
                   amount: _fee.balance,
                   studentName: _student?.fullName,
                 ),
               ),
             );
          }
        } catch (e) {
           if (mounted) AppSnackbar.showError(context, message: 'Payment success but recording failed: $e');
        }
      },
      onError: (error) {
        if (mounted) AppSnackbar.showError(context, message: 'Payment failed: $error');
      },
    );
  }

  Future<void> _recordPayment() async {
    // Navigate to AddTransactionScreen with pre-filled details
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          sectionId: _fee.sectionId.toString(),
          termId: _fee.termId.toString(),
          sessionId: _fee.sessionId.toString(),
          classId: _fee.classId.toString(),
          initialAmount: _fee.balance > 0 ? _fee.balance : null,
          initialCategory: 'Tuition Fee', 
          initialDescription: 'Payment for ${_fee.name}',
          initialStudentId: _fee.studentId,
          feeId: int.tryParse(_fee.id),
        ),
      ),
    );
     // We don't necessarily update the Fee model here because the fee definition stays the same.
     // But we might want to show "Amount Paid" in Fee Detail later. For V1, this is sufficient.
  }

  @override
  Widget build(BuildContext context) {
    final role = _currentUser?.role;
    final canManageFees = role == UserRole.proprietor || 
                          role == UserRole.principal || 
                          role == UserRole.bursar;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Fee Details',
        actions: canManageFees
            ? [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    final schoolId = await StorageHelper.getSchoolId();
                    if (schoolId == null) return;
                    
                    if (mounted) {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditFeeScreen(
                            schoolId: schoolId.toString(),
                            sectionId: _fee.sectionId,
                            feeId: _fee.id,
                          ),
                        ),
                      );
                      
                      if (updated == true) {
                        // Refresh fee data
                        final feeService = Provider.of<FeeServiceApi>(context, listen: false);
                        final feeData = await feeService.getFee(int.parse(_fee.id));
                        if (feeData != null && mounted) {
                          setState(() {
                            _fee = FeeModel.fromMap(feeData);
                          });
                        }
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _deleteFee,
                ),
              ]
            : null,
      ),
      body: Container(
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // Header Card (Payment Status)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassDecoration(
                          context: context,
                          opacity: 0.8,
                          borderRadius: 28,
                          borderColor: theme.dividerColor.withOpacity(0.1),
                          hasGlow: true,
                        ).copyWith(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.white.withOpacity(0.9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Status Circle
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CircularProgressIndicator(
                                    value: _fee.isFullyPaid ? 1.0 : (_fee.amountPaid / (_fee.amount > 0 ? _fee.amount : 1)),
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _fee.isFullyPaid ? AppTheme.neonEmerald : AppTheme.neonBlue,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _fee.isFullyPaid ? Icons.check_rounded : Icons.payments_rounded,
                                  size: 40,
                                  color: _fee.isFullyPaid ? AppTheme.neonEmerald : AppTheme.neonBlue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _fee.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: (_fee.isFullyPaid ? AppTheme.neonEmerald : AppTheme.neonBlue).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _fee.status.toString().split('.').last.toUpperCase(),
                                style: TextStyle(
                                  color: _fee.isFullyPaid ? AppTheme.neonEmerald : AppTheme.neonBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Amount Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              context,
                              title: 'Total Amount',
                              value: Formatters.formatCurrency(_fee.amount),
                              icon: Icons.account_balance_wallet_rounded,
                              color: AppTheme.neonBlue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoCard(
                              context,
                              title: 'Balance Due',
                              value: Formatters.formatCurrency(_fee.balance),
                              icon: Icons.pending_actions_rounded,
                              color: _fee.balance > 0 ? AppTheme.errorColor : AppTheme.neonEmerald,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Details Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassDecoration(
                          context: context,
                          opacity: 0.6,
                          borderRadius: 24,
                        ),
                        child: Column(
                          children: [
                            _buildModernDetailRow(
                              Icons.calendar_month_rounded,
                              'Due Date',
                              Formatters.formatDate(_fee.dueDate),
                            ),
                            const Divider(height: 32),
                            _buildModernDetailRow(
                              Icons.person_rounded,
                              'Student',
                              _student?.fullName ?? 'ID: ${_fee.studentId}',
                            ),
                            const Divider(height: 32),
                            _buildModernDetailRow(
                              Icons.notes_rounded,
                              'Description',
                              _fee.description ?? 'No description provided',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _recordPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColorDark,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _payOnline,
                              icon: const Icon(Icons.bolt_rounded, size: 20),
                              label: const Text('Pay Online'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.neonBlue,
                                side: const BorderSide(color: AppTheme.neonBlue, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _generateInvoice,
                              icon: const Icon(Icons.file_download_rounded, size: 20),
                              label: const Text('Invoice'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textSecondaryColor,
                                side: BorderSide(color: theme.dividerColor, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (_transactions.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Payment History",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () {}, // TODO: See all
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._transactions.map((tx) {
                           if (tx['transaction_type'] != 'credit') return const SizedBox.shrink();
                           return Container(
                             margin: const EdgeInsets.only(bottom: 12),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(16),
                               boxShadow: [
                                 BoxShadow(
                                   color: Colors.black.withOpacity(0.03),
                                   blurRadius: 10,
                                   offset: const Offset(0, 4),
                                 ),
                               ],
                             ),
                             child: ListTile(
                               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                               leading: Container(
                                 padding: const EdgeInsets.all(10),
                                 decoration: BoxDecoration(
                                   color: AppTheme.neonEmerald.withOpacity(0.1),
                                   shape: BoxShape.circle,
                                 ),
                                 child: const Icon(Icons.check_rounded, color: AppTheme.neonEmerald, size: 18),
                               ),
                               title: Text(
                                 Formatters.formatCurrency((tx['amount'] as num).toDouble()),
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                               ),
                               subtitle: Text(
                                 Formatters.formatDate(DateTime.tryParse(tx['transaction_date']) ?? DateTime.now()),
                                 style: TextStyle(color: Colors.grey[600], fontSize: 12),
                               ),
                               trailing: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                 decoration: BoxDecoration(
                                   color: theme.dividerColor.withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: Text(
                                   (tx['payment_method'] ?? 'cash').toUpperCase(),
                                   style: TextStyle(
                                     fontSize: 10,
                                     fontWeight: FontWeight.bold,
                                     color: Colors.grey[700],
                                   ),
                                 ),
                               ),
                             ),
                           );
                        }).toList(),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.8,
        borderRadius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textHintColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  @override
  __PaymentDialogState createState() => __PaymentDialogState();
}

class __PaymentDialogState extends State<_PaymentDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.9,
          borderRadius: 24,
          borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record Payment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primaryColor),
                filled: true,
                fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(_controller.text);
                    if (amount != null && amount > 0) {
                      Navigator.pop(context, amount);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
