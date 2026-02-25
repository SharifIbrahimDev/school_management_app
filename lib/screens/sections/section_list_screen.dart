import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/section_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_display_widget.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/confirmation_dialog.dart';
import 'add_section_screen.dart';
import 'section_detail_screen.dart';
import '../../widgets/custom_app_bar.dart';

class SectionListScreen extends StatefulWidget {
  const SectionListScreen({super.key});

  @override
  State<SectionListScreen> createState() => _SectionListScreenState();
}

class _SectionListScreenState extends State<SectionListScreen> {
  List<SectionModel> _sections = [];
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthServiceApi>(context, listen: false);
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);

      final userMap = authService.currentUser;
      if (userMap == null) throw Exception('User not logged in');
      _currentUser = UserModel.fromMap(userMap);

      final sectionsData = await sectionService.getSections(isActive: true);
      final allSections = sectionsData.map((data) => SectionModel.fromMap(data)).toList();

      if (_currentUser!.role == UserRole.proprietor) {
        _sections = allSections;
      } else {
        _sections = allSections.where((s) => _currentUser!.assignedSections.contains(s.id)).toList();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading sections: $e';
        });
      }
    }
  }

  Future<void> _deleteSection(SectionModel section) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Section',
      content: 'Are you sure you want to delete "${section.sectionName}"? This cannot be undone.',
      confirmText: 'Delete',
      confirmColor: Colors.red,
      icon: Icons.delete_forever_rounded,
    );
    if (!mounted) return;
    if (confirmed == true) {
      try {
        final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
        await sectionService.deleteSection(int.tryParse(section.id) ?? 0);
        
        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Section deleted successfully');
          _loadSections();
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, message: 'Error deleting section: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProprietor = _currentUser?.role == UserRole.proprietor;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Sections',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSections,
          ),
        ],
      ),
      floatingActionButton: isProprietor
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddSectionScreen(),
                    ),
                  ).then((_) => _loadSections());
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Section'),
                backgroundColor: AppTheme.primaryColor,
              ),
            )
          : null,
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
          child: _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (context, index) => const CardSkeletonLoader(),
                )
              : _errorMessage != null
                  ? ErrorDisplayWidget(
                      error: _errorMessage!,
                      onRetry: _loadSections,
                      showContactSupport: true,
                    )
                  : _sections.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.class_,
                          title: 'No Sections Yet',
                          message: isProprietor
                              ? 'Create your first section to organize your school'
                              : 'No sections have been assigned to you yet',
                          actionButtonText: isProprietor ? 'Create Section' : null,
                          onActionPressed: isProprietor
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddSectionScreen(),
                                    ),
                                  ).then((_) => _loadSections());
                                }
                              : null,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _sections.length,
                          itemBuilder: (context, index) {
                            final section = _sections[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: AppTheme.glassDecoration(
                                context: context,
                                opacity: 0.4,
                                hasGlow: true,
                                borderRadius: 16,
                                borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.class_, color: AppTheme.primaryColor, size: 24),
                                ),
                                title: Text(
                                  section.sectionName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    section.aboutSection ?? "No description",
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                                trailing: isProprietor
                                    ? IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteSection(section),
                                      )
                                    : Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryColor),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SectionDetailScreen(section: section),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
