import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/school_service_api.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/utils/app_theme.dart';

import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
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
  final _bankSearchController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSavingProfile = false;
  bool _isResolving = false;
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _filteredBanks = [];
  String? _selectedBankCode;
  String? _selectedBankName;
  String? _resolvedAccountName;
  Map<String, dynamic>? _schoolData;

  @override
  void initState() {
    super.initState();
    _loadData();
    _accountNumberController.addListener(_onAccountNumberChanged);
  }

  void _onAccountNumberChanged() {
    if (_accountNumberController.text.length == 10 && _selectedBankCode != null) {
      _resolveAccount();
    } else {
      if (_resolvedAccountName != null) {
        setState(() => _resolvedAccountName = null);
      }
    }
  }

  Future<void> _resolveAccount() async {
    if (_isResolving) return;
    
    setState(() {
      _isResolving = true;
      _resolvedAccountName = null;
    });

    try {
      final schoolService = Provider.of<SchoolServiceApi>(context, listen: false);
      final result = await schoolService.resolveBankAccount(
        accountNumber: _accountNumberController.text,
        bankCode: _selectedBankCode!,
      );

      if (mounted) {
        setState(() {
          _isResolving = false;
          _resolvedAccountName = result?['account_name'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final authService = Provider.of<AuthServiceApi>(context, listen: false);
      final schoolService = Provider.of<SchoolServiceApi>(context, listen: false);
      
      final results = await Future.wait([
        schoolService.getBanks(),
        authService.refreshUser(),
      ]);

      final user = authService.currentUser;
      if (user != null && user['school'] != null) {
        _schoolData = user['school'];
        _schoolNameController.text = _schoolData?['name'] ?? '';
        _schoolShortCodeController.text = _schoolData?['short_code'] ?? '';
        
        if (_schoolData?['settlement_bank'] != null) {
          _selectedBankCode = _schoolData?['settlement_bank'];
          _accountNumberController.text = _schoolData?['account_number'] ?? '';
        }
      }

      setState(() {
        _banks = (results[0] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _filteredBanks = _banks;
        
        // Find bank name if code exists
        if (_selectedBankCode != null) {
          final bank = _banks.firstWhere((b) => b['code'] == _selectedBankCode, orElse: () => {});
          if (bank.isNotEmpty) _selectedBankName = bank['name'];
        }
        
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Failed to load settings: $e');
        setState(() => _isLoading = false);
      }
    }
  }



  void _showBankPicker() {
    _bankSearchController.clear();
    _filteredBanks = _banks;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Select Your Bank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _bankSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search Nigerian banks...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      _filteredBanks = _banks
                          .where((bank) => bank['name'].toString().toLowerCase().contains(val.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filteredBanks.length,
                  itemBuilder: (context, index) {
                    final bank = _filteredBanks[index];
                    final isSelected = _selectedBankCode == bank['code'];
                    
                    return ListTile(
                      onTap: () {
                        setState(() {
                          _selectedBankCode = bank['code'];
                          _selectedBankName = bank['name'];
                        });
                        if (_accountNumberController.text.length == 10) _resolveAccount();
                        Navigator.pop(context);
                      },
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                        child: Text(bank['name'][0], style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                      ),
                      title: Text(bank['name'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor) : null,
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

      await authService.refreshUser();

      if (mounted) {
        AppSnackbar.showSuccess(context, message: 'School profile updated successfully!');
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
    if (!_formKey.currentState!.validate() || _selectedBankCode == null || _resolvedAccountName == null) {
      AppSnackbar.showError(context, message: 'Please verify account details first');
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
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Setup failed: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.verified_rounded, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text('Verification Successful!', textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          'Your independent payout system has been initialized. Paystack will now verify these details. You will receive an email once fully activated.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close screen
              },
              child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Payout Settings',
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/auth_bg_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.15),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: AppTheme.constrainedContent(
            context: context,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        
                        ResponsiveRowColumn(
                          rowOnMobile: false,
                          rowOnTablet: true,
                          rowOnDesktop: true,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildProfileSection()),
                            const SizedBox(width: 24, height: 24),
                            Expanded(child: _buildPayoutSection()),
                          ],
                        ),
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
        opacity: 0.4,
        borderRadius: 24,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shield_rounded, color: AppTheme.accentColor, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Financial Security', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  'Your payouts are processed directly via Paystack sub-accounts.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text('SCHOOL PROFILE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.6, borderRadius: 24),
          child: Column(
            children: [
              TextFormField(
                controller: _schoolNameController,
                decoration: InputDecoration(
                  labelText: 'School Legal Name',
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _schoolShortCodeController,
                decoration: InputDecoration(
                  labelText: 'Unique Short Code',
                  hintText: 'e.g. BHS',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Update School Info',
                isLoading: _isSavingProfile,
                onPressed: _saveProfile,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text('SETTLEMENT ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2, color: AppTheme.accentColor)),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassDecoration(context: context, opacity: 0.8, borderRadius: 24, hasGlow: true),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Bank Picker
                InkWell(
                  onTap: _showBankPicker,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, color: AppTheme.accentColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedBankName ?? 'Select Settlement Bank',
                            style: TextStyle(
                              color: _selectedBankName == null ? Colors.grey[600] : Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Account Number
                TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'NUBAN Account Number',
                    counterText: '',
                    prefixIcon: const Icon(Icons.numbers_rounded),
                    suffixIcon: _isResolving ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) => (val?.length ?? 0) < 10 ? 'Precisely 10 digits required' : null,
                ),
                
                // Resolved Name View
                if (_resolvedAccountName != null || _isResolving)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _resolvedAccountName != null ? Colors.green.withValues(alpha: 0.05) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _resolvedAccountName != null ? Colors.green.withValues(alpha: 0.2) : Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _resolvedAccountName != null ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                            color: _resolvedAccountName != null ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _resolvedAccountName != null ? 'Account Verified' : 'Resolving Account...',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                ),
                                if (_resolvedAccountName != null)
                                  Text(
                                    _resolvedAccountName!.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                const SizedBox(height: 32),
                
                CustomButton(
                  text: 'Connect to Paystack',
                  isLoading: _isSaving,
                  onPressed: _setupSubaccount,
                  icon: Icons.link_rounded,
                  backgroundColor: AppTheme.accentColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _accountNumberController.removeListener(_onAccountNumberChanged);
    _schoolNameController.dispose();
    _schoolShortCodeController.dispose();
    _accountNumberController.dispose();
    _bankSearchController.dispose();
    super.dispose();
  }
}
