// lib/presentation/screens/complaint/complaint_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/providers/complaint_provider.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final int complaintId;

  const ComplaintDetailScreen({Key? key, required this.complaintId})
      : super(key: key);

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplaintProvider>().fetchComplaintDetails(widget.complaintId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Status helpers ────────────────────────────────────────────────────────

  static Color statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFF9800);
      case 'ASSIGNED':
        return const Color(0xFF2196F3);
      case 'IN_PROGRESS':
        return const Color(0xFF00BCD4);
      case 'RESOLVED':
        return const Color(0xFF4CAF50);
      case 'REJECTED':
        return AppColors.error;
      case 'CLOSED':
        return AppColors.grey400;
      default:
        return AppColors.grey400;
    }
  }

  static IconData statusIcon(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return Icons.hourglass_empty_rounded;
      case 'ASSIGNED':
        return Icons.person_pin_rounded;
      case 'IN_PROGRESS':
        return Icons.sync_rounded;
      case 'RESOLVED':
        return Icons.check_circle_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      case 'CLOSED':
        return Icons.lock_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintProvider>(
      builder: (_, provider, __) {
        final complaint = provider.selectedComplaint;

        if (provider.isLoading && complaint == null) {
          return Scaffold(
            backgroundColor: AppColors.grey100,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00BCD4)),
                  const SizedBox(height: 16),
                  Text('Loading complaint…',
                      style:
                          TextStyle(color: AppColors.grey500, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        if (complaint == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Complaint Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.grey300),
                  const SizedBox(height: 16),
                  Text(provider.error ?? 'Complaint not found.',
                      style: const TextStyle(color: AppColors.grey700)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final color = statusColor(complaint.status);

        return Scaffold(
          backgroundColor: AppColors.grey100,
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              _buildAppBar(complaint, color),
              _buildTabBar(color),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _DetailsTab(complaint: complaint, provider: provider),
                _TimelineTab(logs: provider.complaintLogs),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(Complaint complaint, Color color) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: color,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_rounded,
                color: Colors.white, size: 20),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Gradient bg
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.75)],
                ),
              ),
            ),
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(statusIcon(complaint.status),
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  complaint.getStatusDisplay(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '#${complaint.complaintNumber.isNotEmpty ? complaint.complaintNumber : complaint.id}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      complaint.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            complaint.wardName ?? 'N/A',
                            style:
                                TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(Color color) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: color,
          unselectedLabelColor: AppColors.grey500,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          indicatorColor: color,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'Details'),
            Tab(icon: Icon(Icons.timeline_rounded, size: 18), text: 'Activity'),
          ],
        ),
        color: Colors.white,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DETAILS TAB
// ═══════════════════════════════════════════════════════════════════════════

class _DetailsTab extends StatefulWidget {
  final Complaint complaint;
  final ComplaintProvider provider;

  const _DetailsTab({required this.complaint, required this.provider});

