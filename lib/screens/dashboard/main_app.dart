import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive_utils.dart'; // Add responsive utils
import '../../widgets/responsive_widgets.dart'; // Add responsive widgets
import '../../widgets/navigation_sidebar.dart'; // Add sidebar
import '../sections/section_list_screen.dart';
import '../users/users_list_screen.dart';
import '../sessions/academic_sessions_screen.dart';
import '../transactions/transaction_report_screen.dart';
import '../reports/reports_dashboard_screen.dart';
import '../class/class_list_screen.dart';
import '../../widgets/offline_banner.dart';
import '../student/student_list_screen.dart';
import 'proprietor_dashboard.dart';
import 'principal_dashboard.dart';
import 'bursar_dashboard.dart';
import 'teacher_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import '../profile/profile_screen.dart';

class MainApp extends StatefulWidget {
  final String userId;
  final String schoolId;
  final dynamic role; // Can be UserRole or String
  final String sectionId;
  final AuthServiceApi authService;

  const MainApp({
    super.key,
    required this.userId,
    required this.schoolId,
    required this.role,
    required this.sectionId,
    required this.authService,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    UserRole userRole = widget.role is UserRole
        ? widget.role
        : UserRole.values.firstWhere(
          (r) => r.toString().split('.').last == widget.role,
      orElse: () => UserRole.proprietor,
    );
    
    final navItems = _getNavigationItems(userRole);
    // Remove unused 'screens' variable
    
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    return ResponsiveScaffold(
      // Only show sidebar on tablet/desktop as defined in ResponsiveScaffold logic
      sidebar: NavigationSidebar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
        userRole: userRole,
        isCollapsed: !isDesktop, // Collapse on tablet
      ),
      sidebarWidth: isDesktop ? 250 : 80, // Expanded on desktop, slim on tablet
      
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _getScreens(userRole)[_selectedIndex]),
        ],
      ),
      
      // Only show bottom nav on mobile
      bottomNavigationBar: context.isMobile ? Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.8,
          borderRadius: 30,
          hasGlow: true,
          borderColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            elevation: 0,
            items: navItems,
          ),
        ),
      ) : null,
      
      extendBody: context.isMobile, // Only extend body for floating nav on mobile
    );
  }

  List<Widget> _getScreens(UserRole role) {
    switch (role) {
      case UserRole.proprietor:
        return [
          ProprietorDashboard(schoolId: widget.schoolId),
          const SectionListScreen(),
          const UsersListScreen(),
          const ReportsDashboardScreen(),
          ProfileScreen(),
        ];
      case UserRole.principal:
        return [
          PrincipalDashboard(schoolId: widget.schoolId),
          const SectionListScreen(),
          StudentListScreen(schoolId: widget.schoolId, sectionId: '', classId: ''),
          AcademicSessionsScreen(),
          ProfileScreen(),
        ];
      case UserRole.bursar:
        return [
          BursarDashboard(schoolId: widget.schoolId),
          const SectionListScreen(),
          const ReportsDashboardScreen(),
          AcademicSessionsScreen(),
          ProfileScreen(),
        ];
      case UserRole.teacher:
        return [
          TeacherDashboardScreen(
            teacherId: widget.userId,
            schoolId: widget.schoolId,
            authService: widget.authService,
          ),
          const SectionListScreen(), // For browsing content
          ProfileScreen(),
        ];
      case UserRole.parent:
        return [
          ParentDashboardScreen(parentId: widget.userId, schoolId: widget.schoolId),
          ProfileScreen(),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavigationItems(UserRole role) {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.grid_view_rounded), 
        activeIcon: Icon(Icons.grid_view_rounded), 
        label: 'Home'
      ),
    ];

    switch (role) {
      case UserRole.proprietor:
        items.addAll([
          const BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Sections'),
          const BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Users'),
          const BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Reports'),
        ]);
        break;
      case UserRole.principal:
        items.addAll([
          const BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Sections'),
          const BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Students'),
          const BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Sessions'),
        ]);
        break;
      case UserRole.bursar:
        items.addAll([
          const BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Sections'),
          const BottomNavigationBarItem(icon: Icon(Icons.payments_rounded), label: 'Fees'),
          const BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Sessions'),
        ]);
        break;
      case UserRole.teacher:
        items.addAll([
          const BottomNavigationBarItem(icon: Icon(Icons.auto_stories_rounded), label: 'Academics'),
        ]);
        break;
      case UserRole.parent:
        // Parents might only have Home + Profile initially
        break;
    }

    // Always append Profile as the last item
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.person_2_rounded), 
      label: 'Profile'
    ));

    return items;
  }
}
