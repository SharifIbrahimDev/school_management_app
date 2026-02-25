import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/section_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_snackbar.dart';
import 'edit_section_screen.dart';
import 'assign_principal_screen.dart';
import 'assign_bursar_screen.dart';
import '../../widgets/custom_app_bar.dart';

class SectionDetailScreen extends StatelessWidget {
  final SectionModel section;

  const SectionDetailScreen({super.key, required this.section});

  Future<void> _deleteSection(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text('Are you sure you want to delete ${section.sectionName}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed == true) {
      try {
        final sectionId = int.tryParse(section.id) ?? 0;
        await Provider.of<SectionServiceApi>(context, listen: false).deleteSection(sectionId);
        if (context.mounted) {
          AppSnackbar.showSuccess(context, message: 'Section deleted successfully');
          Navigator.pop(context); // Go back to sections list
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.showError(context, message: 'Failed to delete section: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context);
    final user = authService.currentUser;

    if (user == null || user['role'] != 'proprietor') {
      return const Scaffold(body: Center(child: Text('Access Denied')));
    }

    // Since SectionModel in this project uses specific fields, ensuring they exist
    return Scaffold(
      appBar: CustomAppBar(
        title: section.sectionName,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Section Details', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text('Name: ${section.sectionName}'),
                    const SizedBox(height: 8),
                    Text('About: ${section.aboutSection ?? 'No description'}'),
                    const SizedBox(height: 8),
                    // Based on SectionModel, check if it has these principal/bursar list fields
                    Text('Principals: ${section.assignedPrincipalIds.isNotEmpty ? '${section.assignedPrincipalIds.length} assigned' : 'None'}'),
                    const SizedBox(height: 8),
                    Text('Bursars: ${section.assignedBursarIds.isNotEmpty ? '${section.assignedBursarIds.length} assigned' : 'None'}'),
                    const SizedBox(height: 8),
                    Text('Created: ${section.createdAt.toString().substring(0, 16)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CustomButton(
                  text: 'Edit Section',
                  width: (MediaQuery.of(context).size.width - 40) / 2,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditSectionScreen(section: section)),
                  ),
                ),
                CustomButton(
                  text: 'Assign Principal',
                  width: (MediaQuery.of(context).size.width - 40) / 2,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AssignPrincipalScreen(section: section)),
                  ),
                ),
                CustomButton(
                  text: 'Assign Bursar',
                  width: (MediaQuery.of(context).size.width - 40) / 2,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AssignBursarScreen(section: section)),
                  ),
                ),
                CustomButton(
                  text: 'Delete Section',
                  backgroundColor: Colors.red,
                  width: (MediaQuery.of(context).size.width - 40) / 2,
                  onPressed: () => _deleteSection(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
