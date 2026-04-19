import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _particleAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    // Logo animations
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Background animation for gradient shift
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Particle animation
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _logoAnimationController.forward();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _particleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF6366F1),
                    const Color(0xFF8B5CF6),
                    _backgroundAnimationController.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF8B5CF6),
                    const Color(0xFFA855F7),
                    _backgroundAnimationController.value,
                  )!,
                  Color.lerp(
                    const Color(0xFFA855F7),
                    const Color(0xFFEC4899),
                    _backgroundAnimationController.value,
                  )!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated particles
                ...List.generate(20, (index) => _buildFloatingParticle(index)),

                // Decorative circles
                Positioned(
                  top: -150,
                  right: -150,
                  child: AnimatedBuilder(
                    animation: _particleAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1 + (_particleAnimationController.value * 0.1),
                        child: Container(
                          width: 400,
                          height: 400,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withOpacity(0.05),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -100,
                  child: AnimatedBuilder(
                    animation: _particleAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1 + ((1 - _particleAnimationController.value) * 0.1),
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withOpacity(0.05),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Main content
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Logo
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: AnimatedBuilder(
                              animation: _rotateAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotateAnimation.value,
                                  child: Container(
                                    height: 140,
                                    width: 140,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.white,
                                          Color(0xFFF3F4F6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(35),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 40,
                                          offset: const Offset(0, 20),
                                        ),
                                        BoxShadow(
                                          color: AppColors.white.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, -10),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -_rotateAnimation.value,
                                        child: ShaderMask(
                                          shaderCallback: (bounds) {
                                            return const LinearGradient(
                                              colors: [
                                                Color(0xFF6366F1),
                                                Color(0xFF8B5CF6),
                                                Color(0xFFA855F7),
                                              ],
                                            ).createShader(bounds);
                                          },
                                          child: const Icon(
                                            Icons.location_city,
                                            size: 70,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 40),

                          // App Name with gradient
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [
                                  AppColors.white,
                                  Color(0xFFF3F4F6),
                                ],
                              ).createShader(bounds);
                            },
                            child: Text(
                              'JanSeva',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 48,
                                letterSpacing: 2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Tagline
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Citizen Services at Your Fingertips',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 80),

                          // Loading indicator with pulse effect
                          AnimatedBuilder(
                            animation: _particleAnimationController,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer pulse ring
                                  Transform.scale(
                                    scale: 1 + (_particleAnimationController.value * 0.5),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.white.withOpacity(
                                            0.3 * (1 - _particleAnimationController.value),
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Inner spinner
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white.withOpacity(0.9),
                                      ),
                                      strokeWidth: 3,
                                      backgroundColor: AppColors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Loading text
                          AnimatedBuilder(
                            animation: _particleAnimationController,
                            builder: (context, child) {
                              final dots = '.' * ((_particleAnimationController.value * 3).toInt() + 1);
                              return Text(
                                'Loading$dots',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = 4.0 + random.nextDouble() * 8;
    final duration = 3 + random.nextInt(4);
    final delay = random.nextDouble() * 2;

    return Positioned(
      left: random.nextDouble() * MediaQuery.of(context).size.width,
      top: random.nextDouble() * MediaQuery.of(context).size.height,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(seconds: duration),
        builder: (context, double value, child) {
          return AnimatedBuilder(
            animation: _particleAnimationController,
            builder: (context, child) {
              final offset = math.sin((_particleAnimationController.value * 2 * math.pi) + (index * 0.5)) * 20;
              return Transform.translate(
                offset: Offset(0, offset),
                child: Opacity(
                  opacity: (0.3 + (math.sin(_particleAnimationController.value * 2 * math.pi) * 0.3)).clamp(0.0, 1.0),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.white.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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