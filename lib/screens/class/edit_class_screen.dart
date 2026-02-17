import '../../widgets/custom_app_bar.dart';

class EditClassScreen extends StatefulWidget {
  final ClassModel classModel;
  final String schoolId;
  final String sectionId;

  const EditClassScreen({
    super.key,
    required this.classModel,
    required this.schoolId,
    required this.sectionId,
  });

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  // ... (keep state logic)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Class',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.8),
              theme.primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration(
                context: context,
                opacity: 0.08,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit Class Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update class details',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Class Name',
                      prefixIcon: Icons.class_,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _teacherIdController,
                      labelText: 'Teacher ID (Optional)',
                      prefixIcon: Icons.person,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Update Class',
                      isLoading: _isLoading,
                      onPressed: _updateClass,
                      icon: Icons.save,
                      backgroundColor: AppTheme.neonTeal,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
