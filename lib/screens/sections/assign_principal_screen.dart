import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/section_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/user_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';

class AssignPrincipalScreen extends StatefulWidget {
  final SectionModel section;

  const AssignPrincipalScreen({super.key, required this.section});

  @override
  State<AssignPrincipalScreen> createState() => _AssignPrincipalScreenState();
}

class _AssignPrincipalScreenState extends State<AssignPrincipalScreen> {
  bool _isLoading = false;
  bool _isFetching = true;
  List<UserModel> _principals = [];

  @override
  void initState() {
    super.initState();
    _loadPrincipals();
  }

  Future<void> _loadPrincipals() async {
    setState(() => _isFetching = true);
    try {
      final userService = Provider.of<UserServiceApi>(context, listen: false);
      final usersData = await userService.getUsers();
      _principals = usersData
          .map((u) => UserModel.fromMap(u))
          .where((u) => u.role == UserRole.principal)
          .toList();
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Error loading principals: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _handleAssignment(UserModel principal, bool isAssigned) async {
    setState(() => _isLoading = true);
    try {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final currentIds = widget.section.assignedPrincipalIds.map((id) => int.tryParse(id) ?? 0).where((id) => id != 0).toList();
      final principalId = int.tryParse(principal.id) ?? 0;

      if (isAssigned) {
        currentIds.remove(principalId);
      } else {
        currentIds.add(principalId);
      }

      await sectionService.updateSection(
        int.parse(widget.section.id),
        assignedPrincipalIds: currentIds,
      );
      
      if (mounted) {
        AppSnackbar.showSuccess(context, message: isAssigned ? 'Principal unassigned' : 'Principal assigned');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Error updating assignment: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Assign Principal',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              AppTheme.accentColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            _isFetching
                ? const Center(child: LoadingIndicator(message: 'Loading principals...'))
                : _principals.isEmpty
                    ? const Center(child: Text('No principals found'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _principals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final principal = _principals[index];
                          final isAssigned = widget.section.assignedPrincipalIds.contains(principal.id);

                          return Container(
                            decoration: AppTheme.glassDecoration(
                              context: context,
                              opacity: 0.6,
                              borderRadius: 16,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Icon(Icons.person, color: theme.colorScheme.primary),
                              ),
                              title: Text(principal.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(principal.email),
                              trailing: ElevatedButton(
                                onPressed: _isLoading ? null : () => _handleAssignment(principal, isAssigned),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isAssigned ? theme.colorScheme.error : theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(isAssigned ? 'Unassign' : 'Assign'),
                              ),
                            ),
                          );
                        },
                      ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(child: LoadingIndicator(message: 'Updating assignment...')),
              ),
          ],
        ),
      ),
    );
  }
}
