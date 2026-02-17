
/// Model for managing filter state
class FilterModel {
  // Date range
  DateTime? startDate;
  DateTime? endDate;
  
  // Transaction filters
  String? transactionType; // 'credit', 'debit', or null (all)
  List<String> categories;
  List<String> paymentMethods;
  
  // Sort options
  String sortBy; // 'date', 'amount', 'name'
  bool sortAscending;

  FilterModel({
    this.startDate,
    this.endDate,
    this.transactionType,
    this.categories = const [],
    this.paymentMethods = const [],
    this.sortBy = 'date',
    this.sortAscending = false,
  });

  /// Check if any filters are active
  bool get hasActiveFilters {
    return startDate != null ||
        endDate != null ||
        transactionType != null ||
        categories.isNotEmpty ||
        paymentMethods.isNotEmpty;
  }

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (startDate != null) count++;
    if (endDate != null) count++;
    if (transactionType != null) count++;
    count += categories.length;
    count += paymentMethods.length;
    return count;
  }

  /// Clear all filters
  void clear() {
    startDate = null;
    endDate = null;
    transactionType = null;
    categories = [];
    paymentMethods = [];
    sortBy = 'date';
    sortAscending = false;
  }

  /// Copy with modifications
  FilterModel copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? transactionType,
    List<String>? categories,
    List<String>? paymentMethods,
    String? sortBy,
    bool? sortAscending,
  }) {
    return FilterModel(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transactionType: transactionType ?? this.transactionType,
      categories: categories ?? this.categories,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}
