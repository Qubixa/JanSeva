import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/matrimonial_provider.dart';
import 'widgets/notifications_scrollable.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LOKSEVA — Home Screen · 2026
//  Umang-inspired professional layout
//  Clean cards · Accessible · Government-grade UI
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this)
      ..forward();
    _fade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _slide = Tween<Offset>(
        begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatrimonialProvider>().getDashboardStats();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar — Government Blue Header ──────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
            actions: [
              IconButton(
                tooltip: 'My Profile',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
              IconButton(
                tooltip: 'Logout',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 20),
                ),
                onPressed: () => _showLogoutDialog(context),
              ),
              const SizedBox(width: 6),
            ],
          ),

          // ── Body Content ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding:
                      EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Quick Stats Row ─────────────────────────
                      _buildStatsRow(),
                      const SizedBox(height: 24),

                      // ── Quick Actions ───────────────────────────
                      _SectionHeader(
                          title: 'Quick Actions',
                          subtitle: 'Citizen services at your fingertips'),
                      const SizedBox(height: 14),
                      _buildServicesGrid(isMobile),
                      const SizedBox(height: 24),

                      // ── Live Notifications ──────────────────────
                      _SectionHeader(
                          title: 'Live Notifications',
                          subtitle: 'Important municipal updates'),
                      const SizedBox(height: 14),
                      const NotificationsScrollable(),
                      const SizedBox(height: 24),

                      // ── Matrimonial Spotlight ───────────────────
                      _buildMatrimonialSection(),
                      const SizedBox(height: 24),

                      // ── Complaint Stats ─────────────────────────
                      _SectionHeader(
                          title: 'My Activity',
                          subtitle: 'Overview of your complaints & activity'),
                      const SizedBox(height: 14),
                      _buildActivityCards(),
                      const SizedBox(height: 24),

                      // ── About ───────────────────────────────────
                      _buildAboutCard(),
                      const SizedBox(height: 28),

                      // ── Footer ──────────────────────────────────
                      _buildFooter(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Header
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50, right: -50,
            child: Container(width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05))),
          ),
          Positioned(
            bottom: -30, left: -30,
            child: Container(width: 150, height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04))),
          ),
          // Tricolour top bar
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 3,
              decoration: const BoxDecoration(
                  gradient: AppColors.tricolourGradient))),
          // Greeting
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Consumer<AuthProvider>(
                builder: (_, auth, __) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        auth.user?.name ?? 'Citizen',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _HeaderChip(
                            icon: Icons.verified_user_rounded,
                            label: 'NMMC Verified Citizen',
                          ),
                          const SizedBox(width: 8),
                          _HeaderChip(
                            icon: Icons.location_city_rounded,
                            label: auth.user?.wardName ?? 'Ward',
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Stats Row
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Consumer<MatrimonialProvider>(
      builder: (_, provider, __) {
        return Row(
          children: [
            _StatCard(
              icon: Icons.pending_actions_rounded,
              label: 'Active\nComplaints',
              value: '12',
              color: AppColors.warning,
              bgColor: AppColors.warningBg,
            ),
            const SizedBox(width: 12),
            _StatCard(
              icon: Icons.check_circle_outline_rounded,
              label: 'Resolved\nComplaints',
              value: '45',
              color: AppColors.success,
              bgColor: AppColors.successBg,
            ),
            const SizedBox(width: 12),
            _StatCard(
              icon: Icons.favorite_border_rounded,
              label: 'Matrimonial\nMatches',
              value: provider.totalProfiles.toString(),
              color: const Color(0xFFD81B60),
              bgColor: const Color(0xFFFCE4EC),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Services Grid
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildServicesGrid(bool isMobile) {
    final services = [
      _ServiceItem(
        icon: Icons.emergency_rounded,
        label: 'Emergency\nServices',
        sublabel: 'आपत्कालीन सेवा',
        color: AppColors.error,
        route: '/emergency-services',
      ),
      _ServiceItem(
        icon: Icons.edit_note_rounded,
        label: 'File a\nComplaint',
        sublabel: 'तक्रार नोंदवा',
        color: AppColors.warning,
        route: '/file-complaint',
      ),
      _ServiceItem(
        icon: Icons.track_changes_rounded,
        label: 'Track\nComplaint',
        sublabel: 'तक्रार ट्रॅक करा',
        color: AppColors.info,
        route: '/track-complaint',
      ),
      _ServiceItem(
        icon: Icons.card_giftcard_rounded,
        label: 'Government\nSchemes',
        sublabel: 'सरकारी योजना',
        color: AppColors.success,
        route: '/schemes',
      ),
      _ServiceItem(
        icon: Icons.directions_bus_rounded,
        label: 'Transport\nInfo',
        sublabel: 'वाहतूक माहिती',
        color: const Color(0xFF7B1FA2),
        route: '/transport',
      ),
      _ServiceItem(
        icon: Icons.favorite_rounded,
        label: 'Matrimonial\nServices',
        sublabel: 'विवाह सेवा',
        color: const Color(0xFFD81B60),
        route: '/matrimonial',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 3 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: services.length,
      itemBuilder: (context, i) {
        final s = services[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 250 + i * 70),
          curve: Curves.easeOutBack,
          builder: (_, v, child) =>
              Transform.scale(scale: v, child: Opacity(opacity: v.clamp(0, 1), child: child)),
          child: _ServiceCard(item: s, onTap: () => Navigator.pushNamed(context, s.route)),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Matrimonial Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMatrimonialSection() {
    return Consumer<MatrimonialProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SectionHeader(
                    title: 'Matrimonial Spotlight',
                    subtitle: 'Verified profiles from NMMC area',
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/matrimonial'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All →',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (provider.isLoading)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (provider.recentProfiles.isNotEmpty)
              SizedBox(
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.recentProfiles.length > 5 ? 5 : provider.recentProfiles.length,
                  itemBuilder: (context, i) {
                    final p = provider.recentProfiles[i];
                    return Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 12),
                      child: _MatrimonialCard(profile: p),
                    );
                  },
                ),
              )
            else
              _MatrimonialCTA(),
          ],
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Activity Cards
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildActivityCards() {
    return Row(
      children: [
        Expanded(
          child: _ActivityTile(
            icon: Icons.assignment_outlined,
            title: 'My Complaints',
            subtitle: 'View & track all filed complaints',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/track-complaint'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActivityTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Municipal alerts & updates',
            color: AppColors.accent,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  About Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'About LOKSEVA',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'LOKSEVA is your comprehensive digital gateway to all NMMC citizen services. File complaints, access emergency assistance, explore government schemes, and connect through our matrimonial registry — all in one secure, government-backed platform.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: const [
              _FeatureChip(label: '24/7 Support',   icon: Icons.support_agent_rounded),
              _FeatureChip(label: 'Rapid Response', icon: Icons.flash_on_rounded),
              _FeatureChip(label: 'Secure Portal',  icon: Icons.security_rounded),
              _FeatureChip(label: 'Matrimonial',    icon: Icons.favorite_rounded),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Footer
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: AppColors.borderLight,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                'A BJP Initiative · Powered by Qubixa Technologies',
                style: TextStyle(
                  color: AppColors.saffron.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Dialogs
  // ───────────────────────────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Confirm Logout',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your LOKSEVA account?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Sub-Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4, height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                )),
              const SizedBox(height: 2),
              Text(subtitle,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12.5,
                )),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, bgColor;
  const _StatCard({
    required this.icon, required this.label,
    required this.value, required this.color, required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              )),
            const SizedBox(height: 4),
            Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10.5,
                height: 1.3,
              )),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String label, sublabel, route;
  final Color color;
  const _ServiceItem({
    required this.icon, required this.label, required this.sublabel,
    required this.color, required this.route,
  });
}

class _ServiceCard extends StatelessWidget {
  final _ServiceItem item;
  final VoidCallback onTap;
  const _ServiceCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.sublabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatrimonialCard extends StatelessWidget {
  final MatrimonialProfile profile;
  const _MatrimonialCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/matrimonial/profile/${profile.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                  ? Image.network(profile.photoUrl!,
                      height: 150, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name ?? 'Anonymous',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile.profession != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.work_outline_rounded,
                          size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(profile.profession!,
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                  if (profile.isVerified) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 11, color: AppColors.success),
                          SizedBox(width: 3),
                          Text('Verified',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 150,
    color: const Color(0xFFFCE4EC),
    child: const Center(
      child: Icon(Icons.person_rounded, size: 50, color: Color(0xFFD81B60)),
    ),
  );
}

class _MatrimonialCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(
            color: const Color(0xFFD81B60).withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD81B60).withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.favorite_border_rounded,
                size: 40, color: Color(0xFFD81B60)),
          ),
          const SizedBox(height: 14),
          const Text('Find Your Life Partner',
            style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            )),
          const SizedBox(height: 8),
          const Text(
            'Register now to connect with verified profiles\nfrom the NMMC community.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
                context, '/matrimonial/user-register'),
            icon: const Icon(Icons.favorite_rounded, size: 18),
            label: const Text('Register Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD81B60),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActivityTile({
    required this.icon, required this.title,
    required this.subtitle, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              )),
            const SizedBox(height: 3),
            Text(subtitle,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11.5,
                height: 1.4,
              )),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FeatureChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
        ],
      ),
    );
  }
}