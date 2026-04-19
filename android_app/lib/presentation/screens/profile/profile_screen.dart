import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.mobile ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: AppColors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Profile Avatar
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : 'U',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: AppColors.white,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Name Field
                      CustomTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        prefix: const Icon(Icons.person_outline, color: AppColors.grey500),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Email Field (Read-only)
                      CustomTextField(
                        label: 'Email',
                        controller: _emailController,
                        prefix: const Icon(Icons.email_outlined, color: AppColors.grey500),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Email is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Phone Field
                      CustomTextField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefix: const Icon(Icons.phone_outlined, color: AppColors.grey500),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Phone number is required';
                          if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // User Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grey300),
                        ),
                        child: Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Account Type',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppColors.grey100,
                                                ),
                                          ),
                                          Text(
                                            authProvider.user?.role ?? 'User',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  color: AppColors.grey900,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (authProvider.user?.wardName != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Ward',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppColors.grey100,
                                                  ),
                                            ),
                                            Text(
                                              authProvider.user!.wardName!,
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    color: AppColors.grey900,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Update Button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return CustomButton(
                            label: 'Update Profile',
                            isLoading: authProvider.isLoading,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _handleUpdate(context, authProvider);
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate(BuildContext context, AuthProvider authProvider) async {
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(), // ✅ ADD NAMED PARAMETER
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null, // ✅ ADD EMAIL
      // Note: Phone/mobile cannot be changed in backend, so we don't send it
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? 'Failed to update profile')),
        );
      }
    }
  }
}
