import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/services/student_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/models/section_model.dart';
import '../../core/models/class_model.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';

class AddStudentScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const AddStudentScreen({
    super.key,
    this.arguments,
  });

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _admissionNumberController = TextEditingController();
  final _parentIdController = TextEditingController();
  
  String? _selectedSectionId;
  String? _selectedClassId;
  Set<String> _additionalSectionIds = {};
  
  List<SectionModel> _sections = [];
  List<ClassModel> _classes = [];
  bool _isLoadingData = true;
  bool _isLoadingClasses = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.arguments != null) {
      _selectedSectionId = widget.arguments!['sectionId']?.toString();
      _selectedClassId = widget.arguments!['classId']?.toString();
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final sectionsData = await sectionService.getSections(isActive: true);
      
      if (mounted) {
        setState(() {
          _sections = sectionsData.map((data) => SectionModel.fromMap(data)).toList();
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error loading sections: $e');
        setState(() => _isLoadingData = false);
      }
    }

    if (_selectedSectionId != null) {
      await _loadClasses(_selectedSectionId!);
    }
  }

  Future<void> _loadClasses(String sectionId) async {
    setState(() {
      _isLoadingClasses = true;
      _classes = [];
      _selectedClassId = null;
    });

    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classesData = await classService.getClasses(sectionId: int.tryParse(sectionId));
      
      if (mounted) {
        setState(() {
          _classes = classesData.map((data) => ClassModel.fromMap(data)).toList();
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error loading classes: $e');
        setState(() => _isLoadingClasses = false);
      }
    }
  }

  void _showAdditionalSectionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final availableForAddition = _sections.where((s) => s.id != _selectedSectionId).toList();
            
            return AlertDialog(
              title: const Text('Additional Sections'),
              content: SizedBox(
                width: double.maxFinite,
                child: availableForAddition.isEmpty 
                  ? const Text('No other sections available.') 
                  : ListView(
                      shrinkWrap: true,
                      children: availableForAddition.map((section) {
                        final isSelected = _additionalSectionIds.contains(section.id);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(section.sectionName),
                          onChanged: (bool? value) {
                            setState(() { // Update main state
                              if (value == true) {
                                _additionalSectionIds.add(section.id);
                              } else {
                                _additionalSectionIds.remove(section.id);
                              }
                            });
                            setStateDialog(() {}); // Update dialog state
                          },
                        );
                      }).toList(),
                    ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _admissionNumberController.dispose();
    _parentIdController.dispose();
    super.dispose();
  }

  Future<void> _addStudent() async {
    if (_formKey.currentState!.validate()) {
      // Validation for Section/Class is now optional, so no manual check here

      setState(() => _isLoading = true);
      
      try {
        final studentService = Provider.of<StudentServiceApi>(context, listen: false);

        // 1. Create Student (possibly without Section/Class)
        final newStudentData = await studentService.createStudent(
          sectionId: _selectedSectionId != null ? int.parse(_selectedSectionId!) : null,
          classId: _selectedClassId != null ? int.parse(_selectedClassId!) : null,
          studentName: _fullNameController.text.trim(),
          admissionNumber: _admissionNumberController.text.trim().isNotEmpty
              ? _admissionNumberController.text.trim()
              : null,
          parentId: _parentIdController.text.trim().isNotEmpty
              ? int.tryParse(_parentIdController.text.trim())
              : null,
        );

        // 2. Wrap up: Link Additional Sections if any (Only if Primary Section was selected to have an ID to link to?)
        // Actually, if _selectedSectionId is null, we might still want to link "Additional" sections if the user accessed them.
        // But UI logic hides "Additional" if Primary is null. So this block only runs if a Primary was selected OR if I change UI logic.
        // Current UI logic: `if (_selectedSectionId != null) ...` shows additional sections.
        // So effectively, you can only add "Additional" sections if you have a "Primary" one.
        // "School Level" creation means NO sections.
        
        if (_selectedSectionId != null && _additionalSectionIds.isNotEmpty) {
           final studentId = newStudentData['id'];
           if (studentId != null) {
             final allSectionIds = {
               int.parse(_selectedSectionId!), 
               ..._additionalSectionIds.map(int.parse)
             }.toList();
             
             await studentService.linkStudentToSections(
               studentId: studentId is String ? int.parse(studentId) : studentId,
               sectionIds: allSectionIds,
             );
           }
        }

        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Student added successfully.');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, message: 'Error adding student: $e');
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Add Student',
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
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassDecoration(
                  context: context,
                  opacity: 0.6,
                  borderRadius: 24,
                  hasGlow: true,
                  borderColor: theme.dividerColor.withValues(alpha: 0.1),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Student Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a student to the school. Sections can be assigned now or later.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Primary Section Dropdown
                      _isLoadingData 
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedSectionId,
                            decoration: InputDecoration(
                              labelText: 'Primary Section (Optional)',
                              helperText: 'Select if known (determines available classes)',
                              prefixIcon: const Icon(Icons.school, color: AppTheme.primaryColor),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _sections.map((section) {
                              return DropdownMenuItem(
                                value: section.id,
                                child: Text(section.sectionName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSectionId = value;
                                // Remove picked primary from additional if present
                                if (value != null) _additionalSectionIds.remove(value);
                              });
                              if (value != null) _loadClasses(value);
                            },
                            validator: null, // Optional
                          ),
                      const SizedBox(height: 16),

                      // Class Dropdown
                      _isLoadingClasses 
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedClassId,
                            decoration: InputDecoration(
                              labelText: 'Class (Optional)',
                              prefixIcon: const Icon(Icons.class_, color: AppTheme.primaryColor),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            disabledHint: const Text('Select a primary section first'),
                            items: _classes.map((classModel) {
                              return DropdownMenuItem(
                                value: classModel.id,
                                child: Text(classModel.name),
                              );
                            }).toList(),
                            onChanged: _selectedSectionId == null ? null : (value) {
                              setState(() => _selectedClassId = value);
                            },
                            validator: null, // Optional
                          ),
                      const SizedBox(height: 24),

                      // Additional Sections (Only show if Primary is selected)
                      if (_selectedSectionId != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Additional Sections',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: _showAdditionalSectionsDialog,
                              icon: const Icon(Icons.add_circle_outline, size: 16),
                              label: const Text('Manage'),
                            ),
                          ],
                        ),
                        if (_additionalSectionIds.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _additionalSectionIds.map((id) {
final section = _sections.firstWhere((s) => s.id == id, orElse: () => SectionModel(id: id, sectionName: 'Unknown', schoolId: '', createdAt: DateTime.now(), lastModified: DateTime.now()));
                              return Chip(
                                label: Text(section.sectionName, style: const TextStyle(fontSize: 12)),
                                backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _additionalSectionIds.remove(id);
                                  });
                                },
                              );
                            }).toList(),
                          )
                        else
                          Text(
                            'No additional sections selected.',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        const SizedBox(height: 16),
                      ],


                      CustomTextField(
                        controller: _fullNameController,
                        labelText: 'Full Name',
                        prefixIcon: Icons.person,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _admissionNumberController,
                        labelText: 'Admission Number (Optional)',
                        prefixIcon: Icons.badge,
                        helperText: 'Unique school identifier (if any)',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _parentIdController,
                        labelText: 'Parent ID (Optional)',
                        prefixIcon: Icons.supervisor_account,
                        keyboardType: TextInputType.number,
                        helperText: 'Link to a parent account using their ID',
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Add Student',
                        isLoading: _isLoading,
                        onPressed: _addStudent,
                        icon: Icons.person_add,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
