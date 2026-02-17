import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/student_model.dart';
import '../../core/models/section_model.dart';
import '../../core/services/student_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';

import '../../widgets/custom_app_bar.dart';

class StudentSectionLinkingScreen extends StatefulWidget {
  final StudentModel student;

  const StudentSectionLinkingScreen({super.key, required this.student});

  @override
  State<StudentSectionLinkingScreen> createState() => _StudentSectionLinkingScreenState();
}

class _StudentSectionLinkingScreenState extends State<StudentSectionLinkingScreen> {
  List<SectionModel> _availableSections = [];
  Set<String> _selectedSectionIds = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSectionIds = Set.from(widget.student.sectionIds);
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() => _isLoading = true);
    try {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final sectionsData = await sectionService.getSections(isActive: true);
      
      if (mounted) {
        setState(() {
          _availableSections = sectionsData.map((data) => SectionModel.fromMap(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.showError(context, message: 'Error loading sections: $e');
      }
    }
  }

  Future<void> _saveSectionLinks() async {
    setState(() => _isSaving = true);
    try {
      final studentService = Provider.of<StudentServiceApi>(context, listen: false);
      final sectionIds = _selectedSectionIds.map((id) => int.tryParse(id) ?? 0).toList();
      
      await studentService.linkStudentToSections(
        studentId: int.tryParse(widget.student.id) ?? 0,
        sectionIds: sectionIds,
      );

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Section links updated successfully');
        Navigator.pop(context, true); // Return true to indicate changes were made
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackbar.showError(context, message: 'Error updating sections: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Manage Sections',
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.8),
              theme.primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: AppTheme.glassDecoration(
                                context: context,
                                opacity: 0.05,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
                                    child: Icon(Icons.person, color: AppTheme.neonPurple),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.student.fullName,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (widget.student.admissionNumber != null)
                                          Text(
                                            'Admission: ${widget.student.admissionNumber}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.white60,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'SELECT SECTIONS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: theme.primaryColor.withValues(alpha: 0.7),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_availableSections.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: AppTheme.glassDecoration(
                                  context: context,
                                  opacity: 0.03,
                                ),
                                child: Center(
                                  child: Text(
                                    'No sections available',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              )
                            else
                              ..._availableSections.map((section) {
                                final isSelected = _selectedSectionIds.contains(section.id);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: AppTheme.glassDecoration(
                                    context: context,
                                    opacity: isSelected ? 0.1 : 0.03,
                                    borderColor: isSelected
                                        ? AppTheme.neonTeal.withValues(alpha: 0.5)
                                        : Colors.transparent,
                                    hasGlow: isSelected,
                                  ),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedSectionIds.add(section.id);
                                        } else {
                                          _selectedSectionIds.remove(section.id);
                                        }
                                      });
                                    },
                                    title: Text(
                                      section.sectionName,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? AppTheme.neonTeal : Colors.white,
                                      ),
                                    ),
                                    subtitle: section.aboutSection != null
                                        ? Text(
                                            section.aboutSection!,
                                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                                          )
                                        : null,
                                    secondary: Icon(
                                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                                      color: isSelected ? AppTheme.neonTeal : Colors.white54,
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedSectionIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          '${_selectedSectionIds.length} section(s) selected',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neonTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    CustomButton(
                      text: 'Save Section Links',
                      onPressed: _saveSectionLinks,
                      isLoading: _isSaving,
                      icon: Icons.save,
                      backgroundColor: theme.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
