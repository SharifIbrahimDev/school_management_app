import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../core/services/payment_service_api.dart';
import '../../core/services/payment_service.dart';
import '../../core/services/receipt_service.dart';
import '../../core/services/student_service_api.dart';
import '../../core/services/fee_service_api.dart';
import '../../core/models/payment_model.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_display_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/responsive_widgets.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_snackbar.dart';

class PaymentsScreen extends StatefulWidget {
  final int? studentId; // If provided, shows history for this student
  
  const PaymentsScreen({super.key, this.studentId});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  bool _isLoading = true;
  String? _error;
  List<PaymentModel> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = Provider.of<PaymentServiceApi>(context, listen: false);
      final payments = await service.getPayments(studentId: widget.studentId);
      if (mounted) {
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initiatePayment() async {
    showDialog(
      context: context,
      builder: (context) => _NewPaymentDialog(
        initialStudentId: widget.studentId,
        onPay: (amount, email, studentId, feeId) async {
          await _processPayment(amount, email, studentId, feeId);
        },
      ),
    );
  }

  Future<void> _processPayment(double amount, String email, int studentId, int feeId) async {
    await PaymentService.processPayment(
      context: context,
      amount: amount,
      email: email,
      studentId: studentId,
      feeId: feeId,
      onSuccess: (reference) {
        _loadPayments(); // Refresh list on success
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Payments',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card, color: Colors.white),
            tooltip: 'Make a Payment',
            onPressed: _initiatePayment,
          ),
        ],
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
          child: AppTheme.constrainedContent(
            context: context,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null 
                    ? ErrorDisplayWidget(error: _error!, onRetry: _loadPayments)
                    : _payments.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.payment,
                            title: 'No Payment History',
                            message: 'No recorded payments found.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPayments,
                            child: ResponsiveGridView(
                              mobileColumns: 1,
                              tabletColumns: 1,
                              desktopColumns: 2,
                              padding: AppTheme.responsivePadding(context),
                              spacing: 16,
                              runSpacing: 16,
                              children: _payments.map((payment) => _buildPaymentTile(payment)).toList(),
                            ),
                          ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTile(PaymentModel payment) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final isSuccess = payment.status == 'success';

    return Container(
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderRadius: 16,
        hasGlow: true,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
          child: Icon(
            isSuccess ? Icons.check_circle : Icons.pending,
            color: isSuccess ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          Formatters.formatCurrency(payment.amount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${payment.feeType ?? 'School Fee'} • ${payment.reference}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(payment.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSuccess ? Colors.green : Colors.orange, width: 1),
          ),
          child: Text(
            payment.status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          _showReceipt(payment);
        },
      ),
    );
  }

  Future<void> _showReceipt(PaymentModel payment) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final receiptService = ReceiptService();
      final pdfBytes = await receiptService.generateReceipt(payment);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Receipt_${payment.reference}',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.friendlyError(context, error: e);
      }
    }
  }
}

class _NewPaymentDialog extends StatefulWidget {
  final Function(double, String, int, int) onPay;
  final int? initialStudentId;

  const _NewPaymentDialog({required this.onPay, this.initialStudentId});

  @override
  State<_NewPaymentDialog> createState() => _NewPaymentDialogState();
}

class _NewPaymentDialogState extends State<_NewPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _fees = [];
  
  int? _selectedStudentId;
  int? _selectedFeeId;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
    _loadData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final feeService = Provider.of<FeeServiceApi>(context, listen: false);

      // Load all students (or fetch searched/paged in a real robust app)
      // For now, load first page or a search-friendly list
      final studentsData = await studentService.getStudents(limit: 100); 
      // Note: limit isn't in StudentServiceApi getStudents, so it returns pagination default. 
      // Assuming getStudents returns a list. If standard pagination, it might need adjustment,
      // but based on API service code, it processes 'data'['data'].
      
      final feesData = await feeService.getFees(isActive: true);

      if (mounted) {
        setState(() {
          _students = studentsData;
          _fees = feesData;
          
          // Auto-select email if student selected
          if (_selectedStudentId != null) {
            _updateEmailFromStudent(_selectedStudentId!);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateEmailFromStudent(int studentId) {
    final student = _students.firstWhere((s) => s['id'] == studentId, orElse: () => {});
    if (student.isNotEmpty) {
      _emailController.text = student['parent_email'] ?? '';
    }
  }
  
  void _updateAmountFromFee(int feeId) {
    final fee = _fees.firstWhere((f) => f['id'] == feeId, orElse: () => {});
    if (fee.isNotEmpty) {
      _amountController.text = (fee['amount'] ?? 0).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.95,
          borderRadius: 24,
          borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        child: SingleChildScrollView(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Payment',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 24),
                    
                    // Student Selection
                    DropdownButtonFormField<int>(
                      initialValue: _selectedStudentId,
                      decoration: InputDecoration(
                        labelText: 'Select Student',
                        filled: true,
                        fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _students.map((student) {
                        return DropdownMenuItem<int>(
                          value: student['id'],
                          child: Text(
                            student['student_name'] ?? 'Unknown',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedStudentId = val);
                        if (val != null) _updateEmailFromStudent(val);
                      },
                      validator: (v) => v == null ? 'Please select a student' : null,
                    ),
                    const SizedBox(height: 16),

                    // Fee Selection
                    DropdownButtonFormField<int>(
                      initialValue: _selectedFeeId,
                      decoration: InputDecoration(
                        labelText: 'Select Fee',
                        filled: true,
                        fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _fees.map((fee) {
                        return DropdownMenuItem<int>(
                          value: fee['id'],
                          child: Text(
                            "${fee['fee_name']} - ${Formatters.formatCurrency((fee['amount'] ?? 0).toDouble())}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedFeeId = val);
                        if (val != null) _updateAmountFromFee(val);
                      },
                      validator: (v) => v == null ? 'Please select a fee' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Payer Email',
                        filled: true,
                        fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v?.contains('@') == true ? null : 'Invalid email',
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (₦)',
                        filled: true,
                        fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (double.tryParse(v ?? '') ?? 0) > 0 ? null : 'Invalid amount',
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
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              widget.onPay(
                                double.parse(_amountController.text),
                                _emailController.text,
                                _selectedStudentId!,
                                _selectedFeeId!,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}
