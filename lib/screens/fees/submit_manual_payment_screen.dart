import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/transaction_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/utils/formatters.dart';

class SubmitManualPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> fee;
  final int studentId;

  const SubmitManualPaymentScreen({
    super.key,
    required this.fee,
    required this.studentId,
  });

  @override
  State<SubmitManualPaymentScreen> createState() => _SubmitManualPaymentScreenState();
}

class _SubmitManualPaymentScreenState extends State<SubmitManualPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _paymentMethod = 'bank_transfer';
  File? _proofFile;
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'bank_transfer',
    'mobile_money',
    'cash',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill amount with balance if available
    final double balance = (widget.fee['balance'] ?? widget.fee['amount'] ?? 0).toDouble();
    _amountController.text = balance.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() {
        _proofFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_proofFile == null && _paymentMethod != 'cash') {
      AppSnackbar.showError(context, message: 'Please upload a proof of payment.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
      
      await transactionService.submitManualPayment(
        sectionId: widget.fee['section_id'] ?? 0,
        sessionId: widget.fee['session_id'],
        termId: widget.fee['term_id'],
        studentId: widget.studentId,
        feeId: widget.fee['id'],
        amount: double.tryParse(_amountController.text) ?? 0.0,
        paymentMethod: _paymentMethod,
        transactionDate: DateTime.now().toIso8601String(),
        description: _descriptionController.text,
        proofPath: _proofFile?.path,
      );

      if (mounted) {
        AppSnackbar.showSuccess(
          context, 
          message: 'Payment proof submitted successfully. Your payment is now pending verification.',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Submission failed: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Submit Payment Proof',
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.mainGradientDecoration(context),
        child: SafeArea(
          child: _isLoading
              ? const LoadingIndicator(message: 'Submitting evidence...')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeeSummary(),
                        const SizedBox(height: 24),
                        Text(
                          'PAYMENT DETAILS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey[600],
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFormCard(),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Submit for Verification',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFeeSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.8,
        borderRadius: 24,
        hasGlow: true,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fee['fee_name'] ?? 'School Fee',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Outstanding: ${Formatters.formatCurrency((widget.fee['balance'] ?? widget.fee['amount'] ?? 0).toDouble())}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.7,
        borderRadius: 28,
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Paid Amount',
              prefixIcon: const Icon(Icons.payments_rounded),
              prefixText: '₦ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter the amount paid';
              if (double.tryParse(value) == null) return 'Invalid amount';
              return null;
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Payment Method',
              prefixIcon: const Icon(Icons.account_balance_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            value: _paymentMethod,
            items: _paymentMethods.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Text(method.replaceAll('_', ' ').toUpperCase()),
              );
            }).toList(),
            onChanged: (value) => setState(() => _paymentMethod = value!),
          ),
          const SizedBox(height: 20),
          _buildFileUpload(),
          const SizedBox(height: 20),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Additional Notes (Optional)',
              prefixIcon: const Icon(Icons.note_alt_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              hintText: 'e.g. Bank transfer reference number',
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFileUpload() {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
        ),
        child: Column(
          children: [
            Icon(
              _proofFile == null ? Icons.cloud_upload_rounded : Icons.check_circle_rounded,
              size: 48,
              color: _proofFile == null ? AppTheme.primaryColor : AppTheme.neonEmerald,
            ),
            const SizedBox(height: 8),
            Text(
              _proofFile == null ? 'Upload Proof of Payment' : 'File Selected',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _proofFile == null 
                  ? 'Tap to select receipt image or PDF' 
                  : _proofFile!.path.split('/').last,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