  @override
  State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
  int _feedbackRating = 0;
  final _feedbackCtrl = TextEditingController();

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_feedbackRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating first.')),
      );
      return;
    }

    final success = await widget.provider.submitFeedback(
      complaintId: widget.complaint.id,
      rating: _feedbackRating,
      feedback: _feedbackCtrl.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('Feedback submitted. Thank you!'),
          ]),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final fmt = DateFormat('d MMM yyyy, h:mm a');

    return RefreshIndicator(
      onRefresh: () =>
          widget.provider.fetchComplaintDetails(c.id),
      color: _ComplaintDetailScreenState.statusColor(c.status),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Info cards ──────────────────────────────────────────────────
          _InfoCard(children: [
            _InfoRow(Icons.category_rounded, 'Category',
                c.categoryInfo?.name ?? c.category),
            _InfoRow(Icons.flag_rounded, 'Priority', c.getPriorityDisplay()),
            _InfoRow(Icons.location_city_rounded, 'Ward', c.wardName ?? 'N/A'),
            if (c.assignedOfficerName != null)
              _InfoRow(Icons.person_rounded, 'Assigned Officer',
                  c.assignedOfficerName!),
          ]),
          const SizedBox(height: 12),

          _SectionTitle('Description'),
          _ContentCard(child: Text(c.description,
              style: const TextStyle(
                  color: AppColors.grey900, height: 1.6, fontSize: 13))),

          const SizedBox(height: 12),
          _SectionTitle('Location'),
          _ContentCard(
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.grey400, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.address,
                      style: const TextStyle(
                          color: AppColors.grey700, fontSize: 13)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _InfoCard(children: [
            _InfoRow(Icons.calendar_today_outlined, 'Filed On',
                fmt.format(c.createdAt)),
            if (c.resolvedAt != null)
              _InfoRow(Icons.event_available_rounded, 'Resolved On',
                  fmt.format(c.resolvedAt!)),
          ]),

          // ── Resolution notes ────────────────────────────────────────────
          if (c.resolvedNotes != null) ...[
            const SizedBox(height: 16),
            _SectionTitle('Resolution Notes'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF4CAF50), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(c.resolvedNotes!,
                        style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            height: 1.5,
                            fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          // ── Photo gallery ───────────────────────────────────────────────
          if (c.media.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle('Photos (${c.media.length})'),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: c.media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final media = c.media[i];
                  return GestureDetector(
                    onTap: () => _openImage(ctx, media),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 120,
                        height: 120,
                        color: AppColors.grey200,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.grey400, size: 40),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // ── Existing feedback ────────────────────────────────────────────
          if (c.hasFeedback) ...[
            const SizedBox(height: 16),
            _SectionTitle('Your Feedback'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < (c.rating ?? 0)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFFFC107),
                        size: 22,
                      ),
                    ),
                  ),
                  if (c.feedback != null && c.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.feedback!,
                        style: const TextStyle(
                            color: AppColors.grey700,
                            height: 1.5,
                            fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],

          // ── Feedback form (if can submit) ────────────────────────────────
          if (c.canSubmitFeedback) ...[
            const SizedBox(height: 16),
            _SectionTitle('Rate Resolution'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How satisfied are you with the resolution?',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.grey900)),
                  const SizedBox(height: 12),
                  // Star selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _feedbackRating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            i < _feedbackRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFFC107),
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_feedbackRating > 0) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        ['', 'Very Dissatisfied', 'Dissatisfied',
                            'Neutral', 'Satisfied', 'Very Satisfied'][_feedbackRating],
                        style: const TextStyle(
                            color: Color(0xFFFFC107),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _feedbackCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Any additional comments? (optional)',
                      hintStyle: const TextStyle(
                          color: AppColors.grey400, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.grey100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.grey200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.grey200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF4CAF50), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          widget.provider.isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: widget.provider.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Text('Submit Feedback',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openImage(BuildContext context, ComplaintMedia media) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.image_outlined, size: 80, color: Colors.white38),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TIMELINE TAB
// ═══════════════════════════════════════════════════════════════════════════

class _TimelineTab extends StatelessWidget {
  final List<ComplaintLog> logs;

  const _TimelineTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline_rounded, size: 56, color: AppColors.grey300),
            SizedBox(height: 16),
            Text('No activity yet',
                style: TextStyle(color: AppColors.grey500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (_, i) {
        final log = logs[i];
        final isLast = i == logs.length - 1;
        return _TimelineItem(log: log, isLast: isLast);
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final ComplaintLog log;
  final bool isLast;

  const _TimelineItem({required this.log, required this.isLast});

  Color get _color {
    switch (log.action) {
      case 'CREATED':
        return const Color(0xFF2196F3);
      case 'ASSIGNED':
        return const Color(0xFF9C27B0);
      case 'STATUS_UPDATED':
        return const Color(0xFF00BCD4);
      case 'RESOLVED':
        return const Color(0xFF4CAF50);
      case 'REJECTED':
        return AppColors.error;
      case 'FEEDBACK_SUBMITTED':
        return const Color(0xFFFFC107);
      default:
        return AppColors.grey400;
    }
  }

  IconData get _icon {
    switch (log.action) {
      case 'CREATED':
        return Icons.fiber_new_rounded;
      case 'ASSIGNED':
        return Icons.assignment_ind_rounded;
      case 'STATUS_UPDATED':
        return Icons.update_rounded;
      case 'RESOLVED':
        return Icons.check_circle_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      case 'FEEDBACK_SUBMITTED':
        return Icons.star_rounded;
      default:
        return Icons.radio_button_checked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy, h:mm a');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: dot + line
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Icon(_icon, color: Colors.white, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.grey200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Right: card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.actionDisplay,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.grey900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge if status changed
                        if (log.newStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _ComplaintDetailScreenState.statusColor(log.newStatus!).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              log.newStatus!.replaceAll('_', ' '),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _ComplaintDetailScreenState.statusColor(log.newStatus!)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(log.createdAt),
                      style: const TextStyle(
                          color: AppColors.grey500, fontSize: 11),
                    ),
                    if (log.actionByName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 12, color: AppColors.grey400),
                          const SizedBox(width: 4),
                          Text(log.actionByName!,
                              style: const TextStyle(
                                  color: AppColors.grey500, fontSize: 11)),
                        ],
                      ),
                    ],
                    if (log.remarks != null && log.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(log.remarks!,
                            style: const TextStyle(
                                color: AppColors.grey700,
                                fontSize: 12,
                                height: 1.4)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.grey900)),
      );
}

class _ContentCard extends StatelessWidget {
  final Widget child;
  const _ContentCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: children
              .expand((w) => [
                    w,
                    if (w != children.last)
                      const Divider(height: 1, color: AppColors.grey100),
                  ])
              .toList(),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.grey400),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.grey500, fontSize: 12)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.grey900,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                  textAlign: TextAlign.end),
            ),
          ],
        ),
      );
}

// ── Tab bar delegate ──────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  const _TabBarDelegate(this.tabBar, {required this.color});

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

extension _ColorExt on Color {
  Color withOpacity(double opacity) => Color.fromARGB(
        (255 * opacity).round(),
        red,
        green,
        blue,
      );
}