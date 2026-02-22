import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/user_service_api.dart';
import '../../core/services/student_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_app_bar.dart';

class StudentParentLinkingScreen extends StatefulWidget {
  const StudentParentLinkingScreen({super.key});

  @override
  State<StudentParentLinkingScreen> createState() => _StudentParentLinkingScreenState();
}

class _StudentParentLinkingScreenState extends State<StudentParentLinkingScreen> {
  final TextEditingController _studentSearchController = TextEditingController();
  final TextEditingController _parentSearchController = TextEditingController();

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _parents = [];

  Map<String, dynamic>? _selectedStudent;
  Map<String, dynamic>? _selectedParent;

  bool _isLoadingStudents = false;
  bool _isLoadingParents = false;
  bool _isLinking = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _searchStudents(''),
      _searchParents(''),
    ]);
  }

  Future<void> _searchStudents(String query) async {
    setState(() => _isLoadingStudents = true);
    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final results = await studentService.getStudents(
        search: query.isEmpty ? null : query,
        limit: 50,
      );
      setState(() => _students = results);
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error fetching students: $e');
      }
    } finally {
      setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _searchParents(String query) async {
    setState(() => _isLoadingParents = true);
    try {
      final userService = Provider.of<UserServiceApi>(context, listen: false);
      final results = await userService.getUsers(
        role: 'parent',
        search: query.isEmpty ? null : query,
        limit: 50,
      );
      setState(() {
        _parents = results;
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error fetching parents: $e');
      }
    } finally {
      setState(() => _isLoadingParents = false);
    }
  }

  Future<void> _linkStudentAndParent() async {
    if (_selectedStudent == null || _selectedParent == null) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Please select both a student and a parent');
      }
      return;
    }

    setState(() => _isLinking = true);
    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      
      // Attempt to link using assignParentToStudent
      // Note: We need schoolId, sectionId, classId which might be in the student map
      final studentId = _selectedStudent!['id'].toString();
      final parentId = _selectedParent!['id'].toString();
      final schoolId = _selectedStudent!['school_id']?.toString() ?? '1';
      final sectionId = _selectedStudent!['section_id']?.toString() ?? '1';
      final classId = _selectedStudent!['class_id']?.toString() ?? '1';

      await studentService.assignParentToStudent(
        schoolId: schoolId,
        sectionId: sectionId,
        classId: classId,
        studentId: studentId,
        parentId: parentId,
      );

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Student and Parent linked successfully');
        setState(() {
          _selectedStudent = null;
          _selectedParent = null;
          _studentSearchController.clear();
          _parentSearchController.clear();
          _students = [];
          _parents = [];
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error linking: $e');
      }
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Student-Parent Linking',
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader('Step 1: Select Student', Icons.person_search),
                        const SizedBox(height: 12),
                        _buildSearchField(
                          controller: _studentSearchController,
                          hint: 'Search by student name or admission number',
                          onChanged: _searchStudents,
                          isLoading: _isLoadingStudents,
                        ),
                        if (_selectedStudent != null) 
                          _buildSelectedItemCard(
                            _getItemName(_selectedStudent!),
                            _selectedStudent!['admission_number'] ?? _selectedStudent!['admissionNumber'] ?? 'N/A',
                            () => setState(() => _selectedStudent = null),
                            AppTheme.primaryColor,
                          )
                        else if (_students.isNotEmpty)
                          _buildResultsList(_students, (item) {
                            setState(() {
                              _selectedStudent = item;
                              _students = [];
                              _studentSearchController.text = _getItemName(item);
                            });
                          }, AppTheme.primaryColor),
                        
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('Step 2: Select Parent', Icons.family_restroom),
                        const SizedBox(height: 12),
                        _buildSearchField(
                          controller: _parentSearchController,
                          hint: 'Search by parent name or email',
                          onChanged: _searchParents,
                          isLoading: _isLoadingParents,
                        ),
                        if (_selectedParent != null)
                          _buildSelectedItemCard(
                            _getItemName(_selectedParent!),
                            _selectedParent!['email'] ?? 'No email',
                            () => setState(() => _selectedParent = null),
                            Colors.orangeAccent,
                          )
                        else if (_parents.isNotEmpty)
                          _buildResultsList(_parents, (item) {
                            setState(() {
                              _selectedParent = item;
                              _parents = [];
                              _parentSearchController.text = _getItemName(item);
                            });
                          }, Colors.orangeAccent),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Link Student and Parent',
                  onPressed: _linkStudentAndParent,
                  isLoading: _isLinking,
                  icon: Icons.link,
                  backgroundColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
    required bool isLoading,
  }) {
    return Container(
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderRadius: 16,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: isLoading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
              ) 
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  String _getItemName(Map<String, dynamic> item) {
    return item['student_name'] ?? item['full_name'] ?? item['fullName'] ?? 'Unknown';
  }

  Widget _buildResultsList(List<Map<String, dynamic>> items, Function(Map<String, dynamic>) onSelect, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.4,
        borderRadius: 16,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey.withValues(alpha: 0.1)),
        itemBuilder: (context, index) {
          final item = items[index];
          final name = _getItemName(item);
          final subtitle = item['email'] ?? item['admission_number'] ?? item['admissionNumber'] ?? 'N/A';

          return ListTile(
            title: Text(name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle.toString(), style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            trailing: Icon(Icons.add_circle_outline, color: accentColor),
            onTap: () => onSelect(item),
          );
        },
      ),
    );
  }

  Widget _buildSelectedItemCard(String title, String subtitle, VoidCallback onClear, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderColor: accentColor.withValues(alpha: 0.5),
        hasGlow: true,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentColor.withValues(alpha: 0.2),
            child: Icon(Icons.check, color: accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[600]),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
