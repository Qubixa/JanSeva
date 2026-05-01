import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LOKSEVA — Login Screen · 2026
//  Umang-inspired professional light theme
//  High-contrast fields · Accessible · Clean government aesthetics
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _mobileCtrl   = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _mobileHasFocus  = false;
  bool _passwordHasFocus = false;
  final _mobileFocus   = FocusNode();
  final _passwordFocus = FocusNode();

  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final Listenable _allAnimations;

  late final Animation<double> _headerFade;
  late final Animation<double> _logoFade, _logoScale;
  late final Animation<double> _headFade, _headY;
  late final Animation<double> _field1Fade, _field1Y;
  late final Animation<double> _field2Fade, _field2Y;
  late final Animation<double> _btnFade, _btnY;
  late final Animation<double> _footFade;

  @override
  void initState() {
    super.initState();
    _buildAnimations();
    _mobileFocus.addListener(
        () => setState(() => _mobileHasFocus = _mobileFocus.hasFocus));
    _passwordFocus.addListener(
        () => setState(() => _passwordHasFocus = _passwordFocus.hasFocus));
  }

  void _buildAnimations() {
    _entryCtrl = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this)
      ..forward();
    _pulseCtrl = AnimationController(
        duration: const Duration(milliseconds: 2200), vsync: this)
      ..repeat(reverse: true);

    _allAnimations = Listenable.merge([_entryCtrl, _pulseCtrl]);

    _headerFade  = _iv(0.00, 0.35);
    _logoFade    = _iv(0.05, 0.40);
    _logoScale   = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(
        parent: _entryCtrl, curve: const Interval(0.05, 0.40, curve: Curves.elasticOut)));
    _headFade    = _iv(0.25, 0.55);
    _headY       = _slide(0.25, 0.55);
    _field1Fade  = _iv(0.38, 0.65);
    _field1Y     = _slide(0.38, 0.65);
    _field2Fade  = _iv(0.48, 0.74);
    _field2Y     = _slide(0.48, 0.74);
    _btnFade     = _iv(0.60, 0.85);
    _btnY        = _slide(0.60, 0.85);
    _footFade    = _iv(0.75, 1.00);
  }

  Animation<double> _iv(double b, double e) => CurvedAnimation(
      parent: _entryCtrl, curve: Interval(b, e, curve: Curves.easeOut));

  Animation<double> _slide(double b, double e) =>
      Tween<double>(begin: 24, end: 0).animate(CurvedAnimation(
          parent: _entryCtrl, curve: Interval(b, e, curve: Curves.easeOut)));

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _mobileCtrl.dispose();
    _passwordCtrl.dispose();
    _mobileFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    await auth.login(_mobileCtrl.text.trim(), _passwordCtrl.text.trim());
    if (!mounted) return;
    if (auth.isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    }
  }

  Widget _fade(Animation<double> fade, {required Widget child}) =>
      FadeTransition(opacity: fade, child: child);

  Widget _animated(Animation<double> fade, Animation<double>? slideY,
      {required Widget child}) {
    if (slideY != null) {
      return AnimatedBuilder(
        animation: slideY,
        builder: (_, __) => FadeTransition(
          opacity: fade,
          child: Transform.translate(
              offset: Offset(0, slideY.value), child: child),
        ),
      );
    }
    return FadeTransition(opacity: fade, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: _allAnimations,
        builder: (_, __) {
          return Column(
            children: [
              // ── Blue Header Block ───────────────────────────────────
              _fade(_headerFade, child: _buildHeader(size)),

              // ── Scrollable Body ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
                  child: Column(
                    children: [
                      // Card with proper margin instead of negative translate
                      const SizedBox(height: 16),
                      _buildFormCard(),
                      const SizedBox(height: 4),
                      _animated(_footFade, null, child: const _DividerRow()),
                      const SizedBox(height: 18),
                      _animated(_footFade, null,
                          child: _LinkRow(
                            prompt: "Don't have an account? ",
                            linkText: 'Create Account',
                            onTap: () => Navigator.pushNamed(context, '/register'),
                          )),
                      const SizedBox(height: 32),
                      _animated(_footFade, null, child: const _GovBadge()),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      height: size.height * 0.30,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.loginHeaderGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 20, left: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Tricolour top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: AppColors.tricolourGradient,
              ),
            ),
          ),
          // Logo + title
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: _LogoBadge(pulse: _pulseCtrl.value),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _fade(_logoFade,
                    child: const Text(
                      'LOKSEVA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _fade(_logoFade,
                    child: Text(
                      'Digital Citizen Services',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16), // Add top margin
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _animated(_headFade, _headY, child: const _Heading(
            title: 'Welcome Back',
            subtitle: 'Sign in to your LOKSEVA account',
          )),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _animated(_field1Fade, _field1Y,
                    child: _ProField(
                      controller: _mobileCtrl,
                      focusNode: _mobileFocus,
                      hasFocus: _mobileHasFocus,
                      label: 'Mobile Number',
                      hint: 'Enter 10-digit mobile number',
                      icon: Icons.smartphone_rounded,
                      keyboardType: TextInputType.phone,
                      nextFocus: _passwordFocus,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Mobile number is required';
                        final n = v.trim();
                        if (n.length < 10 || n.length > 15)
                          return 'Enter a valid mobile number (10–15 digits)';
                        if (!RegExp(r'^[0-9]+$').hasMatch(n))
                          return 'Only digits are allowed';
                        return null;
                      },
                    )),
                const SizedBox(height: 16),
                _animated(_field2Fade, _field2Y,
                    child: _ProField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      hasFocus: _passwordHasFocus,
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscure: _obscurePassword,
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Minimum 6 characters required';
                        return null;
                      },
                    )),
                const SizedBox(height: 10),
                _animated(_btnFade, _btnY,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 20),
                _animated(_btnFade, _btnY,
                    child: Consumer<AuthProvider>(
                      builder: (_, auth, __) => _PrimaryButton(
                        label: 'Sign In',
                        icon: Icons.login_rounded,
                        isLoading: auth.isLoading,
                        onTap: auth.isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _handleLogin(auth);
                                }
                              },
                      ),
                    )),
                Consumer<AuthProvider>(
                  builder: (_, auth, __) {
                    if (auth.error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _ErrorBanner(message: auth.error!),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reusable Widgets (unchanged from original)
// ═══════════════════════════════════════════════════════════════════════════

class _LogoBadge extends StatelessWidget {
  final double pulse;
  const _LogoBadge({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80, height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1.0 + pulse * 0.18,
            child: Opacity(
              opacity: (0.5 - pulse * 0.5).clamp(0.0, 1.0),
              child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.08,
                  child: CustomPaint(
                    size: const Size(48, 48),
                    painter: _AshokaWheelPainter(color: AppColors.primary),
                  ),
                ),
                Icon(Icons.account_balance_rounded,
                    size: 30, color: AppColors.primary),
              ],
            ),
          ),
          Positioned(
            top: 4, right: 4,
            child: Container(
              width: 14, height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [
                  Color(0xFFFF9933),
                  Colors.white,
                  Color(0xFF138808),
                  Color(0xFFFF9933),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String title, subtitle;
  const _Heading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ProField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasFocus;
  final String label, hint;
  final IconData icon;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FocusNode? nextFocus;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ProField({
    required this.controller,
    required this.focusNode,
    required this.hasFocus,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.nextFocus,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasFocus ? AppColors.primary : AppColors.borderLight;
    final iconColor   = hasFocus ? AppColors.primary : AppColors.grey400;
    final labelColor  = hasFocus ? AppColors.primary : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: hasFocus ? AppColors.white : AppColors.bgSurface,
            border: Border.all(
              color: borderColor,
              width: hasFocus ? 1.8 : 1.2,
            ),
            boxShadow: hasFocus ? AppColors.inputFocusShadow : [],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword && obscure,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLines: isPassword ? 1 : maxLines,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            onFieldSubmitted: (_) {
              if (nextFocus != null) {
                FocusScope.of(context).requestFocus(nextFocus);
              }
            },
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 48, minHeight: 52),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grey400,
                        size: 20,
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 14 : 16,
              ),
              errorStyle: const TextStyle(
                color: AppColors.error,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: onTap != null
              ? AppColors.primaryGradient
              : LinearGradient(colors: [
                  AppColors.grey300,
                  AppColors.grey300,
                ]),
          boxShadow: onTap != null ? AppColors.buttonShadow : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.errorLight,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerRow extends StatelessWidget {
  const _DividerRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppColors.borderLight),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.grey400,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: AppColors.borderLight),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String prompt, linkText;
  final VoidCallback onTap;
  const _LinkRow(
      {required this.prompt, required this.linkText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: prompt,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        children: [
          TextSpan(
            text: linkText,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
    );
  }
}

class _GovBadge extends StatelessWidget {
  const _GovBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.saffron.withValues(alpha: 0.4)),
            color: AppColors.saffron.withValues(alpha: 0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_florist_rounded,
                  size: 12,
                  color: AppColors.saffron.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                'A BJP Initiative',
                style: TextStyle(
                  color: AppColors.saffron.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Powered by Qubixa Technologies',
          style: TextStyle(
            color: AppColors.textDisabled,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'LOKSEVA · Secure Government Portal',
          style: TextStyle(
            color: AppColors.textDisabled,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _AshokaWheelPainter extends CustomPainter {
  final Color color;
  const _AshokaWheelPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paint);
    for (int i = 0; i < 24; i++) {
      final angle = (i * 2 * math.pi) / 24;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}