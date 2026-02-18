import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/student_model.dart';
import '../core/models/user_model.dart';
import '../core/services/student_service_api.dart';
import '../core/services/user_service_api.dart';
import '../core/services/auth_service_api.dart';
import '../core/utils/app_theme.dart';
import '../core/utils/responsive_utils.dart';
import '../screens/student/add_student_screen.dart';
import '../screens/student/student_detail_screen.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_display_widget.dart';
import 'loading_indicator.dart';
import 'responsive_widgets.dart';

class StudentListWidget extends StatefulWidget {
  final String schoolId;
  final String sectionId;
  final String classId;

  const StudentListWidget({
    super.key,
    required this.schoolId,
    required this.sectionId,
    required this.classId,
  });

  @override
  State<StudentListWidget> createState() => _StudentListWidgetState();
}

class _StudentListWidgetState extends State<StudentListWidget> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _handleBulkExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting ${_selectedIds.length} students to PDF...')),
    );
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentService = Provider.of<StudentServiceApi>(context, listen: false);
    final userService = Provider.of<UserServiceApi>(context, listen: false);
    final authService = Provider.of<AuthServiceApi>(context, listen: false);

    final role = authService.currentUserModel?.role;
    final canAddStudent = role == UserRole.proprietor || role == UserRole.principal;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text('${_selectedIds.length} Selected', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() {
                        _isSelectionMode = false;
                        _selectedIds.clear();
                      }),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: studentService.getStudents(
                sectionId: int.tryParse(widget.sectionId),
                classId: int.tryParse(widget.classId),
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorDisplayWidget(
                    error: snapshot.error.toString(),
                    onRetry: () => setState(() {}),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: LoadingIndicator());
                }

                final studentsData = snapshot.data!;
                final students = studentsData.map((data) => StudentModel.fromMap(data)).toList();

                if (students.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.school,
                    title: 'No Students Yet',
                    message: 'Add your first student to get started',
                    actionButtonText: canAddStudent ? 'Add Student' : null,
                    onActionPressed: canAddStudent ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddStudentScreen(
                            arguments: {
                              'schoolId': widget.schoolId,
                              'sectionId': widget.sectionId,
                              'classId': widget.classId,
                            },
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    } : null,
                  );
                }

                return ResponsiveGridView(
                  mobileColumns: 1,
                  tabletColumns: 2,
                  desktopColumns: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  spacing: 16,
                  runSpacing: 16,
                  children: students.map((student) {
                    final isSelected = _selectedIds.contains(student.id);

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: student.parentId != null
                          ? userService.getUser(int.tryParse(student.parentId!) ?? 0)
                          : Future.value(null),
                      builder: (context, parentSnapshot) {
                        final parentName = parentSnapshot.hasData && parentSnapshot.data != null
                            ? (parentSnapshot.data!['full_name'] ?? parentSnapshot.data!['fullName'] ?? 'Unassigned')
                            : "Unassigned";

                        if (context.isMobile) {
                          return Container(
                            decoration: AppTheme.glassDecoration(
                              context: context,
                              opacity: 0.6,
                              borderRadius: 12,
                              borderColor: theme.dividerColor.withValues(alpha: 0.1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: _isSelectionMode 
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _toggleSelection(student.id),
                                    activeColor: AppTheme.primaryColor,
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.person, color: AppTheme.accentColor, size: 20),
                                  ),
                              title: Text(
                                student.fullName,
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'Parent: $parentName',
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryColor),
                              ),
                              onLongPress: () {
                                if (!_isSelectionMode) {
                                  setState(() {
                                    _isSelectionMode = true;
                                    _selectedIds.add(student.id);
                                  });
                                }
                              },
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(student.id);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => StudentDetailScreen(student: student)),
                                  );
                                }
                              },
                            ),
                          );
                        }

                        // Desktop/Tablet Card View
                        return Container(
                          decoration: AppTheme.glassDecoration(
                            context: context,
                            opacity: 0.6,
                            borderRadius: 20,
                            hasGlow: true,
                            borderColor: isSelected ? AppTheme.primaryColor : theme.dividerColor.withValues(alpha: 0.1),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(student.id);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => StudentDetailScreen(student: student)),
                                );
                              }
                            },
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedIds.add(student.id);
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          student.fullName[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_isSelectionMode)
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (_) => _toggleSelection(student.id),
                                          activeColor: AppTheme.primaryColor,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    student.fullName,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${student.prettyId ?? student.id}',
                                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 16, color: AppTheme.accentColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Parent: $parentName',
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        if (_isSelectionMode)
          Positioned(
            bottom: context.isMobile ? 100 : 20, // Lift higher on mobile to clear bottom nav
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: AppTheme.glassDecoration(
                context: context,
                opacity: 0.9,
                borderRadius: 40,
                hasGlow: true,
                borderColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BulkActionItem(icon: Icons.picture_as_pdf_outlined, label: 'Export', onTap: _handleBulkExport),
                  _BulkActionItem(icon: Icons.archive_outlined, label: 'Archive', onTap: () {}),
                  _BulkActionItem(icon: Icons.ios_share_outlined, label: 'Promote', onTap: () {}),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BulkActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BulkActionItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ],
      ),
    );
  }
}
