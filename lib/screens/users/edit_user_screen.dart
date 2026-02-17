import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/user_service_api.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_app_bar.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;
  const EditUserScreen({super.key, required this.user});
  
  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.user.fullName;
    _emailController.text = widget.user.email;
    _phoneNumberController.text = widget.user.phoneNumber;
    _addressController.text = widget.user.address;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateUser(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthServiceApi>(context, listen: false);
    final currentUserMap = authService.currentUser;
    
    if (currentUserMap == null) {
      AppSnackbar.showError(context, message: 'User not logged in');
      return;
    }
    
    final currentUser = UserModel.fromMap(currentUserMap);
    if (currentUser.role != UserRole.proprietor) {
      AppSnackbar.showError(context, message: 'Access Denied');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userService = Provider.of<UserServiceApi>(context, listen: false);
      
      await userService.updateUser(
        int.tryParse(widget.user.id) ?? 0,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.showSuccess(context, message: 'User updated successfully');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showError(context, message: 'Error updating user: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit User',
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassDecoration(
                      context: context,
                      opacity: 0.6,
                      hasGlow: true,
                      borderRadius: 20,
                      borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    ),
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _fullNameController,
                          labelText: 'Full Name',
                          prefixIcon: Icons.person,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          labelText: 'Email',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _phoneNumberController,
                          labelText: 'Phone Number',
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _addressController,
                          labelText: 'Address',
                          prefixIcon: Icons.location_on,
                          maxLines: 3,
                          isRequired: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Save Changes',
                    isLoading: _isLoading,
                    onPressed: () => _updateUser(context),
                    icon: Icons.save,
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
