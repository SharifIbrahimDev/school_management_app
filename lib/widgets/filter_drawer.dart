import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/filter_model.dart';

/// Reusable filter drawer for list screens
class FilterDrawer extends StatefulWidget {
  final FilterModel initialFilters;
  final Function(FilterModel) onApply;
  final bool showTransactionFilters;
  final bool showDateFilters;

  const FilterDrawer({
    super.key,
    required this.initialFilters,
    required this.onApply,
    this.showTransactionFilters = true,
    this.showDateFilters = true,
  });

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  late FilterModel _filters;
  
  final List<String> _availableCategories = [
    'Tuition',
    'Fees',
    'Salary',
    'Utilities',
    'Maintenance',
    'Other',
  ];

  final List<String> _availablePaymentMethods = [
    'Cash',
    'Bank Transfer',
    'Cheque',
    'Online',
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.primaryColor,
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_filters.hasActiveFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_filters.activeFilterCount}',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Filters
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date Range
                  if (widget.showDateFilters) ...[
                    _buildSectionTitle('Date Range'),
                    _buildDateRangeSelector(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Transaction Type
                  if (widget.showTransactionFilters) ...[
                    _buildSectionTitle('Transaction Type'),
                    _buildTransactionTypeSelector(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Categories
                  if (widget.showTransactionFilters) ...[
                    _buildSectionTitle('Categories'),
                    _buildCategoryChips(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Payment Methods
                  if (widget.showTransactionFilters) ...[
                    _buildSectionTitle('Payment Methods'),
                    _buildPaymentMethodChips(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Sort Options
                  _buildSectionTitle('Sort By'),
                  _buildSortOptions(),
                ],
              ),
            ),
            
            // Footer Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _filters.clear();
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        widget.onApply(_filters);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text(
          _filters.startDate != null && _filters.endDate != null
              ? '${dateFormat.format(_filters.startDate!)} - ${dateFormat.format(_filters.endDate!)}'
              : 'Select Date Range',
          style: TextStyle(
            color: _filters.startDate != null ? null : Colors.grey,
          ),
        ),
        trailing: _filters.startDate != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _filters.startDate = null;
                    _filters.endDate = null;
                  });
                },
              )
            : null,
        onTap: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange: _filters.startDate != null && _filters.endDate != null
                ? DateTimeRange(start: _filters.startDate!, end: _filters.endDate!)
                : null,
          );
          
          if (picked != null) {
            setState(() {
              _filters.startDate = picked.start;
              _filters.endDate = picked.end;
            });
          }
        },
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return RadioGroup<String?>(
      groupValue: _filters.transactionType,
      onChanged: (value) => setState(() => _filters.transactionType = value),
      child: Column(
        children: [
          RadioListTile<String?>(
            title: const Text('All'),
            value: null,
          ),
          RadioListTile<String?>(
            title: const Text('Income (Credit)'),
            value: 'credit',
          ),
          RadioListTile<String?>(
            title: const Text('Expense (Debit)'),
            value: 'debit',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableCategories.map((category) {
        final isSelected = _filters.categories.contains(category);
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _filters.categories = [..._filters.categories, category];
              } else {
                _filters.categories = _filters.categories.where((c) => c != category).toList();
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availablePaymentMethods.map((method) {
        final isSelected = _filters.paymentMethods.contains(method);
        return FilterChip(
          label: Text(method),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _filters.paymentMethods = [..._filters.paymentMethods, method];
              } else {
                _filters.paymentMethods = _filters.paymentMethods.where((m) => m != method).toList();
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortOptions() {
    return RadioGroup<String>(
      groupValue: _filters.sortBy,
      onChanged: (value) => setState(() => _filters.sortBy = value!),
      child: Column(
        children: [
          RadioListTile<String>(
            title: const Text('Date'),
            value: 'date',
          ),
          RadioListTile<String>(
            title: const Text('Amount'),
            value: 'amount',
          ),
          RadioListTile<String>(
            title: const Text('Name/Category'),
            value: 'name',
          ),
          SwitchListTile(
            title: const Text('Ascending Order'),
            value: _filters.sortAscending,
            onChanged: (value) => setState(() => _filters.sortAscending = value),
          ),
        ],
      ),
    );
  }
}
