import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/models/section_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/session_service_api.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/user_service_api.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/custom_button.dart';
import 'edit_section_screen.dart';
import 'assign_principal_screen.dart';
import 'assign_bursar_screen.dart';
import '../../widgets/custom_app_bar.dart';

class SectionDetailScreen extends StatefulWidget {
  final SectionModel section;

  const SectionDetailScreen({super.key, required this.section});

  @override
  _SectionDetailScreenState createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends State<SectionDetailScreen> {
  String? _selectedSessionId;
  String? _selectedTermId;

  Future<Map<String, String>> _fetchUserNames(List<String> userIds, UserServiceApi userService) async {
    final names = <String, String>{};
    
    for (final userIdStr in userIds) {
       final userId = int.tryParse(userIdStr);
       if (userId != null) {
         try {
           final user = await userService.getUser(userId);
           if (user != null) {
             names[userIdStr] = user['full_name'] ?? 'Unknown';
           }
         } catch (e) {
           debugPrint('Error fetching user $userId: $e');
           names[userIdStr] = 'Unknown ($userIdStr)';
         }
       }
    }
    return names;
  }

  Future<List<String>> _fetchSessionNames(
      String schoolId,
      String sectionId,
      List<String> sessionIds,
      SessionServiceApi sessionService,
      ) async {
    final names = <String>[];
    try {
      final sessionsData = await sessionService.getSessions(sectionId: int.tryParse(sectionId));
      final sessions = sessionsData; 
      
      for (final sessionIdStr in sessionIds) {
        final session = sessions.firstWhere(
            (s) => s['id'].toString() == sessionIdStr, 
            orElse: () => <String, dynamic>{}
        );
        if (session.isNotEmpty) {
          names.add(session['session_name'] ?? 'Unknown');
        } else {
          names.add('Unknown ($sessionIdStr)');
        }
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      for (final id in sessionIds) {
        names.add('Unknown ($id)');
      }
    }
    return names;
  }

  Future<void> _deleteSection(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Section',
        content: 'Are you sure you want to delete ${widget.section.sectionName}? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
      ),
    );

    if (confirmed == true && mounted) {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      try {
        await sectionService.deleteSection(int.tryParse(widget.section.id) ?? 0);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Section deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Placeholder for de-assigning principal/bursar as API might not support it yet
  Future<void> _deAssignPrincipal(BuildContext context, String userId, String userName) async {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('De-assign feature coming soon'), backgroundColor: Colors.orange),
        );
      }
  }

