import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/report_service_api.dart';
import '../../core/services/section_service_api.dart';
import '../../core/services/school_service_api.dart';
import '../../core/models/section_model.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_app_bar.dart';

class DebtorsListScreen extends StatefulWidget {
  const DebtorsListScreen({super.key});

  @override
  State<DebtorsListScreen> createState() => _DebtorsListScreenState();
}

class _DebtorsListScreenState extends State<DebtorsListScreen> {
  List<Map<String, dynamic>> _debtors = [];
  List<SectionModel> _sections = [];
  String? _selectedSectionId;
  bool _isLoading = true;
  String? _schoolName;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
      final sectionsData = await sectionService.getSections(isActive: true);
      _sections = sectionsData.map((s) => SectionModel.fromMap(s)).toList();

      if (!mounted) return;
      final schoolService = Provider.of<SchoolServiceApi>(context, listen: false);
      final schoolData = await schoolService.getSchool();
      _schoolName = schoolData['name'] ?? 'The School';

      if (!mounted) return;
      await _loadDebtors();
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Initialization failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDebtors() async {
    try {
      if (!mounted) return;
      final reportService = Provider.of<ReportServiceApi>(context, listen: false);
      final debtorsData = await reportService.getDebtors(
        sectionId: _selectedSectionId != null ? int.tryParse(_selectedSectionId!) : null,
      );
      setState(() => _debtors = debtorsData);
    } catch (e) {
      debugPrint('Error loading debtors: $e');
    }
  }

  Future<void> _nudgeWhatsApp(Map<String, dynamic> debtor) async {
    final phone = debtor['parent_phone'] ?? '';
    if (phone.isEmpty) {
      AppSnackbar.showError(context, message: 'No parent phone number found');
      return;
    }

    final student = debtor['student_name'];
    final balance = Formatters.formatCurrency(debtor['balance']);
    final message = "Dear ${debtor['parent_name'] ?? 'Parent'}, this is a priority reminder from $_schoolName regarding the outstanding balance of $balance for $student. Please kindly make payments at your earliest convenience to avoid service interruption. Thank you.";

    final whatsappUrl = Uri.parse("https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}");
    
    try {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Could not launch WhatsApp: $e');
    }
  }

  Future<void> _nudgeSMS(Map<String, dynamic> debtor) async {
    final phone = debtor['parent_phone'] ?? '';
    if (phone.isEmpty) {
      AppSnackbar.showError(context, message: 'No parent phone number found');
      return;
    }

    final student = debtor['student_name'];
    final balance = Formatters.formatCurrency(debtor['balance']);
    final message = "Reminder from $_schoolName: Outstanding balance for $student is $balance. Please kindly make payment. Thank you.";

    final smsUrl = Uri.parse("sms:${phone.replaceAll(' ', '')}?body=${Uri.encodeComponent(message)}");
    
    try {
      await launchUrl(smsUrl);
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, message: 'Could not launch SMS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Outstanding Fees',
      ),
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/auth_bg_pattern.png'),
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
          child: Column(
            children: [
              _buildFilterHeader(),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _debtors.isEmpty 
                    ? _buildEmptyState()
                    : _buildDebtorsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.6,
          borderRadius: 16,
          borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedSectionId,
            hint: const Text('Filter by Section'),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Sections')),
              ..._sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.sectionName))),
            ],
            onChanged: (val) {
              setState(() {
                _selectedSectionId = val;
                _loadDebtors();
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No outstanding balances found!', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('All students have cleared their fees.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDebtorsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _debtors.length,
      itemBuilder: (context, index) {
        final debtor = _debtors[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppTheme.glassDecoration(
            context: context,
            opacity: 0.8,
            borderRadius: 20,
            hasGlow: true,
            borderColor: Colors.redAccent.withValues(alpha: 0.2),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(20),
                title: Text(debtor['student_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.class_rounded, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${debtor['class_name']} • ${debtor['section_name']}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('Parent: ${debtor['parent_name']}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(Formatters.formatCurrency(debtor['balance']), 
                      style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5)),
                    const Text('BALANCE', style: TextStyle(color: AppTheme.errorColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.02),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Text('QUICK NUDGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[600], letterSpacing: 0.8)),
                    const Spacer(),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'WhatsApp',
                      color: Colors.green,
                      onTap: () => _nudgeWhatsApp(debtor),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.sms_outlined,
                      label: 'SMS',
                      color: Colors.blue,
                      onTap: () => _nudgeSMS(debtor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
