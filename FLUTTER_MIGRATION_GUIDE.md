# Flutter Screen Migration Guide

## 📋 Overview

This guide provides step-by-step instructions for updating Flutter screens to use the new Laravel API instead of Firebase.

---

## 🔄 Migration Order

1. ✅ **Authentication Screens** (Login, Register) - CRITICAL
2. ✅ **Dashboard Screen** - HIGH PRIORITY
3. **Student Management** - HIGH PRIORITY
4. **Transaction Management** - HIGH PRIORITY
5. **Other Screens** - MEDIUM PRIORITY

---

## 1. Update Login Screen

### Current (Firebase):
```dart
import 'package:firebase_auth/firebase_auth.dart';

final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

### New (API):
```dart
import 'package:your_app/core/services/auth_service_api.dart';

final authService = AuthServiceApi();
final user = await authService.login(email, password);
```

### Full Example:

**File:** `lib/screens/auth/login_screen.dart`

```dart
// Add import
import 'package:your_app/core/services/auth_service_api.dart';
import 'package:your_app/core/services/api_service.dart';

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthServiceApi();
  
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        // Navigate to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

---

## 2. Update Dashboard Screen

### Current (Firebase):
```dart
final snapshot = await FirebaseFirestore.instance
    .collection('transactions')
    .where('schoolId', isEqualTo: schoolId)
    .get();
```

### New (API):
```dart
import 'package:your_app/core/services/transaction_service_api.dart';

final transactionService = TransactionServiceApi();
final stats = await transactionService.getDashboardStats(
  sectionId: sectionId,
  sessionId: sessionId,
  termId: termId,
);
```

### Full Example:

**File:** `lib/screens/dashboard/dashboard_content.dart`

```dart
// Add imports
import 'package:your_app/core/services/transaction_service_api.dart';
import 'package:your_app/core/services/auth_service_api.dart';

class _DashboardContentState extends State<DashboardContent> {
  final _transactionService = TransactionServiceApi();
  final _authService = AuthServiceApi();
  
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final stats = await _transactionService.getDashboardStats(
        sectionId: widget.sectionId,
        sessionId: widget.sessionId,
        termId: widget.termId,
      );
      
      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load dashboard data';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildFinancialOverview(),
            _buildRecentTransactions(),
            // ... other widgets
          ],
        ),
      ),
    );
  }
  
  Widget _buildFinancialOverview() {
    final totalIncome = _dashboardStats?['total_income'] ?? 0.0;
    final totalExpenses = _dashboardStats?['total_expenses'] ?? 0.0;
    final balance = _dashboardStats?['balance'] ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Total Income: \$${totalIncome.toStringAsFixed(2)}'),
            Text('Total Expenses: \$${totalExpenses.toStringAsFixed(2)}'),
            Text('Balance: \$${balance.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
```

---

## 3. Update Student List Screen

### Current (Firebase):
```dart
final snapshot = await FirebaseFirestore.instance
    .collection('students')
    .where('schoolId', isEqualTo: schoolId)
    .get();
```

### New (API):
```dart
import 'package:your_app/core/services/student_service_api.dart';

final studentService = StudentServiceApi();
final students = await studentService.getStudents(
  sectionId: sectionId,
  classId: classId,
  search: searchQuery,
);
```

### Full Example:

**File:** `lib/screens/students/student_list_screen.dart`

```dart
// Add import
import 'package:your_app/core/services/student_service_api.dart';

class _StudentListScreenState extends State<StudentListScreen> {
  final _studentService = StudentServiceApi();
  
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadStudents();
  }
  
  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final students = await _studentService.getStudents(
        sectionId: widget.sectionId,
        classId: widget.classId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load students';
          _isLoading = false;
        });
      }
    }
  }
  
  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _loadStudents();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddStudent(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search students...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _buildStudentList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudentList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            ElevatedButton(
              onPressed: _loadStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_students.isEmpty) {
      return const Center(child: Text('No students found'));
    }
    
    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return ListTile(
            title: Text(student['student_name'] ?? 'Unknown'),
            subtitle: Text(student['admission_number'] ?? ''),
            onTap: () => _navigateToStudentDetail(student['id']),
          );
        },
      ),
    );
  }
}
```

---

## 4. Update Student Detail Screen

### Current (Firebase):
```dart
final doc = await FirebaseFirestore.instance
    .collection('students')
    .doc(studentId)
    .get();
```

### New (API):
```dart
import 'package:your_app/core/services/student_service_api.dart';

final studentService = StudentServiceApi();
final student = await studentService.getStudent(studentId);
final paymentSummary = await studentService.getStudentPaymentSummary(studentId);
final transactions = await studentService.getStudentTransactions(studentId);
```

---

## 5. Update Transaction Screens

### Add Transaction:

```dart
import 'package:your_app/core/services/transaction_service_api.dart';

final transactionService = TransactionServiceApi();

await transactionService.addTransaction(
  sectionId: sectionId,
  sessionId: sessionId,
  termId: termId,
  studentId: studentId,
  transactionType: 'income', // or 'expense'
  amount: amount,
  paymentMethod: 'cash', // or 'bank_transfer', 'cheque', 'mobile_money'
  category: category,
  description: description,
  transactionDate: DateTime.now().toIso8601String().split('T')[0],
);
```

---

## 🔧 Common Patterns

### 1. Loading State
```dart
bool _isLoading = true;

setState(() => _isLoading = true);
// ... API call
setState(() => _isLoading = false);
```

### 2. Error Handling
```dart
try {
  final result = await apiService.someMethod();
} on ApiException catch (e) {
  // Handle API errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
} catch (e) {
  // Handle unexpected errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('An error occurred')),
  );
}
```

### 3. Pull to Refresh
```dart
RefreshIndicator(
  onRefresh: _loadData,
  child: ListView(...),
)
```

### 4. Search/Filter
```dart
TextField(
  onChanged: (query) {
    setState(() => _searchQuery = query);
    _loadData();
  },
)
```

---

## 📝 Checklist

### For Each Screen:

- [ ] Import new API service
- [ ] Remove Firebase imports
- [ ] Replace Firebase calls with API calls
- [ ] Update data models (if needed)
- [ ] Add loading states
- [ ] Add error handling
- [ ] Test functionality
- [ ] Test error cases
- [ ] Test offline behavior

---

## 🚨 Important Notes

### 1. Date Formatting
API expects dates in `YYYY-MM-DD` format:
```dart
final dateString = DateTime.now().toIso8601String().split('T')[0];
```

### 2. ID Types
- Firebase uses string IDs
- MySQL uses integer IDs
- Update your models accordingly

### 3. Field Names
API uses snake_case (e.g., `student_name`)
Flutter typically uses camelCase (e.g., `studentName`)
Handle conversion as needed.

### 4. Null Safety
Always check for null values:
```dart
final name = student['student_name'] ?? 'Unknown';
```

---

## 🧪 Testing

### Test Each Screen:

1. **Load Data** - Does it fetch correctly?
2. **Create** - Can you add new records?
3. **Update** - Can you edit records?
4. **Delete** - Can you remove records?
5. **Search** - Does filtering work?
6. **Error Handling** - What happens on errors?
7. **Offline** - What happens without internet?

---

## 📞 Need Help?

Common issues and solutions in `TROUBLESHOOTING.md`

---

**Last Updated**: 2025-12-02  
**Status**: Ready for implementation
