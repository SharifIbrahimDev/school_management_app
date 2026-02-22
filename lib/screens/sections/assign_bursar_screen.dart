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

class AssignBursarScreen extends StatefulWidget {
  final SectionModel section;

  const AssignBursarScreen({super.key, required this.section});

  @override
  State<AssignBursarScreen> createState() => _AssignBursarScreenState();
}

class _AssignBursarScreenState extends State<AssignBursarScreen> {
  bool _isLoading = false;
  bool _isFetching = true;
  List<UserModel> _bursars = [];

  @override
  void initState() {
    super.initState();
    _loadBursars();
  }

  Future<void> _loadBursars() async {
    setState(() => _isFetching = true);
    try {
      final userService = Provider.of<UserServiceApi>(context, listen: false);
      final usersData = await userService.getUsers();
      _bursars = usersData
          .map((u) => UserModel.fromMap(u))
          .where((u) => u.role == UserRole.bursar)
          .toList();
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Error loading bursars: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _handleAssignment(UserModel bursar, bool isAssigned) async {
    setState(() => _isLoading = true);
    try {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final currentIds = widget.section.assignedBursarIds.map((id) => int.tryParse(id) ?? 0).where((id) => id != 0).toList();
      final bursarId = int.tryParse(bursar.id) ?? 0;

      if (isAssigned) {
        currentIds.remove(bursarId);
      } else {
        currentIds.add(bursarId);
      }

      await sectionService.updateSection(
        int.parse(widget.section.id),
        assignedBursarIds: currentIds,
      );
      
      if (mounted) {
        AppSnackbar.showSuccess(context, message: isAssigned ? 'Bursar unassigned' : 'Bursar assigned');
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
        title: 'Assign Bursar',
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
                ? const Center(child: LoadingIndicator(message: 'Loading bursars...'))
                : _bursars.isEmpty
                    ? const Center(child: Text('No bursars found'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bursars.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final bursar = _bursars[index];
                          final isAssigned = widget.section.assignedBursarIds.contains(bursar.id);

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
                              title: Text(bursar.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(bursar.email),
                              trailing: ElevatedButton(
                                onPressed: _isLoading ? null : () => _handleAssignment(bursar, isAssigned),
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
