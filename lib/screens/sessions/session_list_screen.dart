import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/section_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/session_service_api.dart';
import '../../core/services/auth_service_api.dart';
import 'add_session_screen.dart';
import 'edit_session_screen.dart';
import 'session_detail_screen.dart';
import '../../widgets/loading_indicator.dart';

class SessionListView extends StatefulWidget {
  final List<SectionModel> assignedSections;
  final String? selectedSectionId;
  final String? errorMessage;
  final ValueChanged<String?> onSectionChanged;

  const SessionListView({
    super.key,
    required this.assignedSections,
    required this.selectedSectionId,
    required this.errorMessage,
    required this.onSectionChanged,
  });

  @override
  State<SessionListView> createState() => _SessionListViewState();
}

class _SessionListViewState extends State<SessionListView> {
  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void didUpdateWidget(SessionListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSectionId != widget.selectedSectionId) {
      _loadSessions();
    }
  }

  void _loadSessions() {
    if (widget.selectedSectionId != null) {
      final sessionService = Provider.of<SessionServiceApi>(context, listen: false);
      setState(() {
        _sessionsFuture = sessionService.getSessions(
          sectionId: int.tryParse(widget.selectedSectionId!),
        );
      });
    } else {
      _sessionsFuture = Future.value([]);
    }
  }

  Future<void> _deleteSession(BuildContext context, AcademicSessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete "${session.sessionName}"?'),
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
        final sessionService = Provider.of<SessionServiceApi>(context, listen: false);
        final authService = Provider.of<AuthServiceApi>(context, listen: false);
        
        await sessionService.deleteAcademicSession(
          schoolId: authService.currentUserModel?.schoolId.toString() ?? '',
          sectionId: session.sectionId,
          sessionId: session.id,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted successfully')),
        );
        _loadSessions();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting session: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context, listen: false);

    if (widget.assignedSections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: Color(0xFF757575)),
            const SizedBox(height: 16),
            const Text(
              'No sections assigned',
              style: TextStyle(fontSize: 18, color: Color(0xFF757575), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('Please contact the school administrator', style: TextStyle(color: Color(0xFF757575))),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => widget.onSectionChanged(null), 
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButton<String>(
                value: widget.selectedSectionId,
                isExpanded: true,
                hint: const Text('Select a Section'),
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
                items: widget.assignedSections
                    .map((section) => DropdownMenuItem(
                  value: section.id,
                  child: Text(section.sectionName),
                ))
                    .toList(),
                onChanged: widget.onSectionChanged,
              ),
            ),
          ),
        ),
        if (widget.errorMessage != null)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(widget.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
            ),
          ),
        Expanded(
          child: widget.selectedSectionId == null
              ? const Center(child: Text('Select a section to view sessions'))
              : FutureBuilder<List<Map<String, dynamic>>>(
            future: _sessionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LoadingIndicator(size: 40));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => _loadSessions(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final sessionsData = snapshot.data ?? [];
              final sessions = sessionsData.map((data) => AcademicSessionModel.fromMap(data)).toList();

              if (sessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 64, color: Color(0xFF757575)),
                      const SizedBox(height: 16),
                      const Text(
                        'No academic sessions found',
                        style: TextStyle(fontSize: 18, color: Color(0xFF757575), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text('Create a new session to get started', style: TextStyle(color: Color(0xFF757575))),
                      if (authService.currentUserModel?.role == UserRole.principal)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: FilledButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddSessionScreen(
                                    selectedSectionId: widget.selectedSectionId!,
                                    onSuccess: () => widget.onSectionChanged(widget.selectedSectionId),
                                    schoolId: authService.currentUserModel!.schoolId!.toString(),
                                  ),
                                ),
                              );
                            },
                            child: const Text('Create Session'),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final isPrincipal = authService.currentUserModel?.role == UserRole.principal;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: session.isActive ? Colors.green : Colors.grey,
                        child: const Icon(Icons.calendar_today, color: Colors.white),
                      ),
                      title: Text(
                        session.sessionName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'From: ${DateFormat('dd/MM/yyyy').format(session.startDate)}\n'
                            'To: ${DateFormat('dd/MM/yyyy').format(session.endDate)}',
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
                                  builder: (context) => EditSessionScreen(
                                    session: session,
                                    onSuccess: () => widget.onSectionChanged(widget.selectedSectionId),
                                  ),
                                ),
                              ),
                            ),
                          if (isPrincipal)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSession(context, session),
                            ),
                          if (session.isActive)
                            const Chip(
                              label: Text('Active'),
                              backgroundColor: Colors.green,
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SessionDetailScreen(
                              session: session,
                              schoolId: authService.currentUserModel?.schoolId.toString() ?? '',
                              sectionId: widget.selectedSectionId!,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
