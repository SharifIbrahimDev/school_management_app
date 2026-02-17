import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/enums/fee_scope.dart';
import '../../core/models/class_model.dart';
import '../../core/models/fee_model.dart';
import '../../core/models/section_model.dart';
import '../../core/models/academic_session_model.dart';
import '../../core/models/term_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/class_service_api.dart';
import '../../core/services/fee_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/session_service_api.dart';
import '../../core/services/term_service_api.dart';
import '../../core/utils/formatters.dart';
import 'fee_detail_screen.dart';
import 'add_fee_screen.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';

class FeeListScreen extends StatefulWidget {
  final FeeScope? scope;
  final String? schoolId;
  final String? sectionId;
  final String? sessionId;
  final String? termId;
  final String? classId;
  final String? studentId;
  final String? parentId;
  
  const FeeListScreen({
    super.key,
    this.scope,
    this.schoolId,
    this.sectionId,
    this.sessionId,
    this.termId,
    this.classId,
    this.studentId,
    this.parentId,
  });

  @override
  State<FeeListScreen> createState() => _FeeListScreenState();
}

class _FeeListScreenState extends State<FeeListScreen> {
  List<FeeModel> _fees = [];
  List<SectionModel> _sections = [];
  List<AcademicSessionModel> _sessions = [];
  List<TermModel> _terms = [];
  List<ClassModel> _classes = [];

