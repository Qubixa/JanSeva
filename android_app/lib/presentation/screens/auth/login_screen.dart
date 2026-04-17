import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        height: screenHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1),
              const Color(0xFF8B5CF6),
              const Color(0xFFA855F7),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).padding.top),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    left: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withOpacity(0.05),
                      ),
                    ),
                  ),

                  // Main Content
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 24 : 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 500),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(isMobile ? 32 : 48),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Logo with gradient
                                          Center(
                                            child: Container(
                                              height: 100,
                                              width: 100,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF6366F1),
                                                    Color(0xFF8B5CF6),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(24),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF6366F1).withOpacity(0.4),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.location_city,
                                                size: 50,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 32),

                                          Text(
                                            'Welcome Back',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                              color: AppColors.grey900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          Text(
                                            'Login to Nagarseva Services',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: AppColors.grey300,
                                            ),
                                          ),

                                          const SizedBox(height: 40),

                                          // Mobile Number Field
                                          _buildFieldLabel(context, Icons.phone, 'Mobile Number', true),
                                          const SizedBox(height: 12),
                                          CustomTextField(
                                            hint: '9876543210',
                                            controller: _mobileController,
                                            keyboardType: TextInputType.phone,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Mobile number is required';
                                              }
                                              if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                                                return 'Enter a valid mobile number';
                                              }
                                              return null;
                                            },
                                          ),

                                          const SizedBox(height: 24),

                                          // Password Field
                                          _buildFieldLabel(context, Icons.lock_outline, 'Password', true),
                                          const SizedBox(height: 12),
                                          CustomTextField(
                                            hint: 'Enter your password',
                                            controller: _passwordController,
                                            isPassword: true,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Password is required';
                                              }
                                              if (value.length < 6) {
                                                return 'Password must be at least 6 characters';
                                              }
                                              return null;
                                            },
                                          ),

                                          const SizedBox(height: 32),

                                          // Login Button
                                          Consumer<AuthProvider>(
                                            builder: (context, authProvider, _) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Color(0xFF6366F1),
                                                      Color(0xFF8B5CF6),
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF6366F1).withOpacity(0.4),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 6),
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton(
                                                  onPressed: authProvider.isLoading
                                                      ? null
                                                      : () {
                                                    if (_formKey.currentState!.validate()) {
                                                      _handleLogin(context, authProvider);
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    shadowColor: Colors.transparent,
                                                    foregroundColor: AppColors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: authProvider.isLoading
                                                      ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                                    ),
                                                  )
                                                      : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(Icons.login, size: 20),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Login',
                                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                          color: AppColors.white,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                          const SizedBox(height: 20),

                                          // Error Message
                                          Consumer<AuthProvider>(
                                            builder: (context, authProvider, _) {
                                              if (authProvider.error != null) {
                                                return Container(
                                                  padding: const EdgeInsets.all(14),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        const Color(0xFFF44336).withOpacity(0.1),
                                                        const Color(0xFFE53935).withOpacity(0.05),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: const Color(0xFFF44336).withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF44336),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Icon(
                                                          Icons.error_outline,
                                                          color: AppColors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          authProvider.error!,
                                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            color: const Color(0xFFC62828),
                                                            fontWeight: FontWeight.w500,
                                                          ),
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

                                          // Divider
                                          Row(
                                            children: [
                                              Expanded(child: Divider(color: AppColors.grey300)),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                child: Text(
                                                  'OR',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppColors.grey500,
                                                  ),
                                                ),
                                              ),
                                              Expanded(child: Divider(color: AppColors.grey300)),
                                            ],
                                          ),

                                          const SizedBox(height: 24),

                                          // Sign Up
                                          Center(
                                            child: RichText(
                                              text: TextSpan(
                                                text: "Don't have an account? ",
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  color: AppColors.grey300,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: 'Sign Up',
                                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                      color: const Color(0xFF6366F1),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    recognizer: TapGestureRecognizer()
                                                      ..onTap = () {
                                                        Navigator.pushNamed(context, '/register');
                                                      },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
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

  Widget _buildFieldLabel(BuildContext context, IconData icon, String label, bool required) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(0.1),
                const Color(0xFF8B5CF6).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.grey900,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleLogin(BuildContext context, AuthProvider authProvider) async {
    print('🔐 Login pressed');
    print('📱 Mobile: ${_mobileController.text.trim()}');

    FocusScope.of(context).unfocus();

    await authProvider.login(
      _mobileController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }
}

extension on Color {
  Color withOpacity(double opacity) {
    return Color.fromARGB(
      (255 * opacity).toInt(),
      red,
      green,
      blue,
    );
  }
}