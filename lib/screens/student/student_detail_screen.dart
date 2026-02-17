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
import '../../core/utils/app_snackbar.dart';
import '../../widgets/detail_item.dart';
import 'student_section_linking_screen.dart';
import 'assign_parent_screen.dart';
import '../../widgets/custom_app_bar.dart';

class StudentDetailScreen extends StatefulWidget {
  final StudentModel student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  _StudentDetailScreenState createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  bool _isDeleting = false;
  String? _className;
  String? _parentName;
  bool _loadingInfo = true;
  List<Map<String, dynamic>> _fees = [];
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loadingInfo = true);

    try {
      final authService = Provider.of<AuthServiceApi>(context, listen: false);
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final userService = Provider.of<UserServiceApi>(context, listen: false);
      final feeService = Provider.of<FeeServiceApi>(context, listen: false);

      // Get current user
      final userMap = authService.currentUser;
      _currentUser = userMap != null ? UserModel.fromMap(userMap) : null;

      // Get class name
      String? className;
      if (widget.student.classId.isNotEmpty) {
        try {
          final classData = await classService.getClass(int.tryParse(widget.student.classId) ?? 0);
          className = classData?['class_name'] ?? classData?['name'] ?? 'Unknown';
        } catch (e) {
          className = 'Unknown';
        }
      } else {
        className = 'Unassigned';
      }

      // Get parent name
      String? parentName;
      if (widget.student.parentId != null && widget.student.parentId!.isNotEmpty) {
        try {
          final parentData = await userService.getUser(int.tryParse(widget.student.parentId!) ?? 0);
          parentName = parentData?['full_name'] ?? parentData?['fullName'] ?? 'Unknown';
        } catch (e) {
          parentName = 'Unknown';
        }
      } else {
        parentName = 'Not assigned';
      }

      // Get fees - use first section if multiple sections assigned
      try {
        final primarySectionId = widget.student.sectionIds.isNotEmpty 
          ? int.tryParse(widget.student.sectionIds.first) 
          : null;
        
        if (primarySectionId != null) {
          _fees = await feeService.getFees(
            sectionId: primarySectionId,
            studentId: int.tryParse(widget.student.id),
          );
        }
      } catch (e) {
        debugPrint('Error loading fees: $e');
        _fees = [];
      }

      if (mounted) {
        setState(() {
          _className = className;
          _parentName = parentName;
          _loadingInfo = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() => _loadingInfo = false);
      }
    }
  }

  Future<void> _deleteStudent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${widget.student.fullName}?'),
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
        final studentService = Provider.of<StudentServiceApi>(context, listen: false);
        await studentService.deleteStudent(int.tryParse(widget.student.id) ?? 0);
        
        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Student deleted successfully');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          AppSnackbar.showError(context, message: 'Error deleting student: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = _currentUser?.role;
    final List<Widget> actionButtons = [];

    // 1. Manage Sections (Proprietor & Principal)
    if (role == UserRole.proprietor || role == UserRole.principal) {
      actionButtons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentSectionLinkingScreen(student: widget.student),
                ),
              );
              if (result == true && mounted) {
                // Reload data if sections were updated
                _loadData();
              }
            },
            icon: const Icon(Icons.school, size: 20),
            label: const Text("Sections", overflow: TextOverflow.ellipsis),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonTeal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
          ),
        ),
      );
    }

    // 2. Edit (Proprietor & Principal)
    if (role == UserRole.proprietor || role == UserRole.principal) {
      if (actionButtons.isNotEmpty) actionButtons.add(const SizedBox(width: 8));
      actionButtons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to edit screen
              AppSnackbar.showInfo(context, message: 'Edit feature coming soon');
            },
            icon: const Icon(Icons.edit, size: 20),
            label: const Text("Edit"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
          ),
        ),
      );
    }

    // 3. Assign Parent (Proprietor, Principal, Bursar)
    if (role == UserRole.proprietor || role == UserRole.principal || role == UserRole.bursar) {
      if (actionButtons.isNotEmpty) actionButtons.add(const SizedBox(width: 8));
      actionButtons.add(
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignParentScreen(student: widget.student),
                ),
              ).then((result) {
                if (result == true) {
                  _loadData(); // Refresh if parent was changed
                }
              });
            },
            icon: const Icon(Icons.family_restroom, size: 20),
            label: const Text("Parent", overflow: TextOverflow.ellipsis),
          ),
        ),
      );
    }

    // 4. Delete (Proprietor & Principal)
    if (role == UserRole.proprietor || role == UserRole.principal) {
      if (actionButtons.isNotEmpty) actionButtons.add(const SizedBox(width: 8));
      actionButtons.add(
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            onPressed: _isDeleting ? null : _deleteStudent,
            icon: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete, size: 20),
            label: const Text("Delete"),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.student.fullName,
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
          child: _loadingInfo
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Assigned Fees
                      if (_fees.isNotEmpty) ...[
                        Text(
                          'Assigned Fees',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: AppTheme.glassDecoration(
                            context: context,
                            opacity: 0.6,
                            borderRadius: 12,
                            borderColor: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _fees.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
                            itemBuilder: (context, index) {
                              final fee = _fees[index];
                              return ListTile(
                                leading: const Icon(Icons.payment, color: AppTheme.primaryColor),
                                title: Text(fee['fee_type'] ?? fee['feeType'] ?? 'Fee'),
                                subtitle: Text('Amount: ${Formatters.formatCurrency((fee['amount'] as num?)?.toDouble() ?? 0.0)}'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Student Info Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassDecoration(
                          context: context,
                          opacity: 0.7,
                          borderRadius: 24,
                          hasGlow: true,
                          borderColor: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                        child: Column(
                          children: [
                            DetailItem(
                              icon: Icons.person,
                              title: 'Full Name',
                              value: widget.student.fullName,
                            ),
                            const SizedBox(height: 12),
                            DetailItem(
                              icon: Icons.class_,
                              title: 'Class',
                              value: _className ?? 'Unassigned',
                            ),
                            const SizedBox(height: 12),
                            // Assigned Sections
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.school, color: theme.primaryColor, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Assigned Sections',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      widget.student.sectionIds.isEmpty
                                          ? Text(
                                              'No sections assigned',
                                              style: theme.textTheme.bodyMedium,
                                            )
                                          : Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: widget.student.sectionIds.map((sectionId) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.neonTeal.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(
                                                      color: AppTheme.neonTeal.withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Section $sectionId',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.neonTeal,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DetailItem(
                              icon: Icons.supervisor_account,
                              title: 'Parent',
                              value: _parentName ?? 'Not assigned',
                            ),
                            const SizedBox(height: 12),
                            DetailItem(
                              icon: Icons.calendar_today,
                              title: 'Created',
                              value: Formatters.formatDate(widget.student.createdAt),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),

      bottomNavigationBar: actionButtons.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: actionButtons,
                ),
              ),
            ),
    );
  }
}
