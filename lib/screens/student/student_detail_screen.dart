import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/student_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/student_service_api.dart';
import '../../core/services/user_service_api.dart';
import '../../core/services/fee_service_api.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import 'student_section_linking_screen.dart';
import 'assign_parent_screen.dart';
import 'edit_student_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/loading_indicator.dart';

class StudentDetailScreen extends StatefulWidget {
  final StudentModel student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  bool _isDeleting = false;
  String? _className;
  String? _parentName;
  bool _loadingInfo = true;
  List<Map<String, dynamic>> _fees = [];
  List<Map<String, dynamic>> _transactions = [];
  UserModel? _currentUser;
  late StudentModel _student;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _loadData();
  }

  Future<void> _refreshStudent() async {
    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final fresh = await studentService.getStudent(int.parse(_student.id), forceRefresh: true);
      if (fresh != null && mounted) {
        setState(() => _student = StudentModel.fromMap(fresh));
      }
    } catch (e) {
      debugPrint('Error refreshing student: $e');
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loadingInfo = true);

    try {
      final authService = Provider.of<AuthServiceApi>(context, listen: false);
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final userService = Provider.of<UserServiceApi>(context, listen: false);
      final feeService = Provider.of<FeeServiceApi>(context, listen: false);

      final userMap = authService.currentUser;
      _currentUser = userMap != null ? UserModel.fromMap(userMap) : null;

      String? className;
      if (_student.classId.isNotEmpty) {
        try {
          final classData = await classService.getClass(int.tryParse(_student.classId) ?? 0);
          className = classData?['class_name'] ?? classData?['name'] ?? 'Unknown';
        } catch (e) { className = 'Unknown'; }
      } else { className = 'Unassigned'; }

      String? parentName;
      if (_student.parentId != null && _student.parentId!.isNotEmpty) {
        try {
          final parentData = await userService.getUser(int.tryParse(_student.parentId!) ?? 0);
          parentName = parentData?['full_name'] ?? parentData?['fullName'] ?? 'Unknown';
        } catch (e) { parentName = 'Unknown'; }
      } else { parentName = 'Not assigned'; }

      final primarySectionId = _student.sectionIds.isNotEmpty ? int.tryParse(_student.sectionIds.first) : null;

      try {
        if (primarySectionId != null) {
          _fees = await feeService.getFees(sectionId: primarySectionId, studentId: int.tryParse(_student.id));
        }
      } catch (e) { debugPrint('Error loading fees: $e'); }

      try {
        final studentId = int.tryParse(widget.student.id);
        if (studentId != null) {
          final studentService = Provider.of<StudentServiceApi>(context, listen: false);
          _transactions = await studentService.getStudentTransactions(studentId);
        }
      } catch (e) { debugPrint('Error loading transactions: $e'); }

      if (mounted) {
        setState(() {
          _className = className;
          _parentName = parentName;
          _loadingInfo = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingInfo = false);
    }
  }

  Future<void> _deleteStudent() async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Decommission Identity',
      content: 'Are you sure you want to permanently remove ${widget.student.fullName} from the registry?',
      confirmText: 'DESTRUCTION CONFIRMED',
      confirmColor: Colors.red,
      icon: Icons.person_remove_rounded,
    );
    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        final studentService = Provider.of<StudentServiceApi>(context, listen: false);
        await studentService.deleteStudent(int.tryParse(widget.student.id) ?? 0);
        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Identity decommissioned.');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          AppSnackbar.friendlyError(context, error: e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingInfo) return const Scaffold(body: Center(child: LoadingIndicator(message: 'Loading Identity Matrix...')));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Identity Profile',
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _loadData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.mainGradientDecoration(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildQuickStats(),
                const SizedBox(height: 24),
                _buildModernSection(
                  title: 'ACADEMIC PLACEMENT',
                  icon: Icons.school_rounded,
                  children: [
                    _buildInfoRow('Current Class', _className ?? 'N/A'),
                    _buildInfoRow('Admission No.', widget.student.admissionNumber ?? 'N/A'),
                    _buildSectionChips(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernSection(
                  title: 'BIOGRAPHIC DATA',
                  icon: Icons.fingerprint_rounded,
                  children: [
                    _buildInfoRow('Guardianship', _parentName ?? 'Not Assigned'),
                    _buildInfoRow('Date of Entry', Formatters.formatDate(widget.student.createdAt)),
                    _buildInfoRow('Status', 'Active Enrollment', color: AppTheme.neonEmerald),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActivitySection(),
                const SizedBox(height: 40),
                _buildModernActions(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassDecoration(context: context, opacity: 0.8, borderRadius: 32, hasGlow: true),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.mainGradient(context),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)],
            ),
            child: Center(
              child: Text(
                widget.student.fullName[0].toUpperCase(),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.student.fullName.toUpperCase(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'REGISTRY ID: #${widget.student.id.padLeft(4, '0')}',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[600], letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(
              _className?.toUpperCase() ?? 'UNASSIGNED',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    double totalFees = 0;
    for (var f in _fees) totalFees += (f['amount'] as num?)?.toDouble() ?? 0;
    
    return Row(
      children: [
        _buildStatChip(Icons.account_balance_wallet_rounded, 'FEES', Formatters.formatCurrency(totalFees), AppTheme.accentColor),
        const SizedBox(width: 12),
        _buildStatChip(Icons.done_all_rounded, 'PRESENCE', '92%', AppTheme.neonEmerald),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(context: context, opacity: 0.6, borderRadius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSection({required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 12, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.textSecondaryColor)),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.5, borderRadius: 24),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSectionChips() {
    if (widget.student.sectionIds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.student.sectionIds.map((id) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.neonTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.neonTeal.withValues(alpha: 0.2))),
          child: Text('SECTION $id', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.neonTeal)),
        )).toList(),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 12, bottom: 8),
          child: Text('TEMPORAL LOGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.textSecondaryColor)),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.5, borderRadius: 24),
          child: _transactions.isEmpty && _fees.isEmpty
              ? const Center(child: Text('No historical data found.', style: TextStyle(fontSize: 12, color: Colors.grey)))
              : Column(
                  children: [
                    _buildTimelineItem(Icons.how_to_reg_rounded, AppTheme.neonBlue, 'IDENTITY CREATED', widget.student.createdAt, 'Registry initialized.'),
                    ..._transactions.map((t) => _buildTimelineItem(
                      Icons.account_balance_rounded, 
                      AppTheme.neonEmerald, 
                      'CREDIT: ${Formatters.formatCurrency((t['amount'] as num?)?.toDouble() ?? 0)}', 
                      DateTime.tryParse(t['transaction_date'] ?? '') ?? DateTime.now(), 
                      'Via ${t['payment_method'] ?? 'System'}'
                    )),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(IconData icon, Color color, String title, DateTime date, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(Formatters.formatDate(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActions() {
    final role = _currentUser?.role;
    final isAdmin = role == UserRole.proprietor || role == UserRole.principal;
    
    return Column(
      children: [
        if (isAdmin)
          _buildActionButton(Icons.auto_fix_high_rounded, 'MODIFY IDENTITY', AppTheme.primaryColor, () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => EditStudentScreen(student: widget.student)));
            _loadData();
          }),
        const SizedBox(height: 12),
        if (isAdmin)
          _buildActionButton(Icons.family_restroom_rounded, 'ASSIGN GUARDIAN', AppTheme.accentColor, () async {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => AssignParentScreen(student: _student)));
            if (res == true) {
              await _refreshStudent();
              _loadData();
            }
          }),
        const SizedBox(height: 12),
        if (isAdmin)
          _buildActionButton(Icons.no_accounts_rounded, 'DECOMMISSION', Colors.redAccent, _deleteStudent, outlined: true),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap, {bool outlined = false}) {
    return SizedBox(
      width: double.infinity,
      child: outlined 
        ? OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
    );
  }
}
