import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/services_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? _selectedWardId;

  @override
  void initState() {
    super.initState();
    // Load wards when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicesProvider>().fetchWards();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.grey900),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join Nagarseva Services Community',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Name Field
                      CustomTextField(
                        label: 'Full Name',
                        hint: 'Your full name',
                        controller: _nameController,
                        prefix: const Icon(Icons.person_outline, color: AppColors.grey500),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Name is required';
                          if ((value?.length ?? 0) < 2) return 'Name must be at least 2 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field (Optional)
                      CustomTextField(
                        label: 'Email (Optional)',
                        hint: 'your@email.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefix: const Icon(Icons.email_outlined, color: AppColors.grey500),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      CustomTextField(
                        label: 'Mobile Number',
                        hint: '10-digit mobile number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefix: const Icon(Icons.phone_outlined, color: AppColors.grey500),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Mobile number is required';
                          if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
                            return 'Please enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Ward Dropdown
                      Consumer<ServicesProvider>(
                        builder: (context, servicesProvider, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ward *',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.grey700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.grey300),
                                ),
                                child: servicesProvider.isLoading
                                    ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                )
                                    : servicesProvider.wards.isEmpty
                                    ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No wards available',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                )
                                    : DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    hint: Text(
                                      'Select your ward',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.grey500,
                                      ),
                                    ),
                                    value: _selectedWardId,
                                    items: servicesProvider.wards.map((ward) {
                                      return DropdownMenuItem<int>(
                                        value: ward.id,
                                        child: Text(
                                          ward.name,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.grey900,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedWardId = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              if (_selectedWardId == null && servicesProvider.wards.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, left: 12),
                                  child: Text(
                                    'Please select a ward',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address Field
                      CustomTextField(
                        label: 'Address',
                        hint: 'Your full address',
                        controller: _addressController,
                        maxLines: 3,
                        prefix: const Icon(Icons.home_outlined, color: AppColors.grey500),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Address is required';
                          if ((value?.length ?? 0) < 10) {
                            return 'Address must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      CustomTextField(
                        label: 'Password',
                        hint: 'Minimum 6 characters',
                        controller: _passwordController,
                        isPassword: true,
                        prefix: const Icon(Icons.lock_outline, color: AppColors.grey500),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Password is required';
                          if ((value?.length ?? 0) < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      CustomTextField(
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        controller: _confirmPasswordController,
                        isPassword: true,
                        prefix: const Icon(Icons.lock_outline, color: AppColors.grey500),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Please confirm your password';
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Register Button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return CustomButton(
                            label: 'Create Account',
                            isLoading: authProvider.isLoading,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _handleRegister(context, authProvider);
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Error Message
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          if (authProvider.error != null) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      authProvider.error!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 24),

                      // Login Link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pop(context);
                                  },
                              ),
                            ],
                          ),
                        ),
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

  void _handleRegister(BuildContext context, AuthProvider authProvider) async {
    print('📝 Registration attempt');
    print('Mobile: ${_phoneController.text.trim()}');
    print('Ward ID: $_selectedWardId');

    // Validate ward selection
    if (_selectedWardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a ward'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await authProvider.register(
      name: _nameController.text.trim(),
      mobile: _phoneController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      wardId: _selectedWardId!,
      address: _addressController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (success) {
      print('✅ Registration successful');
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      print('❌ Registration failed: ${authProvider.error}');
    }
  }
}