import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/student_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/user_service_api.dart';
import '../../core/services/student_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';

class AssignParentScreen extends StatefulWidget {
  final StudentModel student;

  const AssignParentScreen({
    super.key,
    required this.student,
  });

  @override
  State<AssignParentScreen> createState() => _AssignParentScreenState();
}

class _AssignParentScreenState extends State<AssignParentScreen> {
  List<UserModel> _parents = [];
  List<UserModel> _filteredParents = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParents({String? query}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userService = Provider.of<UserServiceApi>(context, listen: false);
      final parentsData = await userService.getUsers(
        role: 'parent',
        search: query,
        limit: 50, // Increase limit to find more potential parents
      );
      
      final parents = parentsData
          .map((data) => UserModel.fromMap(data))
          .toList();

      if (mounted) {
        setState(() {
          _parents = parents;
          _filteredParents = parents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading parents: $e';
        });
      }
    }
  }

  void _filterParents(String query) {
    if (query.length >= 2 || query.isEmpty) {
      _loadParents(query: query.isEmpty ? null : query);
    }
  }

  Future<void> _assignParent(String? parentId, bool isUnassigning) async {
    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      
      final message = await studentService.assignParentToStudent(
        schoolId: widget.student.schoolId,
        sectionId: widget.student.sectionIds.isNotEmpty ? widget.student.sectionIds.first : '',
        classId: widget.student.classId,
        studentId: widget.student.id,
        parentId: isUnassigning ? null : parentId,
      );

      if (mounted) {
        AppSnackbar.showSuccess(context, message: message);
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Assign Parent',
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
              AppTheme.primaryColor.withValues(alpha: 0.05),
              AppTheme.accentColor.withValues(alpha: 0.05),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Current Parent Info if assigned
              if (widget.student.parentId != null && !_isLoading) ...[
                 Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Container(
                     decoration: AppTheme.glassDecoration(
                       context: context, 
                       borderRadius: 12,
                       borderColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                     ),
                     padding: const EdgeInsets.all(16),
                     child: Row(
                       children: [
                         const CircleAvatar(
                           backgroundColor: AppTheme.primaryColor,
                           child: Icon(Icons.family_restroom, color: Colors.white),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text('Assigned Parent', style: TextStyle(
                                 fontSize: 12, color: Colors.grey
                               )),
                               // Note: We don't have the current parent object here easily unless we fetch it.
                               // But we can unassign.
                               const Text('Current Parent Linked', style: TextStyle(
                                 fontWeight: FontWeight.bold,
                               )),
                             ],
                           ),
                         ),
                         TextButton.icon(
                           onPressed: () => _assignParent(null, true),
                           icon: const Icon(Icons.link_off, color: Colors.red),
                           label: const Text('Unlink', style: TextStyle(color: Colors.red)),
                         ),
                       ],
                     ),
                   ),
                 ),
              ],

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search parents by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _filterParents,
                ),
              ),

              // List
              Expanded(
                child: _isLoading 
                  ? const Center(child: LoadingIndicator())
                  : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _filteredParents.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.person_search,
                          title: 'No Parents Found',
                          message: 'Try a different search term or add a new parent user.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredParents.length,
                          itemBuilder: (context, index) {
                            final parent = _filteredParents[index];
                            final isAssigned = widget.student.parentId == parent.id;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: AppTheme.glassDecoration(
                                context: context,
                                borderRadius: 12,
                                hasGlow: isAssigned,
                                opacity: 0.6,
                                borderColor: isAssigned 
                                  ? AppTheme.primaryColor 
                                  : theme.dividerColor.withValues(alpha: 0.1),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
                                  child: Text(
                                    parent.initials,
                                    style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(parent.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(parent.email),
                                trailing: isAssigned
                                  ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                                  : ElevatedButton(
                                      onPressed: () => _assignParent(parent.id, false),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                      child: const Text('Assign'),
                                    ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