  String? _selectedSectionId;
  String? _selectedSessionId;
  String? _selectedTermId;
  String? _selectedClassId;
  
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize from widget parameters if provided
    _selectedSectionId = widget.sectionId;
    _selectedSessionId = widget.sessionId;
    _selectedTermId = widget.termId;
    _selectedClassId = widget.classId;
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
        _sections = allSections;
      } else {
        _sections = allSections.where((s) => _currentUser!.assignedSections.contains(s.id)).toList();
      }

      if (_sections.isNotEmpty) {
        _selectedSectionId ??= _sections.first.id;
        await _loadSessions();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No sections assigned';
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

    try {
      final sessionService = Provider.of<SessionServiceApi>(context, listen: false);
      final sessionsData = await sessionService.getSessions(sectionId: int.tryParse(_selectedSectionId!));
      
      if (mounted) {
        setState(() {
          _sessions = sessionsData.map((data) => AcademicSessionModel.fromMap(data)).toList();
          if (_sessions.isNotEmpty && _selectedSessionId == null) {
            _selectedSessionId = _sessions.firstWhere((s) => s.isActive, orElse: () => _sessions.first).id;
          }
        });
        await _loadTerms();
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

  Future<void> _loadTerms() async {
    if (_selectedSectionId == null || _selectedSessionId == null) return;

    try {
      final termService = Provider.of<TermServiceApi>(context, listen: false);
      final termsData = await termService.getTerms(
        sectionId: int.tryParse(_selectedSectionId!),
        sessionId: int.tryParse(_selectedSessionId!),
      );
      
      if (mounted) {
        setState(() {
          _terms = termsData.map((data) => TermModel.fromMap(data)).toList();
          if (_terms.isNotEmpty && _selectedTermId == null) {
            _selectedTermId = _terms.firstWhere((t) => t.isActive, orElse: () => _terms.first).id;
          }
        });
        await _loadClasses();
      }
    } catch (e) {
      debugPrint('Error loading terms: $e');
    }
  }

  Future<void> _loadClasses() async {
    if (_selectedSectionId == null) return;

    try {
      final classService = Provider.of<ClassServiceApi>(context, listen: false);
      final classesData = await classService.getClasses(sectionId: int.tryParse(_selectedSectionId!));
      
      if (mounted) {
        setState(() {
          _classes = classesData.map((data) => ClassModel.fromMap(data)).toList();
        });
        await _loadFees();
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  Future<void> _loadFees() async {
    setState(() => _isLoading = true);

    try {
      final feeService = Provider.of<FeeServiceApi>(context, listen: false);
      final feesData = await feeService.getFees(
        sectionId: int.tryParse(_selectedSectionId ?? ''),
        sessionId: int.tryParse(_selectedSessionId ?? ''),
        termId: int.tryParse(_selectedTermId ?? ''),
        classId: int.tryParse(_selectedClassId ?? ''),
      );
      
      if (mounted) {
        setState(() {
          _fees = feesData.map((data) => FeeModel.fromMap(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading fees: $e';
        });
      }
    }
  }

  String? _editingFeeId;
  final TextEditingController _editAmountController = TextEditingController();

  Future<void> _updateFeeAmount(FeeModel fee, double newAmount) async {
    setState(() => _isLoading = true);
    try {
      final feeService = Provider.of<FeeServiceApi>(context, listen: false);
      await feeService.updateFee(int.parse(fee.id), amount: newAmount);
      setState(() {
        _editingFeeId = null;
        _isLoading = false;
      });
      await _loadFees();
      if (mounted) AppSnackbar.showSuccess(context, message: 'Fee updated successfully');
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) AppSnackbar.showError(context, message: 'Update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _currentUser?.role;
    final canAddFee = role == UserRole.proprietor || 
                      role == UserRole.principal || 
                      role == UserRole.bursar;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Fees',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      floatingActionButton: canAddFee && _selectedSectionId != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddFeeScreen(
                      sectionId: _selectedSectionId!,
                      sessionId: _selectedSessionId,
                      termId: _selectedTermId,
                    ),
                  ),
                ).then((_) => _loadFees());
              },
              backgroundColor: AppTheme.primaryColor,
              tooltip: 'Add Fee',
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
          child: AppTheme.constrainedContent(
            context: context,
            child: SingleChildScrollView(
              padding: AppTheme.responsivePadding(context),
              child: ResponsiveRowColumn(
                rowOnMobile: false,
                rowOnTablet: true,
                rowOnDesktop: true,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters Side
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Filter Fees', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: AppTheme.glassDecoration(
                            context: context,
                            opacity: 0.7,
                            borderRadius: 16,
                            borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: !context.isMobile,
                            title: const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    if (_sections.isNotEmpty)
                                      _buildDropdownWrapper(
                                        context,
                                        label: 'Section',
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedSectionId,
                                          decoration: const InputDecoration(border: InputBorder.none),
                                          items: _sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.sectionName))).toList(),
                                          onChanged: (value) {
                                            setState(() => _selectedSectionId = value);
                                            _loadSessions();
                                          },
                                        ),
                                      ),
                                    if (_sessions.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      _buildDropdownWrapper(
                                        context,
                                        label: 'Session',
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedSessionId,
                                          decoration: const InputDecoration(border: InputBorder.none),
                                          items: _sessions.map((s) => DropdownMenuItem(value: s.id, child: Text(s.sessionName))).toList(),
                                          onChanged: (value) {
                                            setState(() => _selectedSessionId = value);
                                            _loadTerms();
                                          },
                                        ),
                                      ),
                                    ],
                                    if (_terms.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      _buildDropdownWrapper(
                                        context,
                                        label: 'Term',
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedTermId,
                                          decoration: const InputDecoration(border: InputBorder.none),
                                          items: _terms.map((t) => DropdownMenuItem(value: t.id, child: Text(t.termName))).toList(),
                                          onChanged: (value) {
                                            setState(() => _selectedTermId = value);
                                            _loadFees();
                                          },
                                        ),
                                      ),
                                    ],
                                    if (_classes.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      _buildDropdownWrapper(
                                        context,
                                        label: 'Class (Optional)',
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedClassId,
                                          decoration: const InputDecoration(border: InputBorder.none),
                                          items: [
                                            const DropdownMenuItem(value: null, child: Text('All Classes')),
                                            ..._classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                                          ],
                                          onChanged: (value) {
                                            setState(() => _selectedClassId = value);
                                            _loadFees();
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                  
                  if (!context.isMobile) const SizedBox(width: 32),
  
                  // Fee List Side
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Active Fees', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            if (_fees.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('${_fees.length}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                        else if (_fees.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No fees found for selected criteria')))
                        else
                          ResponsiveGridView(
                            mobileColumns: 1,
                            tabletColumns: 1,
                            desktopColumns: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            spacing: 16,
                            runSpacing: 16,
                            children: _fees.map((fee) {
                              final isEditing = _editingFeeId == fee.id;
                              return Container(
                                decoration: AppTheme.glassDecoration(
                                  context: context,
                                  opacity: 0.6,
                                  borderRadius: 20,
                                  hasGlow: true,
                                  borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(20),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryColor),
                                  ),
                                  title: Text(
                                    fee.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Due: ${Formatters.formatDate(fee.dueDate)}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isEditing)
                                        SizedBox(
                                          width: 100,
                                          child: TextField(
                                            controller: _editAmountController,
                                            keyboardType: TextInputType.number,
                                            autofocus: true,
                                            decoration: const InputDecoration(prefixText: '₦', isDense: true),
                                            onSubmitted: (val) {
                                              final amt = double.tryParse(val);
                                              if (amt != null) {
                                                _updateFeeAmount(fee, amt);
                                              } else {
                                                setState(() => _editingFeeId = null);
                                              }
                                            },
                                          ),
                                        )
                                      else
                                        GestureDetector(
                                          onTap: () {
                                            if (canAddFee) {
                                              setState(() {
                                                _editingFeeId = fee.id;
                                                _editAmountController.text = fee.amount.toString();
                                              });
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => FeeDetailScreen(fee: fee)),
                                              );
                                            }
                                          },
                                          child: Text(
                                            Formatters.formatCurrency(fee.amount),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                    ],
                                  ),
                                  onTap: isEditing ? null : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => FeeDetailScreen(fee: fee)),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownWrapper(BuildContext context, {required String label, required Widget child}) {
    return Container(
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.3,
        borderRadius: 12,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          child: child,
        ),
      ),
    );
  }
}
