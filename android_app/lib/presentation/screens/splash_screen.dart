import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LOKSEVA · Splash Screen
//  FIX: Added rebuild prevention flags and navigation safeguards
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _masterCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _bgCtrl;
  Size? _cachedSize;

  late final Listenable _allAnimations;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoY;
  late final Animation<double> _taglineFade;
  late final Animation<double> _taglineY;
  late final Animation<double> _progressWidth;
  late final Animation<double> _shimmer;
  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring1Fade;
  late final Animation<double> _ring2Scale;
  late final Animation<double> _ring2Fade;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _buildAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startFlow();
    });
  }

  void _buildAnimations() {
    _masterCtrl = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    _logoFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.00, 0.35, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.00, 0.45, curve: Curves.elasticOut),
      ),
    );
    _logoY = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.00, 0.40, curve: Curves.easeOut),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.45, 0.70, curve: Curves.easeOut),
    );
    _taglineY = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.45, 0.70, curve: Curves.easeOut),
      ),
    );
    _progressWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.55, 1.00, curve: Curves.easeInOut),
      ),
    );

    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _ringCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _ring1Scale = Tween<double>(begin: 0.85, end: 1.6).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.00, 0.70, curve: Curves.easeOut),
      ),
    );
    _ring1Fade = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.00, 0.70, curve: Curves.easeOut),
      ),
    );
    _ring2Scale = Tween<double>(begin: 0.85, end: 1.6).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.30, 1.00, curve: Curves.easeOut),
      ),
    );
    _ring2Fade = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.30, 1.00, curve: Curves.easeOut),
      ),
    );

    _bgCtrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _allAnimations = Listenable.merge([
      _masterCtrl,
      _ringCtrl,
      _shimmerCtrl,
      _bgCtrl,
    ]);

    _masterCtrl.forward();
  }

  Future<void> _startFlow() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    await _showAnnouncements();
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isNavigating) {
        _isNavigating = true;
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final route = auth.isAuthenticated ? '/home' : '/login';
        Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
      }
    });
  }

  Future<void> _showAnnouncements() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => const _AnnouncementOverlay(),
    );
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _shimmerCtrl.dispose();
    _ringCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: AnimatedBuilder(
        animation: _allAnimations,
        builder: (context, _) => _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    _cachedSize ??= MediaQuery.of(context).size;
    final size = _cachedSize!;
    
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        ),
        _buildBgOrb(size,
            dx: -120 + (_bgCtrl.value * 60),
            dy: -120 + (_bgCtrl.value * 40),
            radius: 300,
            color: AppColors.alpha(AppColors.primary, 0.08)),
        _buildBgOrb(size,
            dx: size.width -
                160 +
                (math.sin(_bgCtrl.value * math.pi) * 50),
            dy: size.height - 200 + (_bgCtrl.value * 30),
            radius: 260,
            color: AppColors.alpha(AppColors.secondary, 0.06)),
        _buildBgOrb(size,
            dx: size.width / 2 -
                50 +
                (math.cos(_bgCtrl.value * math.pi) * 40),
            dy: size.height * 0.35,
            radius: 180,
            color: AppColors.alpha(AppColors.primary, 0.05)),
        CustomPaint(
          size: size,
          painter: _GridPainter(progress: _masterCtrl.value),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
                gradient: AppColors.tricolourGradient),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: Offset(0, _logoY.value),
                child: FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: _LogoCluster(
                      ring1Scale: _ring1Scale.value,
                      ring1Fade: _ring1Fade.value,
                      ring2Scale: _ring2Scale.value,
                      ring2Fade: _ring2Fade.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Transform.translate(
                offset: Offset(0, _logoY.value),
                child: FadeTransition(
                  opacity: _logoFade,
                  child: _AppNameText(shimmer: _shimmer.value),
                ),
              ),
              const SizedBox(height: 14),
              Transform.translate(
                offset: Offset(0, _taglineY.value),
                child: FadeTransition(
                  opacity: _taglineFade,
                  child: const _TaglineWidget(),
                ),
              ),
              const SizedBox(height: 64),
              FadeTransition(
                opacity: _taglineFade,
                child: _ProgressBar(
                  width: _progressWidth.value,
                  shimmer: _shimmer.value,
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _taglineFade,
                child: Text(
                  'Initialising secure session…',
                  style: TextStyle(
                    color: AppColors.alpha(Colors.white, 0.38),
                    fontSize: 12,
                    letterSpacing: 0.8,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _taglineFade,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.alpha(AppColors.saffron, 0.4)),
                        color: AppColors.alpha(AppColors.saffron, 0.08),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_florist_rounded,
                              size: 12,
                              color: AppColors.alpha(AppColors.saffron, 0.8)),
                          const SizedBox(width: 6),
                          Text(
                            'A BJP Initiative',
                            style: TextStyle(
                              color: AppColors.alpha(AppColors.saffron, 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 40,
                        height: 1,
                        color: AppColors.alpha(Colors.white, 0.12)),
                    const SizedBox(width: 10),
                    Text(
                      'Powered by Qubixa Technologies',
                      style: TextStyle(
                        color: AppColors.alpha(Colors.white, 0.28),
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                        width: 40,
                        height: 1,
                        color: AppColors.alpha(Colors.white, 0.12)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'LOKSEVA v2.0',
                  style: TextStyle(
                    color: AppColors.alpha(Colors.white, 0.18),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBgOrb(Size size,
      {required double dx,
      required double dy,
      required double radius,
      required Color color}) {
    return Positioned(
      left: dx,
      top: dy,
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Logo Cluster
// ─────────────────────────────────────────────────────────────────────────────
class _LogoCluster extends StatelessWidget {
  final double ring1Scale, ring1Fade, ring2Scale, ring2Fade;
  const _LogoCluster({
    required this.ring1Scale,
    required this.ring1Fade,
    required this.ring2Scale,
    required this.ring2Fade,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: ring2Scale,
            child: Opacity(
              opacity: ring2Fade.clamp(0, 1),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.alpha(AppColors.primary, 0.6),
                      width: 1.5),
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: ring1Scale,
            child: Opacity(
              opacity: ring1Fade.clamp(0, 1),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.alpha(AppColors.secondary, 0.5),
                      width: 1.5),
                ),
              ),
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.logoGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.alpha(AppColors.primary, 0.5),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: AppColors.alpha(Colors.black, 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.12,
                  child: CustomPaint(
                    size: const Size(80, 80),
                    painter: _AshokaWheelPainter(),
                  ),
                ),
                const Icon(Icons.account_balance_rounded,
                    size: 52, color: Colors.white),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [
                  Color(0xFFFF9933),
                  Color(0xFFFFFFFF),
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

// ─────────────────────────────────────────────────────────────────────────────
//  App name shimmer
// ─────────────────────────────────────────────────────────────────────────────
class _AppNameText extends StatelessWidget {
  final double shimmer;
  const _AppNameText({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          AppColors.shimmerGradient(shimmer).createShader(bounds),
      child: const Text(
        'LOKSEVA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: 8,
          height: 1.0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tagline pill
// ─────────────────────────────────────────────────────────────────────────────
class _TaglineWidget extends StatelessWidget {
  const _TaglineWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        color: AppColors.glass05,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded,
              size: 14, color: AppColors.alpha(AppColors.secondary, 0.8)),
          const SizedBox(width: 8),
          Text(
            'Citizen Services · One Click Away',
            style: TextStyle(
              color: AppColors.alpha(Colors.white, 0.65),
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Progress bar
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double width;
  final double shimmer;
  const _ProgressBar({required this.width, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            Container(
              height: 3,
              width: 200,
              color: AppColors.alpha(Colors.white, 0.1),
            ),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.progressGradient(shimmer).createShader(bounds),
              child:
                  Container(height: 3, width: 200 * width, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Painters
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final double progress;
  _GridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.3) return;
    final opacity = ((progress - 0.3) / 0.4).clamp(0.0, 1.0) * 0.06;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 0.5;
    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.progress != progress;
}

class _AshokaWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
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
  bool shouldRepaint(_AshokaWheelPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Announcement Overlay
// ─────────────────────────────────────────────────────────────────────────────
class _AnnouncementOverlay extends StatefulWidget {
  const _AnnouncementOverlay();

  @override
  State<_AnnouncementOverlay> createState() => _AnnouncementOverlayState();
}

class _AnnouncementOverlayState extends State<_AnnouncementOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  static const int _totalPages = 2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Container(
            width: double.infinity,
            height: size.height * 0.82,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.alpha(AppColors.primary, 0.3),
                  blurRadius: 60,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(colors: [
                      AppColors.alpha(AppColors.primary, 0.2),
                      AppColors.alpha(AppColors.secondary, 0.1),
                    ]),
                    border: Border(
                      bottom: BorderSide(
                          color: AppColors.alpha(Colors.white, 0.08)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.alpha(AppColors.warning, 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.campaign_rounded,
                            color: AppColors.warning, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Announcements',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Swipe to view all notices',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.glass08,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentPage + 1} / $_totalPages',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.glass08,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              color: AppColors.textTertiary, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: const [
                      _AnnouncementPage(
                        imagePath: 'assets/images/announcement_banner.jpeg',
                        title: 'जयंती महापुरुषांची',
                        subtitle: 'Sector 4, Airoli',
                        dateLabel: '02–03 May 2026',
                        badgeLabel: 'EVENT',
                        badgeColor: AppColors.accent,
                        icon: Icons.event_rounded,
                        iconColor: AppColors.accent,
                        titleColor: Colors.white, 
                      ),
                      _AnnouncementPage(
                        imagePath: 'assets/images/announcement_person.jpeg',
                        title: 'A BJP Initiative',
                        subtitle:
                            'LOKSEVA App · Powered by Qubixa',
                        dateLabel: 'Comming Soon',
                        badgeLabel: 'INITIATIVE',
                        badgeColor: AppColors.saffron,
                        icon: Icons.volunteer_activism_rounded,
                        iconColor: AppColors.saffron,
                        titleColor: Colors.white, 
                        descriptionLines: [
                          'Championed by our dedicated Karyakarta network',
                          'Developed in partnership with Qubixa',
                          'Bringing digital citizen services to every doorstep',
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.alpha(Colors.white, 0.07)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Row(
                        children: List.generate(_totalPages, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 6),
                            width: active ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: active
                                  ? AppColors.primary
                                  : AppColors.alpha(Colors.white, 0.2),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _next,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: AppColors.primaryGradient,
                            boxShadow: AppColors.buttonShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage < _totalPages - 1
                                    ? 'Next'
                                    : 'Continue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _currentPage < _totalPages - 1
                                    ? Icons.arrow_forward_rounded
                                    : Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Single Announcement Page
// ─────────────────────────────────────────────────────────────────────────────
class _AnnouncementPage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final String dateLabel;
  final String badgeLabel;
  final Color badgeColor;
  final IconData icon;
  final Color iconColor;
  final List<String> descriptionLines;
  final Color? titleColor; // Add this new parameter

  const _AnnouncementPage({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.badgeLabel,
    required this.badgeColor,
    required this.icon,
    required this.iconColor,
    this.descriptionLines = const [],
    this.titleColor, // Make it optional
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: titleColor ?? AppColors.textPrimary, // Use titleColor or default
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.alpha(iconColor, 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.glass08,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 10, color: AppColors.alpha(Colors.white, 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: AppColors.alpha(Colors.white, 0.65),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.asset(
                  imagePath,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.alpha(Colors.white, 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: iconColor, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            'Image unavailable',
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xCC0A1628), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (descriptionLines.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.glass05,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: descriptionLines
                    .map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Icon(
                                Icons.fiber_manual_record_rounded,
                                size: 6,
                                color: AppColors.alpha(iconColor, 0.7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                line,
                                style: TextStyle(
                                  color: AppColors.alpha(Colors.white, 0.65),
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}