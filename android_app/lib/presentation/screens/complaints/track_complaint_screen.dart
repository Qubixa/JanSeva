// lib/presentation/screens/complaint/track_complaint_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/providers/complaint_provider.dart';
import 'complaint_detail_screen.dart';

class TrackComplaintScreen extends StatefulWidget {
  const TrackComplaintScreen({Key? key}) : super(key: key);

  @override
  State<TrackComplaintScreen> createState() => _TrackComplaintScreenState();
}

class _TrackComplaintScreenState extends State<TrackComplaintScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  String? _selectedStatus;
  bool _isInitialLoad = true;
  bool _isRefreshing = false;

  static const _statusFilters = [
    {'label': 'All', 'value': null},
    {'label': 'Pending', 'value': 'PENDING'},
    {'label': 'Assigned', 'value': 'ASSIGNED'},
    {'label': 'In Progress', 'value': 'IN_PROGRESS'},
    {'label': 'Resolved', 'value': 'RESOLVED'},
    {'label': 'Closed', 'value': 'CLOSED'},
    {'label': 'Rejected', 'value': 'REJECTED'},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComplaints();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshComplaints();
    }
  }

  void _loadComplaints() {
    final provider = context.read<ComplaintProvider>();
    provider.resetMyComplaints();
    provider.fetchMyComplaints(refresh: true).then((_) {
      if (mounted) {
        setState(() => _isInitialLoad = false);
      }
    }).catchError((error) {
      if (mounted) {
        setState(() => _isInitialLoad = false);
        _showErrorSnackBar('Failed to load complaints: $error');
      }
    });
  }

  Future<void> _refreshComplaints() async {
    setState(() => _isRefreshing = true);
    final provider = context.read<ComplaintProvider>();
    provider.resetMyComplaints();
    await provider.fetchMyComplaints(refresh: true, statusFilter: _selectedStatus);
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final provider = context.read<ComplaintProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.fetchMyComplaints(statusFilter: _selectedStatus);
      }
    }
  }

  Future<void> _onRefresh() async {
    await _refreshComplaints();
  }

  void _onStatusFilter(String? status) {
    setState(() {
      _selectedStatus = status;
      _isInitialLoad = true;
    });
    final provider = context.read<ComplaintProvider>();
    provider.resetMyComplaints();
    provider.fetchMyComplaints(refresh: true, statusFilter: status).then((_) {
      if (mounted) {
        setState(() => _isInitialLoad = false);
      }
    }).catchError((error) {
      if (mounted) {
        setState(() => _isInitialLoad = false);
        _showErrorSnackBar('Failed to filter complaints: $error');
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFF00BCD4),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildSliverAppBar(provider),
                if (provider.myComplaints.isNotEmpty) ...[
                  _buildStatsBar(provider),
                  _buildFilterBar(),
                ],
                _buildContent(provider),
                if (provider.isLoading && provider.myComplaints.isNotEmpty)
  const SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: SizedBox(width: 24, height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00BCD4)))),
    ),
  ),
