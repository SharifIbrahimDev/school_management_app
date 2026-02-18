import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/class_model.dart';
import '../../core/models/section_model.dart';
import '../../core/models/term_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/session_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/transaction_service_api.dart';
import 'dashboard_content.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display_widget.dart';
import '../../widgets/empty_state_widget.dart';

class BursarDashboard extends StatefulWidget {
  final String schoolId;

  const BursarDashboard({super.key, required this.schoolId});

  @override
  State<BursarDashboard> createState() => _BursarDashboardState();
}

class _BursarDashboardState extends State<BursarDashboard> {
  String? _selectedSectionId;
  String? _selectedSessionId;
  String? _selectedTermId;
  String? _selectedClassId;
  String? _selectedStudentId;
  
  List<SectionModel> _sections = [];
  List<AcademicSessionModel> _sessions = [];
  List<TermModel> _terms = [];
  List<ClassModel> _classes = [];
  Map<String, double> _stats = {
    'totalGenerated': 0.0,
    'totalSpent': 0.0,
    'cashInHand': 0.0,
    'cashInAccount': 0.0,
    'balanceRemaining': 0.0,
  };
  
  bool _isLoading = true;
  String? _errorMessage;

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
      final user = userMap != null ? UserModel.fromMap(userMap) : null;
      
      // Get sections assigned to bursar
      final assignedSections = user?.assignedSections ?? [];
      
      if (assignedSections.isEmpty) {
        // If no assigned sections, get all sections
        final sectionsData = await sectionService.getSections(isActive: true);
        _sections = sectionsData.map((data) => SectionModel.fromMap(data)).toList();
      } else {
        // Get only assigned sections
        final sectionsData = await sectionService.getSections(isActive: true);
        _sections = sectionsData
            .map((data) => SectionModel.fromMap(data))
            .where((s) => assignedSections.contains(s.id))
            .toList();
      }

      if (!mounted) return;

      if (_sections.isNotEmpty) {
        _selectedSectionId = _sections.first.id;
        await _loadSessions(_selectedSectionId!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading sections: $e';
      });
    }
  }

  Future<void> _loadSessions(String sectionId) async {
    try {
      final sessionService = Provider.of<SessionServiceApi>(context, listen: false);
      final sessionsData = await sessionService.getSessions(sectionId: int.tryParse(sectionId));
      
      if (!mounted) return;

      setState(() {
        _sessions = sessionsData.map((data) => AcademicSessionModel.fromMap(data)).toList();
      });

      if (_sessions.isNotEmpty) {
        final activeSession = _sessions.firstWhere(
          (s) => s.isActive,
          orElse: () => _sessions.first,
        );
        _selectedSessionId = activeSession.id;
        await _loadTerms(sectionId, _selectedSessionId!);
      } else {
        _selectedSessionId = null;
        _terms = [];
        _selectedTermId = null;
        await _loadClasses(sectionId);
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      await _loadClasses(sectionId);
    }
  }

  Future<void> _loadTerms(String sectionId, String sessionId) async {
    try {
      final termService = Provider.of<TermServiceApi>(context, listen: false);
      final termsData = await termService.getTerms(
        sectionId: int.tryParse(sectionId),
        sessionId: int.tryParse(sessionId),
      );
      
      if (!mounted) return;

      setState(() {
        _terms = termsData.map((data) => TermModel.fromMap(data)).toList();
      });

      if (_terms.isNotEmpty) {
        final activeTerm = _terms.firstWhere(
          (t) => t.isActive,
          orElse: () => _terms.first,
        );
        _selectedTermId = activeTerm.id;
      } else {
        _selectedTermId = null;
      }
      
      await _loadClasses(sectionId);
    } catch (e) {
      debugPrint('Error loading terms: $e');
      await _loadClasses(sectionId);
    }
  }

  Future<void> _loadClasses(String sectionId) async {
    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classesData = await classService.getClasses(sectionId: int.tryParse(sectionId));
      
      if (!mounted) return;

      setState(() {
        _classes = classesData.map((data) => ClassModel.fromMap(data)).toList();
      });
      
      await _loadStats();
    } catch (e) {
      debugPrint('Error loading classes: $e');
      await _loadStats();
    }
  }

  Future<void> _loadStats() async {
    if (_selectedSectionId == null) return;

    try {
      final transactionService = Provider.of<TransactionServiceApi>(context, listen: false);
      final statsData = await transactionService.getDashboardStats(
        sectionId: int.tryParse(_selectedSectionId!),
        sessionId: _selectedSessionId != null ? int.tryParse(_selectedSessionId!) : null,
        termId: _selectedTermId != null ? int.tryParse(_selectedTermId!) : null,
      );
      
      if (!mounted) return;

      setState(() {
        _stats = {
          'totalGenerated': (statsData['total_income'] as num?)?.toDouble() ?? 0.0,
          'totalSpent': (statsData['total_expenses'] as num?)?.toDouble() ?? 0.0,
          'cashInHand': 0.0,
          'cashInAccount': 0.0,
          'balanceRemaining': (statsData['balance'] as num?)?.toDouble() ?? 0.0,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshDashboard() async {
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator(message: 'Loading financial dashboard...')),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorScreen(_errorMessage!, _refreshDashboard);
    }

    if (_sections.isEmpty) {
      return _buildNoSectionsScreen();
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Dashboard Overview',
      ),
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
          child: DashboardContent(
            sections: _sections,
            sessions: _sessions,
            classes: _classes,
            terms: _terms,
            selectedSectionId: _selectedSectionId,
            selectedSessionId: _selectedSessionId,
            selectedTermId: _selectedTermId,
            selectedClassId: _selectedClassId,
            selectedStudentId: _selectedStudentId,
            dashboardStats: _stats,
            isLoading: _isLoading,
            errorMessage: null,
            onSectionChanged: (value) async {
              if (value != null && value != _selectedSectionId) {
                setState(() {
                  _selectedSectionId = value;
                  _selectedSessionId = null;
                  _selectedTermId = null;
                  _selectedClassId = null;
                  _selectedStudentId = null;
                  _isLoading = true;
                });
                await _loadSessions(value);
              }
            },
            onSessionChanged: (value) async {
              if (value != null && value != _selectedSessionId) {
                setState(() {
                  _selectedSessionId = value;
                  _selectedTermId = null;
                  _isLoading = true;
                });
                await _loadTerms(_selectedSectionId!, value);
              }
            },
            onTermChanged: (value) async {
              if (value != null && value != _selectedTermId) {
                setState(() {
                  _selectedTermId = value;
                  _isLoading = true;
                });
                await _loadStats();
              }
            },
            onClassChanged: (value) {
              setState(() {
                _selectedClassId = value;
                _selectedStudentId = null;
              });
            },
            onStudentChanged: (value) {
              setState(() => _selectedStudentId = value);
            },
            onRefresh: _refreshDashboard,
            role: 'Bursar',
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error, VoidCallback onRetry) {
    return Scaffold(
      body: SafeArea(
        child: ErrorDisplayWidget(
          error: error,
          onRetry: onRetry,
          showContactSupport: true,
        ),
      ),
    );
  }

  Widget _buildNoSectionsScreen() {
    return Scaffold(
      body: SafeArea(
        child: EmptyStateWidget(
          icon: Icons.account_balance_rounded,
          title: 'No Sections Assigned',
          message: 'It looks like you haven\'t been assigned to any sections yet. Please contact your proprietor to get started.',
          actionButtonText: 'Refresh Dashboard',
          onActionPressed: _refreshDashboard,
        ),
      ),
    );
  }
}
