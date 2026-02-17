import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/term_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/term_service_api.dart';
import 'edit_term_screen.dart';
import 'term_detail_screen.dart';
import '../../core/utils/app_theme.dart';

class TermListView extends StatelessWidget {
  final TermServiceApi termService;
  final AcademicSessionModel session;
  final String schoolId;
  final String sectionId;
  final String sessionId;
  final String? errorMessage;
  final VoidCallback onRefresh;

  const TermListView({
    super.key,
    required this.termService,
    required this.session,
    required this.schoolId,
    required this.sectionId,
    required this.sessionId,
    required this.errorMessage,
    required this.onRefresh,
  });

  Future<void> _deleteTerm(BuildContext context, TermModel term) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Term'),
        content: Text('Are you sure you want to delete "${term.termName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await termService.deleteTerm(
          int.parse(term.id),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Term deleted successfully')),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting term: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context);
    final isPrincipal = authService.currentUserModel?.role == UserRole.principal;

    return Column(
      children: [
        if (errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: AppTheme.glassDecoration(
              context: context,
              opacity: 0.1,
              borderColor: Colors.red.withValues(alpha: 0.3),
            ),
            child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
          ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: termService.getTerms(
            sectionId: int.tryParse(sectionId),
            sessionId: int.tryParse(sessionId),
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('FutureBuilder error: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    ElevatedButton(
                      onPressed: onRefresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final termsData = snapshot.data ?? [];
            final terms = termsData.map((data) => TermModel.fromMap(data)).toList();
            if (terms.isEmpty) {
              return const Center(child: Text('No terms added yet'));
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: terms.length,
              itemBuilder: (context, index) {
                final term = terms[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: AppTheme.glassDecoration(
                    context: context,
                    opacity: 0.6,
                    borderRadius: 16,
                    hasGlow: term.isActive,
                    borderColor: term.isActive ? Colors.blue.withValues(alpha: 0.3) : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: term.isActive ? Colors.blue : Colors.grey[300],
                      child: const Icon(Icons.event, color: Colors.white),
                    ),
                    title: Text(term.termName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat('MMM dd, yyyy').format(term.startDate)} - ${DateFormat('MMM dd, yyyy').format(term.endDate)}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPrincipal)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditTermScreen(
                                  term: term,
                                  session: session,
                                  schoolId: schoolId,
                                  sectionId: sectionId,
                                  onSuccess: onRefresh,
                                ),
                              ),
                            ),
                          ),
                        if (isPrincipal)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTerm(context, term),
                          ),
                        if (term.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TermDetailScreen(
                          term: term,
                          session: session,
                          schoolId: schoolId,
                          sectionId: sectionId,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
