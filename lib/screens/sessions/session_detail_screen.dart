import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../terms/add_term_screen.dart';
import '../terms/term_list_screen.dart';
import '../../widgets/custom_app_bar.dart';

class SessionDetailScreen extends StatefulWidget {
  final AcademicSessionModel session;
  final String schoolId;
  final String sectionId;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.schoolId,
    required this.sectionId,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTerms());
  }

  Future<void> _loadTerms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading terms: $e';
        });
      }
      print('Error loading terms: $e');
    }
    return; // Explicitly return Future<void>
  }

  @override
  Widget build(BuildContext context) {
    final termService = Provider.of<TermServiceApi>(context);
    final authService = Provider.of<AuthServiceApi>(context);
    final isPrincipal = authService.currentUserModel?.role == UserRole.principal;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.session.sessionName,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTerms,
          ),
        ],
      ),
      floatingActionButton: isPrincipal
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTermScreen(
                session: widget.session,
                schoolId: widget.schoolId,
                sectionId: widget.sectionId,
                onSuccess: _loadTerms,
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        tooltip: 'Add Term',
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
      body: Container(
        height: double.infinity,
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassDecoration(
                          context: context,
                          opacity: 0.6,
                          borderRadius: 24,
                          hasGlow: true,
                          borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.session.sessionName,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: widget.session.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: widget.session.isActive ? Colors.green : Colors.grey),
                                  ),
                                  child: Text(
                                    widget.session.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: widget.session.isActive ? Colors.green : Colors.grey[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.calendar_today, 'Start Date', DateFormat('dd MMM, yyyy').format(widget.session.startDate)),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.event, 'End Date', DateFormat('dd MMM, yyyy').format(widget.session.endDate)),
                          ],
                        ),
                      ),
            const SizedBox(height: 24),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Icon(Icons.list_alt, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ACADEMIC TERMS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor.withValues(alpha: 0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TermListView(
                        termService: termService,
                        session: widget.session,
                        schoolId: widget.schoolId,
                        sectionId: widget.sectionId,
                        sessionId: widget.session.id,
                        errorMessage: _errorMessage,
                        onRefresh: _loadTerms,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}