if (provider.myComplaints.isNotEmpty)
  const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<ComplaintProvider>(
        builder: (context, provider, child) {
          if ((provider.isLoading && provider.myComplaints.isEmpty) || _isInitialLoad || _isRefreshing) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/file-complaint');
              if (result == true && mounted) {
                _loadComplaints();
              }
            },
            backgroundColor: const Color(0xFFFF9800),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'New Complaint',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(ComplaintProvider provider) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: const Color(0xFF00BCD4),
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
            child: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
          onPressed: _isRefreshing ? null : _onRefresh,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.track_changes_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'My Complaints',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                    if (!_isInitialLoad && !_isRefreshing)
                      Text(
                        provider.myComplaints.isEmpty
                            ? 'No complaints yet'
                            : '${provider.stats.total} complaint${provider.stats.total == 1 ? '' : 's'} filed',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85), fontSize: 13),
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

  Widget _buildStatsBar(ComplaintProvider provider) {
    final stats = provider.stats;
    
    if (stats.total == 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final items = [
      _StatItem('Total', stats.total, const Color(0xFF607D8B)),
      _StatItem('Pending', stats.pending, const Color(0xFFFF9800)),
      _StatItem('In Progress', stats.inProgress + stats.assigned,
          const Color(0xFF00BCD4)),
      _StatItem('Resolved', stats.resolved, const Color(0xFF4CAF50)),
    ];

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Row(
          children: items.map((item) => Expanded(child: _buildStatTile(item))).toList(),
        ),
      ),
    );
  }

  Widget _buildStatTile(_StatItem item) {
    return Column(
      children: [
        Text(
          item.count.toString(),
          style: TextStyle(
              color: item.color,
              fontWeight: FontWeight.w800,
              fontSize: 22),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: const TextStyle(
              color: AppColors.grey500, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterBarDelegate(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _statusFilters.map((f) {
                final value = f['value'] as String?;
                final label = f['label'] as String;
                final isSelected = _selectedStatus == value;
                final color = value != null
                    ? statusColor(value)
                    : const Color(0xFF00BCD4);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => _onStatusFilter(value),
                    selectedColor: color,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.grey700,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                    backgroundColor: AppColors.grey100,
                    side: BorderSide(
                        color: isSelected ? color : AppColors.grey200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ComplaintProvider provider) {
  if (_isInitialLoad || _isRefreshing || (provider.isLoading && provider.myComplaints.isEmpty)) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00BCD4)),
            SizedBox(height: 16),
            Text(
              'Loading your complaints...',
              style: TextStyle(color: AppColors.grey500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  if (provider.myComplaints.isEmpty) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: _buildEmptyState(provider),
    );
  }

  return SliverPadding(
    padding: const EdgeInsets.only(top: 8, bottom: 24),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= provider.myComplaints.length) return const SizedBox.shrink();
          final complaint = provider.myComplaints[index];
          if (complaint.id == 0 && complaint.title.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ComplaintCard(complaint: complaint),
          );
        },
        childCount: provider.myComplaints.length,
      ),
    ),
  );
}

  Widget _buildEmptyState(ComplaintProvider provider) {
    final hasFilter = _selectedStatus != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFilter ? Icons.filter_list_off : Icons.note_alt_outlined,
              size: 56,
              color: const Color(0xFF00BCD4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasFilter
                ? 'No complaints with this status'
                : 'No complaints yet',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Try selecting a different filter'
                : 'File your first complaint to get started',
            style: const TextStyle(
                color: AppColors.grey500, fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (hasFilter)
            TextButton.icon(
              onPressed: () => _onStatusFilter(null),
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filter'),
            )
          else
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/file-complaint');
                if (result == true && mounted) {
                  _loadComplaints();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('File a Complaint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Complaint Card ─────────────────────────────────────────────────────────

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;

  const ComplaintCard({Key? key, required this.complaint}) : super(key: key);

  Color get _statusColor =>
      _TrackComplaintScreenState.statusColor(complaint.status);

  IconData get _statusIcon {
    switch (complaint.status.toUpperCase()) {
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

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ComplaintDetailScreen(complaintId: complaint.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status stripe + header ───────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_statusIcon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.grey900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            complaint.complaintNumber.isNotEmpty 
                                ? '#${complaint.complaintNumber}' 
                                : '#${complaint.id}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        complaint.getStatusDisplay(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category + Priority chips
                    Row(
                      children: [
                        _Chip(
                          icon: Icons.category_rounded,
                          label: complaint.categoryInfo?.name ?? complaint.category,
                          color: const Color(0xFF2196F3),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          icon: Icons.flag_rounded,
                          label: complaint.getPriorityDisplay(),
                          color: _priorityColor(complaint.priority),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Description preview
                    Text(
                      complaint.description,
                      style: const TextStyle(
                          color: AppColors.grey700,
                          fontSize: 12,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Location & date row
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.grey400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            complaint.address,
                            style: const TextStyle(
                                color: AppColors.grey500, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: AppColors.grey400),
                        const SizedBox(width: 4),
                        Text(
                          dateFmt.format(complaint.createdAt),
                          style: const TextStyle(
                              color: AppColors.grey500, fontSize: 11),
                        ),
                      ],
                    ),

                    // Resolution notes
                    if (complaint.resolutionRemarks != null && complaint.resolutionRemarks!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFA5D6A7)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                size: 14, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                complaint.resolutionRemarks!,
                                style: const TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 11,
                                    height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Feedback prompt
                    if (complaint.canSubmitFeedback) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ComplaintDetailScreen(complaintId: complaint.id),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFCC80)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star_outline_rounded,
                                  color: Color(0xFFFF9800), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Tap to rate this resolution',
                                style: TextStyle(
                                    color: Color(0xFFE65100),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p.toUpperCase()) {
      case 'LOW':
        return const Color(0xFF4CAF50);
      case 'MEDIUM':
        return const Color(0xFF2196F3);
      case 'HIGH':
        return const Color(0xFFFF9800);
      case 'URGENT':
        return const Color(0xFFE91E63);
      default:
        return AppColors.grey400;
    }
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Persistent filter bar delegate ────────────────────────────────────────

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  
  const _FilterBarDelegate({required this.child});

  @override
  double get minExtent => 54;
  
  @override
  double get maxExtent => 54;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_FilterBarDelegate oldDelegate) => false;
}

// ── Helper Classes ─────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final int count;
  final Color color;
  
  const _StatItem(this.label, this.count, this.color);
}