  Future<void> _deAssignBursar(BuildContext context, String userId, String userName) async {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('De-assign feature coming soon'), backgroundColor: Colors.orange),
        );
      }
  }

  Future<void> _deleteFee(BuildContext context, String feeId, String feeType) async {
      // Placeholder for delete fee
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete fee feature coming soon'), backgroundColor: Colors.orange),
        );
      }
  }

  Future<Map<String, String>> _fetchAllUserNames(UserServiceApi userService) async {
    final allUserIds = [...widget.section.assignedPrincipalIds, ...widget.section.assignedBursarIds];
    return _fetchUserNames(allUserIds, userService);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceApi>(context);
    final sessionService = Provider.of<SessionServiceApi>(context);
    final userService = Provider.of<UserServiceApi>(context);
    
    final userMap = authService.currentUser;
    final user = userMap != null ? UserModel.fromMap(userMap) : null;
    final isProprietor = user?.role == UserRole.proprietor;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not authenticated')));
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.section.sectionName,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                _selectedSessionId = null;
                _selectedTermId = null;
              });
            },
          ),
        ],
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
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _selectedSessionId = null;
              _selectedTermId = null;
            });
          },
          color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Information Card
              Container(
                decoration: AppTheme.glassDecoration(
                  context: context,
                  opacity: 0.6,
                  borderRadius: 16,
                  hasGlow: true,
                  borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.school,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Section Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildModernDetailItem(
                      context,
                      icon: Icons.badge,
                      title: 'Section Name',
                      value: widget.section.sectionName,
                    ),
                    _buildModernDetailItem(
                      context,
                      icon: Icons.description,
                      title: 'About Section',
                      value: widget.section.aboutSection ?? 'No description provided',
                    ),
                    _buildModernDetailItem(
                      context,
                      icon: Icons.calendar_today,
                      title: 'Created',
                      value: widget.section.createdAt.toString().substring(0, 16),
                    ),
                    _buildModernDetailItem(
                      context,
                      icon: Icons.update,
                      title: 'Last Modified',
                      value: widget.section.lastModified.toString().substring(0, 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Staff Assignment Card
              Container(
                decoration: AppTheme.glassDecoration(
                  context: context,
                  opacity: 0.6,
                  borderRadius: 16,
                  hasGlow: true,
                  borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                padding: const EdgeInsets.all(20),
                child: FutureBuilder<Map<String, String>>(
                  future: _fetchAllUserNames(userService),
                  builder: (context, snapshot) {
                    final userNames = snapshot.data ?? {};
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.people, color: Colors.blue, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Staff Assignments',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildModernDetailItem(
                          context,
                          icon: Icons.person,
                          title: 'Principals',
                          value: snapshot.connectionState == ConnectionState.waiting
                              ? 'Loading...'
                              : snapshot.hasError
                              ? 'Error loading names'
                              : (userNames.isNotEmpty && widget.section.assignedPrincipalIds.isNotEmpty)
                              ? widget.section.assignedPrincipalIds
                              .map((id) => userNames[id] ?? 'Unknown')
                              .join(', ')
                              : 'No principals assigned',
                          isImportant: true,
                        ),
                        _buildModernDetailItem(
                          context,
                          icon: Icons.account_balance_wallet,
                          title: 'Bursars',
                          value: snapshot.connectionState == ConnectionState.waiting
                              ? 'Loading...'
                              : snapshot.hasError
                              ? 'Error loading names'
                              : (userNames.isNotEmpty && widget.section.assignedBursarIds.isNotEmpty)
                              ? widget.section.assignedBursarIds
                              .map((id) => userNames[id] ?? 'Unknown')
                              .join(', ')
                              : 'No bursars assigned',
                          isImportant: true,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Academic Sessions Card
              Container(
                decoration: AppTheme.glassDecoration(
                  context: context,
                  opacity: 0.6,
                  borderRadius: 16,
                  hasGlow: true,
                  borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_month, color: Colors.purple, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Academic Sessions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<String>>(
                      future: _fetchSessionNames(
                        widget.section.schoolId,
                        widget.section.id,
                        widget.section.academicSessionIds,
                        sessionService,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Text('Error loading sessions');
                        } else {
                          final sessionNames = snapshot.data ?? [];
                          if (sessionNames.isEmpty) {
                            return const Text('No academic sessions assigned.');
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: sessionNames
                                .asMap()
                                .entries
                                .map(
                                  (entry) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '• ${entry.value}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            )
                                .toList(),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              if (isProprietor) ...[
                const SizedBox(height: 24),
                // Buttons placeholder
                CustomButton(
                  text: 'Edit Section',
                  icon: Icons.edit,
                  backgroundColor: AppTheme.primaryColor,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditSectionScreen(section: widget.section)),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Assign Principal',
                  icon: Icons.person_add,
                  backgroundColor: Colors.blue,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AssignPrincipalScreen(section: widget.section)),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Assign Bursar',
                  icon: Icons.account_balance_wallet,
                  backgroundColor: Colors.indigo,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AssignBursarScreen(section: widget.section)),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Delete Section',
                  icon: Icons.delete,
                  backgroundColor: Colors.red,
                  onPressed: () => _deleteSection(context),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildModernDetailItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
        bool isImportant = false,
        }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isImportant 
                  ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isImportant ? AppTheme.primaryColor : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                    fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
