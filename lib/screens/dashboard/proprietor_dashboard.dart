import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/class_model.dart';
import '../../core/models/section_model.dart';
import '../../core/models/term_model.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/session_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/transaction_service_api.dart';
import '../../core/services/dashboard_filter_service.dart';
import '../../core/services/attendance_service_api.dart';
import '../../core/services/fee_service_api.dart'; // Added FeeServiceApi
import '../../core/services/exam_service_api.dart';
import '../../widgets/app_snackbar.dart';
import 'dashboard_content.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display_widget.dart';
import '../../widgets/custom_speed_dial.dart';
import '../users/add_user_screen.dart';
import '../sections/add_section_screen.dart';
import '../class/add_class_screen.dart';
import 'analytics_dashboard_screen.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_drawer.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class ProprietorDashboard extends StatefulWidget {
  final String schoolId;

  const ProprietorDashboard({super.key, required this.schoolId});

  @override
  State<ProprietorDashboard> createState() => _ProprietorDashboardState();
}

class _ProprietorDashboardState extends State<ProprietorDashboard> {
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
    'totalFees': 0.0, // Represents total expected
    'outstandingDebt': 0.0, // Replace cash inputs with actual debt stats
    'balanceRemaining': 0.0,
  };
  
  Map<String, dynamic>? _attendanceSummary;
  Map<String, dynamic>? _academicAnalytics;
  
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
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final sectionsData = await sectionService.getSections(isActive: true);
      
      if (!mounted) return;

      setState(() {
        _sections = sectionsData.map((data) => SectionModel.fromMap(data)).toList();
      });

      if (_sections.isNotEmpty) {
        // Try to load saved filter
        final savedFilters = await DashboardFilterService.getFilters('Proprietor');
        final savedSectionId = savedFilters['sectionId'];
        
        // Verify saved section still exists
        if (savedSectionId != null && _sections.any((s) => s.id == savedSectionId)) {
          _selectedSectionId = savedSectionId;
        } else {
          _selectedSectionId = _sections.first.id;
        }
        
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
        // Try to load saved session
        final savedFilters = await DashboardFilterService.getFilters('Proprietor');
        final savedSessionId = savedFilters['sessionId'];

        AcademicSessionModel? activeSession;
        
        if (savedSessionId != null && _sessions.any((s) => s.id == savedSessionId)) {
           activeSession = _sessions.firstWhere((s) => s.id == savedSessionId);
        } else {
           activeSession = _sessions.firstWhere(
            (s) => s.isActive,
            orElse: () => _sessions.first,
          );
        }

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
      // Continue loading classes even if sessions fail
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
        // Try to load saved term
        final savedFilters = await DashboardFilterService.getFilters('Proprietor');
        final savedTermId = savedFilters['termId'];

        TermModel? activeTerm;

        if (savedTermId != null && _terms.any((t) => t.id == savedTermId)) {
          activeTerm = _terms.firstWhere((t) => t.id == savedTermId);
        } else {
           activeTerm = _terms.firstWhere(
            (t) => t.isActive,
            orElse: () => _terms.first,
          );
        }
        
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
      final feeService = Provider.of<FeeServiceApi>(context, listen: false);

      final statsData = await transactionService.getDashboardStats(
        sectionId: int.tryParse(_selectedSectionId!),
        sessionId: _selectedSessionId != null ? int.tryParse(_selectedSessionId!) : null,
        termId: _selectedTermId != null ? int.tryParse(_selectedTermId!) : null,
      );

      final feesData = await feeService.getFeeSummary(
        sectionId: int.tryParse(_selectedSectionId!),
        sessionId: _selectedSessionId != null ? int.tryParse(_selectedSessionId!) : null,
        termId: _selectedTermId != null ? int.tryParse(_selectedTermId!) : null,
      );
      
      if (!mounted) return;

      setState(() {
        _stats = {
          'totalGenerated': (statsData['total_income'] as num?)?.toDouble() ?? 0.0,
          'totalSpent': (statsData['total_expenses'] as num?)?.toDouble() ?? 0.0,
          'totalFees': (feesData['total_amount'] as num?)?.toDouble() ?? 0.0,
          'outstandingDebt': (feesData['total_balance'] as num?)?.toDouble() ?? 0.0,
          'balanceRemaining': (statsData['balance'] as num?)?.toDouble() ?? 0.0,
        };
        _isLoading = false;
      });

      await _loadProprietorAnalytics(_selectedSectionId!);
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Don't show error message for stats failure, just show empty stats
      });
    }
  }

  Future<void> _loadProprietorAnalytics(String sectionId) async {
    try {
      final attendanceService = Provider.of<AttendanceServiceApi>(context, listen: false);
      final examService = Provider.of<ExamServiceApi>(context, listen: false);

      final attendancePromise = attendanceService.getSectionSummary(
        sectionId: int.parse(sectionId),
        date: DateTime.now(),
      );
      
      final examPromise = examService.getAcademicAnalytics(
        sectionId: int.parse(sectionId),
      );

      final results = await Future.wait<dynamic>([attendancePromise, examPromise]);

      if (!mounted) return;

      setState(() {
        _attendanceSummary = results[0];
        _academicAnalytics = results[1];
      });
    } catch (e) {
      debugPrint('Error loading proprietor analytics: $e');
    }
  }

  Future<void> _refreshDashboard() async {
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator(message: 'Loading your dashboard...')),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorScreen(_errorMessage!);
    }

    if (_sections.isEmpty) {
      return _buildNoSectionsScreen();
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dashboard Overview',
        actions: [
          const NotificationBadge(),
        ],
      ),
      drawer: const CustomDrawer(),
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
                await DashboardFilterService.saveFilters('Proprietor', sectionId: value);
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
                await DashboardFilterService.saveFilters('Proprietor', sessionId: value);
                await _loadTerms(_selectedSectionId!, value);
              }
            },
            onTermChanged: (value) async {
              if (value != null && value != _selectedTermId) {
                setState(() {
                  _selectedTermId = value;
                  _isLoading = true;
                });
                await DashboardFilterService.saveFilters('Proprietor', termId: value);
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
            role: 'Proprietor',
            attendanceSummary: _attendanceSummary,
            academicAnalytics: _academicAnalytics,
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Prevent overlapping with context.isMobile bottom navbar
        child: CustomSpeedDial(
          tooltip: 'Proprietor Actions',
          children: [
            SpeedDialChild(
              child: const Icon(Icons.insights_rounded),
              backgroundColor: AppTheme.neonPurple,
              foregroundColor: Colors.white,
              label: 'View Analytics',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalyticsDashboardScreen(schoolId: widget.schoolId))),
            ),
            SpeedDialChild(
              child: const Icon(Icons.person_add_rounded),
              backgroundColor: AppTheme.neonBlue,
              foregroundColor: Colors.white,
              label: 'Add User',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen())).then((_) => _refreshDashboard()),
            ),
            SpeedDialChild(
              child: const Icon(Icons.grid_view_rounded),
              backgroundColor: AppTheme.neonTeal,
              foregroundColor: Colors.white,
              label: 'Add Section',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSectionScreen())).then((_) => _refreshDashboard()),
            ),
            SpeedDialChild(
              child: const Icon(Icons.class_rounded),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              label: 'Add Class',
              onTap: () {
                if (_selectedSectionId == null) {
                  AppSnackbar.showWarning(context, message: 'Please select a section first.');
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (_) => AddClassScreen(schoolId: widget.schoolId, sectionId: _selectedSectionId!))).then((_) => _loadClasses(_selectedSectionId!));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: SafeArea(
        child: ErrorDisplayWidget(
          error: error,
          onRetry: _refreshDashboard,
          showContactSupport: true,
        ),
      ),
    );
  }

  Widget _buildNoSectionsScreen() {
    return Scaffold(
      body: SafeArea(
        child: EmptyStateWidget(
          icon: Icons.school_outlined,
          title: 'No Sections Found',
          message: 'You need to create at least one section to see your dashboard data.',
          actionButtonText: 'Create Section',
          onActionPressed: () => Navigator.pushNamed(context, '/add-section'),
        ),
      ),
    );
  }
}
