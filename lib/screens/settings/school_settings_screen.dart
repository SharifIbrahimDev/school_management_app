import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/school_service_api.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/responsive_widgets.dart';

import '../../widgets/custom_app_bar.dart';

class SchoolSettingsScreen extends StatefulWidget {
  const SchoolSettingsScreen({super.key});

  @override
  State<SchoolSettingsScreen> createState() => _SchoolSettingsScreenState();
}

class _SchoolSettingsScreenState extends State<SchoolSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _schoolShortCodeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSavingProfile = false;
  List<Map<String, dynamic>> _banks = [];
  String? _selectedBankCode;
  String? _selectedBankName;
  Map<String, dynamic>? _schoolData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authService = Provider.of<AuthServiceApi>(context, listen: false);
      final schoolService = Provider.of<SchoolServiceApi>(context, listen: false);
      
      // Load banks and school data in parallel
      final results = await Future.wait([
        schoolService.getBanks(),
        authService.refreshUser(), // This will refresh the user and school data in context
      ]);

      final user = authService.currentUser;
      if (user != null && user['school'] != null) {
        _schoolData = user['school'];
        _schoolNameController.text = _schoolData?['name'] ?? '';
        _schoolShortCodeController.text = _schoolData?['short_code'] ?? '';
        
        // If they already have a subaccount, we might want to pre-fill, 
        // but for now let's focus on the new fields
      }

      setState(() {
        _banks = (results[0] as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Failed to load settings: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_schoolNameController.text.trim().isEmpty || _schoolShortCodeController.text.trim().isEmpty) {
      AppSnackbar.showError(context, message: 'Name and Short Code are required');
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      final schoolService = Provider.of<SchoolServiceApi>(context, listen: false);
      final authService = Provider.of<AuthServiceApi>(context, listen: false);
      
      await schoolService.updateSchool(
        name: _schoolNameController.text.trim(),
        shortCode: _schoolShortCodeController.text.trim().toUpperCase(),
      );

      // Refresh user to get updated school data and IDs
      await authService.refreshUser();

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'School profile updated! Staff/Student IDs have been synchronized.');
        setState(() => _isSavingProfile = false);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Update failed: $e');
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _setupSubaccount() async {
    if (!_formKey.currentState!.validate() || _selectedBankCode == null) {
      AppSnackbar.showError(context, message: 'Please complete all fields');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final schoolService = Provider.of<SchoolServiceApi>(context, listen: false);
      await schoolService.setupSubaccount(
        settlementBank: _selectedBankCode!,
        accountNumber: _accountNumberController.text,
      );

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'Independent Payouts Initialized Successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Setup failed: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Payout Settings',
      ),
      body: Container(
        height: double.infinity,
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
          child: AppTheme.constrainedContent(
            context: context,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: AppTheme.responsivePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        ResponsiveRowColumn(
                          rowOnMobile: false,
                          rowOnTablet: true,
                          rowOnDesktop: true,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Section
                            Expanded(
                              flex: 1,
                              child: _buildProfileSection(),
                            ),
                            
                            if (!context.isMobile) const SizedBox(width: 32),
                            if (context.isMobile) const SizedBox(height: 32),
  
                            // Payout Section
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  _buildPayoutHeader(),
                                  const SizedBox(height: 24),
                                  _buildSetupForm(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.8,
        borderRadius: 24,
        hasGlow: true,
        borderColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_rounded, size: 48, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'School Management',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your school profile and financial settlement settings here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderRadius: 24,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('General Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _schoolNameController,
            decoration: InputDecoration(
              labelText: 'School Name',
              prefixIcon: const Icon(Icons.school, color: AppTheme.primaryColor),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _schoolShortCodeController,
            decoration: InputDecoration(
              labelText: 'School Short Code',
              helperText: 'Changing this will update all Staff & Student IDs',
              prefixIcon: const Icon(Icons.tag, color: AppTheme.primaryColor),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Update Profile',
            isLoading: _isSavingProfile,
            onPressed: _saveProfile,
            icon: Icons.save_rounded,
            backgroundColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutHeader() {
    return Column(
      children: [
        const Text('Independent Payouts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Link your school\'s bank account to receive automated daily payouts directly from Paystack.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.6,
        borderRadius: 24,
        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payments_rounded, size: 20, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Settlement Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            
            DropdownButtonFormField<String>(
              initialValue: _selectedBankCode,
              dropdownColor: Theme.of(context).cardColor,
              decoration: InputDecoration(
                labelText: 'Select Bank',
                prefixIcon: const Icon(Icons.business_rounded, color: AppTheme.primaryColor),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              items: _banks.map((bank) {
                return DropdownMenuItem<String>(
                  value: bank['code'],
                  child: Text(bank['name'], style: const TextStyle(fontSize: 14)),
                  onTap: () => _selectedBankName = bank['name'],
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedBankCode = val),
              validator: (val) => val == null ? 'Please select a bank' : null,
            ),
            const SizedBox(height: 16),
  
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Account Number',
                prefixIcon: const Icon(Icons.numbers_rounded, color: AppTheme.primaryColor),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                counterText: '',
              ),
              validator: (val) => (val?.length ?? 0) < 10 ? 'Enter a valid 10-digit NUBAN' : null,
            ),
            
            const SizedBox(height: 32),
            
            CustomButton(
              text: 'Save & Initialize',
              isLoading: _isSaving,
              onPressed: _setupSubaccount,
              icon: Icons.rocket_launch_rounded,
              backgroundColor: AppTheme.accentColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolShortCodeController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }
}
