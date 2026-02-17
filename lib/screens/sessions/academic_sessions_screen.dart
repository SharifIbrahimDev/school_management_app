import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/section_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/session_service_api.dart';
import '../../widgets/app_snackbar.dart';
import 'add_session_screen.dart';
import 'edit_session_screen.dart';
import 'session_detail_screen.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_app_bar.dart';

class AcademicSessionsScreen extends StatefulWidget {
  final Function(String?, String?)? onSelectionChanged;

  const AcademicSessionsScreen({super.key, this.onSelectionChanged});

  @override
  State<AcademicSessionsScreen> createState() => _AcademicSessionsScreenState();
}

class _AcademicSessionsScreenState extends State<AcademicSessionsScreen> {
  List<SectionModel> _assignedSections = [];
  String? _selectedSectionId;
  List<AcademicSessionModel> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _currentUser;

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
      if (userMap == null) throw Exception('User not logged in');
      _currentUser = UserModel.fromMap(userMap);

      // Load sections
      final sectionsData = await sectionService.getSections(isActive: true);
      final allSections = sectionsData.map((data) => SectionModel.fromMap(data)).toList();

      if (_currentUser!.role == UserRole.proprietor) {
        _assignedSections = allSections;
      } else {
        _assignedSections = allSections.where((s) => _currentUser!.assignedSections.contains(s.id)).toList();
      }

      if (_assignedSections.isNotEmpty) {
        _selectedSectionId = _assignedSections.first.id;
        await _loadSessions();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading data: $e';
        });
      }
    }
  }

  Future<void> _loadSessions() async {
    if (_selectedSectionId == null) return;

    setState(() => _isLoading = true);

    try {
      final sessionService = Provider.of<SessionServiceApi>(context, listen: false);
      final sessionsData = await sessionService.getSessions(sectionId: int.tryParse(_selectedSectionId!));
      
      if (mounted) {
        setState(() {
          _sessions = sessionsData.map((data) => AcademicSessionModel.fromMap(data)).toList();
          _isLoading = false;
        });
        widget.onSelectionChanged?.call(_selectedSectionId, null);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading sessions: $e';
        });
      }
    }
  }

  Future<void> _deleteSession(AcademicSessionModel session) async {
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
        await sessionService.deleteSession(int.tryParse(session.id) ?? 0);
        
        if (mounted) {
          AppSnackbar.showSuccess(context, message: 'Session deleted successfully');
          _loadSessions();
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, message: 'Error deleting session: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrincipal = _currentUser?.role == UserRole.principal;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Academic Sessions',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      floatingActionButton: _selectedSectionId != null && isPrincipal
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSessionScreen(
                      selectedSectionId: _selectedSectionId!,
                      onSuccess: _loadSessions,
                      schoolId: _currentUser?.schoolId ?? '',
                    ),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              tooltip: 'Add Session',
              child: const Icon(Icons.add, color: Colors.white),
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
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (_assignedSections.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: AppTheme.glassDecoration(
                            context: context,
                            opacity: 0.6,
                            borderRadius: 16,
                            borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: DropdownButton<String>(
                            value: _selectedSectionId,
                            isExpanded: true,
                            hint: const Text('Select a Section'),
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                            dropdownColor: Theme.of(context).cardColor,
                            items: _assignedSections
                                .map((section) => DropdownMenuItem(
                                      value: section.id,
                                      child: Text(section.sectionName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSectionId = value;
                              });
                              _loadSessions();
                            },
                          ),
                        ),
                      ),
                    
                    if (_assignedSections.isEmpty)
                      Expanded(
                        child: EmptyStateWidget(
                          icon: Icons.school_outlined,
                          title: 'No Sections Assigned',
                          message: 'You need to be assigned to a section to manage academic sessions.',
                          actionButtonText: 'Refresh',
                          onActionPressed: _loadInitialData,
                        ),
                      )
                    else if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
    
                    Expanded(
                      child: _sessions.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.calendar_today_outlined,
                              title: 'No Sessions Found',
                              message: 'Start by creating your first academic session for this section.',
                              actionButtonText: isPrincipal ? 'Add Session' : null,
                              onActionPressed: isPrincipal 
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddSessionScreen(
                                            selectedSectionId: _selectedSectionId!,
                                            onSuccess: _loadSessions,
                                            schoolId: _currentUser?.schoolId ?? '',
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _sessions.length,
                              itemBuilder: (context, index) {
                                final session = _sessions[index];
                                return Container(
                                  decoration: AppTheme.glassDecoration(
                                    context: context,
                                    opacity: 0.6,
                                    borderRadius: 16,
                                    hasGlow: session.isActive,
                                    borderColor: session.isActive ? AppTheme.primaryColor.withValues(alpha: 0.5) : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: session.isActive ? AppTheme.primaryColor : Colors.grey[300],
                                      child: const Icon(Icons.calendar_today, color: Colors.white),
                                    ),
                                    title: Text(
                                      session.sessionName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${DateFormat('MMM dd, yyyy').format(session.startDate)} - ${DateFormat('MMM dd, yyyy').format(session.endDate)}',
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
                                                builder: (context) => EditSessionScreen(
                                                  session: session,
                                                  onSuccess: _loadSessions,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (isPrincipal)
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteSession(session),
                                          ),
                                        if (session.isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.green),
                                            ),
                                            child: const Text(
                                              'Active',
                                              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SessionDetailScreen(
                                            session: session,
                                            schoolId: _currentUser?.schoolId ?? '',
                                            sectionId: _selectedSectionId!,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
