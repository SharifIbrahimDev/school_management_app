import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/class_model.dart';
import '../../core/models/section_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/user_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/empty_state_widget.dart';
import '../../core/utils/error_handler.dart';
import 'add_class_screen.dart';
import 'class_detail_screen.dart';

class ClassListScreen extends StatefulWidget {
  final Function(String?)? onSectionChanged;

  const ClassListScreen({super.key, this.onSectionChanged});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  UserModel? _currentUser;
  List<SectionModel> _assignedSections = [];
  String? _selectedSectionId;
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthServiceApi>(context, listen: false);
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      
      final userMap = authService.currentUser;
      if (userMap != null) {
        _currentUser = UserModel.fromMap(userMap);
      }

      final sectionsData = await sectionService.getSections(isActive: true);
      _assignedSections = sectionsData.map((s) => SectionModel.fromMap(s)).toList();

      if (_currentUser != null && _currentUser!.role != UserRole.proprietor) {
        _assignedSections = _assignedSections
            .where((s) => _currentUser!.assignedSections.contains(s.id))
            .toList();
      }

      if (_assignedSections.isNotEmpty) {
        _selectedSectionId = _assignedSections.first.id;
        await _loadClasses();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No sections assigned to you.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading sections: $e';
      });
    }
  }

  Future<void> _loadClasses() async {
    if (_selectedSectionId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classesData = await classService.getClasses(
        sectionId: int.tryParse(_selectedSectionId!),
      );
      if (mounted) {
        setState(() {
          _classes = classesData.map((c) => ClassModel.fromMap(c)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading classes: $e';
        });
      }
    }
  }

  Future<void> _deleteClass(ClassModel classItem) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Class',
      content: 'Are you sure you want to delete ${classItem.name}?',
      confirmText: 'Delete',
      confirmColor: Colors.red,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final classService = Provider.of<ClassServiceApi>(context, listen: false);
        await classService.deleteClass(int.parse(classItem.id));
        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Class deleted');
          _loadClasses();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackbar.friendlyError(context, error: e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrincipal = _currentUser?.role == UserRole.principal || _currentUser?.role == UserRole.proprietor;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Classes',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      floatingActionButton: _selectedSectionId != null && isPrincipal
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddClassScreen(
                        schoolId: _currentUser?.schoolId ?? '',
                        sectionId: _selectedSectionId!,
                      ),
                    ),
                  ).then((_) => _loadClasses());
                },
                backgroundColor: theme.colorScheme.primary,
                tooltip: 'Add Class',
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Class', style: TextStyle(color: Colors.white)),
              ),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/auth_bg_pattern.png'),
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
          child: _isLoading && _classes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (_assignedSections.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: AppTheme.glassDecoration(
                            context: context,
                            opacity: 0.8,
                            borderRadius: 16,
                            borderColor: theme.dividerColor.withOpacity(0.1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSectionId,
                                isExpanded: true,
                                hint: const Text('Select a Section'),
                                items: _assignedSections
                                    .map((section) => DropdownMenuItem(
                                          value: section.id,
                                          child: Text(section.sectionName),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSectionId = value;
                                  });
                                  _loadClasses();
                                  if (widget.onSectionChanged != null) widget.onSectionChanged!(value);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
                      ),

                    Expanded(
                      child: _classes.isEmpty && !_isLoading
                          ? EmptyStateWidget(
                              icon: Icons.class_outlined,
                              title: 'No Classes Yet',
                              message: 'Add your first class to this section to start managing students',
                              actionButtonText: isPrincipal ? 'Add Class' : null,
                              onActionPressed: isPrincipal
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddClassScreen(
                                            schoolId: _currentUser?.schoolId ?? '',
                                            sectionId: _selectedSectionId!,
                                          ),
                                        ),
                                      ).then((_) => _loadClasses());
                                    }
                                  : null,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _classes.length,
                              itemBuilder: (context, index) {
                                final classItem = _classes[index];
                                return _buildClassTile(classItem, isPrincipal);
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildClassTile(ClassModel classItem, bool isPrincipal) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>?>(
      future: classItem.assignedTeacherUserId != null && classItem.assignedTeacherUserId!.isNotEmpty
          ? Provider.of<UserServiceApi>(context, listen: false)
              .getUser(int.tryParse(classItem.assignedTeacherUserId!) ?? 0)
          : Future.value(null),
      builder: (context, snapshot) {
        final teacherName = snapshot.data?['full_name'] ?? 'Not assigned';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppTheme.glassDecoration(
            context: context,
            opacity: 0.7,
            borderRadius: 16,
            hasGlow: true,
            borderColor: theme.dividerColor.withOpacity(0.1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.class_rounded, color: theme.colorScheme.primary),
            ),
            title: Text(
              classItem.name,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Teacher: $teacherName', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.group_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Capacity: ${classItem.capacity ?? 'N/A'}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            trailing: isPrincipal
                ? IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                    onPressed: () => _deleteClass(classItem),
                  )
                : const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassDetailScreen(
                    classModel: classItem,
                  ),
                ),
              ).then((_) => _loadClasses());
            },
          ),
        );
      },
    );
  }
}
