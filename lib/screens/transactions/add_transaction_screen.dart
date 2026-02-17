import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/transaction_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';

class AddTransactionScreen extends StatefulWidget {
  final String sectionId;
  final String termId;
  final String? sessionId;
  final String classId;

  const AddTransactionScreen({
    super.key,
    required this.sectionId,
    required this.termId,
    this.sessionId,
    required this.classId,
    this.initialAmount,
    this.initialCategory,
    this.initialDescription,
    this.initialStudentId,
    this.feeId,
  });

  final double? initialAmount;
  final String? initialCategory;
  final String? initialDescription;
  final String? initialStudentId;
  final int? feeId;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  final _studentIdController = TextEditingController();

  String _transactionType = 'credit';
  String _paymentMethod = 'cash';
  String _category = 'Tuition Fee';
  bool _isLoading = false;

  final List<String> _creditCategories = [
    'Tuition Fee',
    'Exam Fee',
    'Uniform Fee',
    'Book Fee',
    'Transport Fee',
    'Other Income'
  ];

  final List<String> _debitCategories = [
    'Salary',
    'Maintenance',
    'Utilities',
    'Supplies',
    'Transport',
    'Other Expense'
  ];

  final List<String> _paymentMethods = [
    'cash',
    'bank_transfer',
    'pos',
    'cheque'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount.toString();
    }
    if (widget.initialCategory != null) {
      _category = widget.initialCategory!;
      // Ensure category matches transaction type, simplistic check:
      if (_creditCategories.contains(_category)) {
        _transactionType = 'credit';
      } else if (_debitCategories.contains(_category)) {
        _transactionType = 'debit';
      }
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    if (widget.initialStudentId != null) {
      _studentIdController.text = widget.initialStudentId!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
      
      await transactionService.addTransaction(
        sectionId: int.tryParse(widget.sectionId) ?? 0,
        sessionId: widget.sessionId != null ? int.tryParse(widget.sessionId!) : null,
        termId: int.tryParse(widget.termId),
        studentId: _studentIdController.text.isNotEmpty ? int.tryParse(_studentIdController.text) : null,
        transactionType: _transactionType,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        paymentMethod: _paymentMethod,
        category: _category,
        description: _descriptionController.text,
        referenceNumber: _referenceController.text.isNotEmpty ? _referenceController.text : null,
        feeId: widget.feeId,
        transactionDate: DateTime.now().toIso8601String(),
      );

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Transaction added successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error adding transaction: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _transactionType == 'credit' ? _creditCategories : _debitCategories;

    // Reset category if not in current list
    if (!categories.contains(_category)) {
      _category = categories.first;
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Add Transaction',
      ),
      body: Container(
        height: double.infinity,
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
              ? const LoadingIndicator(message: 'Adding transaction...')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glassDecoration(
                        context: context,
                        opacity: 0.8,
                        borderRadius: 32,
                        hasGlow: true,
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixIcon: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
                              prefixText: '₦ ',
                              filled: true,
                              fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter an amount';
                              if (double.tryParse(value) == null) return 'Please enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: const Icon(Icons.category, color: AppTheme.primaryColor),
                              filled: true,
                              fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                            ),
                            initialValue: _category,
                            items: categories.map((category) {
                              return DropdownMenuItem(value: category, child: Text(category));
                            }).toList(),
                            onChanged: (value) => setState(() => _category = value!),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Payment Method',
                              prefixIcon: const Icon(Icons.payment, color: AppTheme.primaryColor),
                              filled: true,
                              fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                            ),
                            initialValue: _paymentMethod,
                            items: _paymentMethods.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(method.replaceAll('_', ' ').toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _paymentMethod = value!),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _referenceController,
                            decoration: InputDecoration(
                              labelText: 'Reference (Optional)',
                              prefixIcon: const Icon(Icons.receipt, color: AppTheme.primaryColor),
                              filled: true,
                              fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _studentIdController,
                            decoration: InputDecoration(
                              labelText: 'Student ID (Optional)',
                              prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
                              helperText: 'Link transaction to a specific student using their ID',
                              filled: true,
                              fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description (Optional)',
                              prefixIcon: const Icon(Icons.description, color: AppTheme.primaryColor),
                              filled: true,
                              fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              ),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _submitForm,
                        child: const Text(
                          'Add Transaction',
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
  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.4,
        borderRadius: 20,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              label: 'Income',
              type: 'credit',
              icon: Icons.trending_up_rounded,
              color: AppTheme.neonEmerald,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTypeButton(
              label: 'Expense',
              type: 'debit',
              icon: Icons.trending_down_rounded,
              color: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required String type,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _transactionType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _transactionType = type;
          _category = type == 'credit' ? _creditCategories.first : _debitCategories.first;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
