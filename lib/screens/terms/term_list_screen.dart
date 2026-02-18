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
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../core/utils/error_handler.dart';

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
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Term',
      content: 'Are you sure you want to delete "${term.termName}"? This will affect all class data linked to this term.',
      confirmText: 'Delete Term',
      confirmColor: Colors.red,
      icon: Icons.event_busy_rounded,
    );
    if (confirmed == true) {
      try {
        await termService.deleteTerm(
          int.parse(term.id),
        );
        if (context.mounted) {
          AppSnackbar.showSuccess(context, message: 'Term deleted successfully');
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.friendlyError(context, error: e);
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
              return ErrorDisplayWidget(
                error: snapshot.error.toString(),
                onRetry: onRefresh,
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingIndicator(message: 'Fetching terms...'));
            }
            final termsData = snapshot.data ?? [];
            final terms = termsData.map((data) => TermModel.fromMap(data)).toList();
            if (terms.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.event_note_rounded,
                title: 'No Terms Found',
                message: 'No terms have been added to this session yet.',
                actionButtonText: isPrincipal ? 'Add Term' : 'Refresh',
                onActionPressed: isPrincipal 
                    ? () { /* This would need navigation to AddTermScreen if it was easily accessible here */ } 
                    : onRefresh,
              );
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
