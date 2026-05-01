import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/services_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LOKSEVA — Register Screen · 2026
//  Umang-inspired professional light theme
//  High-contrast fields · Accessible · Sectioned clean form
// ─────────────────────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int?  _selectedWardId;
  bool  _obscurePassword = true;
  bool  _obscureConfirm  = true;

  final _nameFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _phoneFocus   = FocusNode();
  final _addressFocus = FocusNode();
  final _passFocus    = FocusNode();
  final _confirmFocus = FocusNode();

  bool _nameFocused = false, _emailFocused = false, _phoneFocused = false,
       _addressFocused = false, _passFocused = false, _confirmFocused = false;

  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final Listenable _allAnimations;

  late final Animation<double> _headerFade, _logoFade, _logoScale;
  late final Animation<double> _headFade, _headY;
  late final Animation<double> _formFade, _formY;
  late final Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();
    _buildAnimations();
    _attachFocusListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicesProvider>().fetchWards();
    });
  }

  void _buildAnimations() {
    _entryCtrl = AnimationController(
        duration: const Duration(milliseconds: 1100), vsync: this)
      ..forward();
    _pulseCtrl = AnimationController(
        duration: const Duration(milliseconds: 2400), vsync: this)
      ..repeat(reverse: true);
    _allAnimations = Listenable.merge([_entryCtrl, _pulseCtrl]);

    _headerFade = _iv(0.00, 0.35);
    _logoFade   = _iv(0.05, 0.40);
    _logoScale  = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(
        parent: _entryCtrl, curve: const Interval(0.05, 0.40, curve: Curves.elasticOut)));
    _headFade   = _iv(0.25, 0.55);
    _headY      = _slide(0.25, 0.55);
    _formFade   = _iv(0.40, 0.75);
    _formY      = _slide(0.40, 0.75);
    _btnFade    = _iv(0.65, 1.00);
  }

  Animation<double> _iv(double b, double e) => CurvedAnimation(
      parent: _entryCtrl, curve: Interval(b, e, curve: Curves.easeOut));

  Animation<double> _slide(double b, double e) =>
      Tween<double>(begin: 24, end: 0).animate(CurvedAnimation(
          parent: _entryCtrl, curve: Interval(b, e, curve: Curves.easeOut)));

  void _attachFocusListeners() {
    _nameFocus.addListener(
        () => setState(() => _nameFocused = _nameFocus.hasFocus));
    _emailFocus.addListener(
        () => setState(() => _emailFocused = _emailFocus.hasFocus));
    _phoneFocus.addListener(
        () => setState(() => _phoneFocused = _phoneFocus.hasFocus));
    _addressFocus.addListener(
        () => setState(() => _addressFocused = _addressFocus.hasFocus));
    _passFocus.addListener(
        () => setState(() => _passFocused = _passFocus.hasFocus));
    _confirmFocus.addListener(
        () => setState(() => _confirmFocused = _confirmFocus.hasFocus));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    for (final c in [
      _nameCtrl, _emailCtrl, _phoneCtrl,
      _passwordCtrl, _confirmCtrl, _addressCtrl
    ]) { c.dispose(); }
    for (final f in [
      _nameFocus, _emailFocus, _phoneFocus,
      _addressFocus, _passFocus, _confirmFocus
    ]) { f.dispose(); }
    super.dispose();
  }

  Future<void> _handleRegister(AuthProvider auth) async {
    if (_selectedWardId == null) {
      _showSnack('Please select your ward', isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    final success = await auth.register(
      name: _nameCtrl.text.trim(),
      mobile: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
      wardId: _selectedWardId!,
      address: _addressCtrl.text.trim(),
      email: _emailCtrl.text.trim().isNotEmpty
          ? _emailCtrl.text.trim() : null,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
              // ── Blue Header Block ─────────────────────────────────
              _fade(_headerFade, child: _buildHeader(size)),

              // ── Scrollable Body ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 32),
                  child: Column(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -28),
                        child: Column(
                          children: [
                            _animated(_headFade, _headY,
                                child: _buildHeadingCard()),
                            const SizedBox(height: 16),
                            _animated(_formFade, _formY,
                                child: _buildSection(
                                  label: 'Personal Information',
                                  icon: Icons.person_outline_rounded,
                                  child: _buildPersonalFields(),
                                )),
                            const SizedBox(height: 16),
                            _animated(_formFade, _formY,
                                child: _buildSection(
                                  label: 'Location Details',
                                  icon: Icons.location_on_outlined,
                                  child: _buildLocationFields(),
                                )),
                            const SizedBox(height: 16),
                            _animated(_formFade, _formY,
                                child: _buildSection(
                                  label: 'Secure Access',
                                  icon: Icons.security_rounded,
                                  child: _buildPasswordFields(),
                                )),
                            const SizedBox(height: 24),
                            _animated(_btnFade, null,
                                child: Consumer<AuthProvider>(
                                  builder: (_, auth, __) => _PrimaryButton(
                                    label: 'Create Account',
                                    icon: Icons.how_to_reg_rounded,
                                    isLoading: auth.isLoading,
                                    onTap: auth.isLoading
                                        ? null
                                        : () {
                                            if (_formKey.currentState!.validate()) {
                                              _handleRegister(auth);
                                            }
                                          },
                                  ),
                                )),
                            Consumer<AuthProvider>(
                              builder: (_, auth, __) {
                                if (auth.error == null)
                                  return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: _ErrorBanner(message: auth.error!),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            _animated(_btnFade, null,
                                child: _LinkRow(
                                  prompt: 'Already have an account? ',
                                  linkText: 'Sign In',
                                  onTap: () => Navigator.pop(context),
                                )),
                            const SizedBox(height: 24),
                            _animated(_btnFade, null, child: const _GovBadge()),
                          ],
                        ),
                      ),
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
      height: size.height * 0.22,
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
          Positioned(top: -40, right: -40,
            child: Container(width: 140, height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05)))),
          // Tricolour top bar
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 3,
              decoration: const BoxDecoration(
                  gradient: AppColors.tricolourGradient))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const Spacer(),
                  // Logo + title centered
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                              )],
                            ),
                            child: const Icon(Icons.account_balance_rounded,
                                size: 26, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _fade(_logoFade, child: const Text(
                        'LOKSEVA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                        ),
                      )),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 40), // balance
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Create Your Account',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Join LOKSEVA — Digital Citizen Services',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Step indicator
          _StepIndicator(),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Section fields
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _ProField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            hasFocus: _nameFocused,
            label: 'Full Name *',
            hint: 'Enter your complete name',
            icon: Icons.badge_outlined,
            nextFocus: _phoneFocus,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Full name is required';
              if (v.length < 2) return 'At least 2 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _ProField(
            controller: _phoneCtrl,
            focusNode: _phoneFocus,
            hasFocus: _phoneFocused,
            label: 'Mobile Number *',
            hint: 'Enter 10-digit mobile number',
            icon: Icons.smartphone_rounded,
            keyboardType: TextInputType.phone,
            nextFocus: _emailFocus,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mobile number is required';
              final n = v.trim();
              if (n.length != 10) return 'Enter a valid 10-digit number';
              if (!RegExp(r'^[0-9]+$').hasMatch(n))
                return 'Only digits are allowed';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _ProField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            hasFocus: _emailFocused,
            label: 'Email Address (Optional)',
            hint: 'your@email.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            nextFocus: _addressFocus,
            validator: (v) {
              if (v != null && v.isNotEmpty) {
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                  return 'Invalid email format';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationFields() {
    return Column(
      children: [
        Consumer<ServicesProvider>(
          builder: (_, sp, __) => _WardDropdown(
            provider: sp,
            selectedId: _selectedWardId,
            onChanged: (v) => setState(() => _selectedWardId = v),
          ),
        ),
        const SizedBox(height: 14),
        _ProField(
          controller: _addressCtrl,
          focusNode: _addressFocus,
          hasFocus: _addressFocused,
          label: 'Full Address *',
          hint: 'House no., street, landmark…',
          icon: Icons.home_outlined,
          maxLines: 3,
          nextFocus: _passFocus,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Address is required';
            if (v.length < 10) return 'Please enter your complete address';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        _ProField(
          controller: _passwordCtrl,
          focusNode: _passFocus,
          hasFocus: _passFocused,
          label: 'Password *',
          hint: 'Minimum 6 characters',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscure: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          nextFocus: _confirmFocus,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 6) return 'Minimum 6 characters required';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _ProField(
          controller: _confirmCtrl,
          focusNode: _confirmFocus,
          hasFocus: _confirmFocused,
          label: 'Confirm Password *',
          hint: 'Re-enter your password',
          icon: Icons.lock_reset_outlined,
          isPassword: true,
          obscure: _obscureConfirm,
          onToggleObscure: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          textInputAction: TextInputAction.done,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != _passwordCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Register-specific widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(true),
        _line(),
        _dot(true),
        _line(),
        _dot(false),
      ],
    );
  }

  Widget _dot(bool active) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.primary : AppColors.borderDefault,
        ),
      );

  Widget _line() => Container(
        width: 20, height: 2,
        color: AppColors.primary.withValues(alpha: 0.3),
        margin: const EdgeInsets.symmetric(horizontal: 3),
      );
}

class _WardDropdown extends StatelessWidget {
  final ServicesProvider provider;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const _WardDropdown({
    required this.provider,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            'Ward *',
            style: TextStyle(
              color: AppColors.textSecondary,
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
            color: AppColors.bgSurface,
            border: Border.all(color: AppColors.borderLight, width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: provider.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                )
              : provider.wards.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No wards available at this time',
                        style: TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        dropdownColor: AppColors.white,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        hint: const Text(
                          'Select your ward',
                          style: TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 14,
                          ),
                        ),
                        value: selectedId,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.grey400,
                        ),
                        items: provider.wards.map((ward) {
                          return DropdownMenuItem<int>(
                            value: ward.id,
                            child: Text(ward.name),
                          );
                        }).toList(),
                        onChanged: onChanged,
                      ),
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared Widgets (same as Login but exported for reuse)
// ─────────────────────────────────────────────────────────────────────────────

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
            border: Border.all(color: borderColor, width: hasFocus ? 1.8 : 1.2),
            boxShadow: hasFocus ? AppColors.inputFocusShadow : [],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword && obscure,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLines: isPassword ? 1 : maxLines,
            // Dark text — always visible on light field background
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
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: onTap != null
              ? AppColors.primaryGradient
              : LinearGradient(colors: [AppColors.grey300, AppColors.grey300]),
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
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
        const Text('Powered by Qubixa Technologies',
            style: TextStyle(
                color: AppColors.textDisabled, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 3),
        const Text('LOKSEVA · Secure Government Portal',
            style: TextStyle(
                color: AppColors.textDisabled,
                fontSize: 10,
                letterSpacing: 1.5)),
      ],
    );
  }
}