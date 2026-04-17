import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/notification_provider.dart'; // fixed: 4 levels up to reach lib/
import '../../../../core/models/notification_model.dart';       // fixed: 4 levels up
import '../../../../core/constants/app_colors.dart';            // fixed: 4 levels up
import '../../../notifications/notification_detail_screen.dart'; // fixed: screens/ → notifications/

class NotificationsScrollable extends StatefulWidget {
  const NotificationsScrollable({Key? key}) : super(key: key);

  @override
  State<NotificationsScrollable> createState() => _NotificationsScrollableState();
}

class _NotificationsScrollableState extends State<NotificationsScrollable>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;
  int _currentIndex = 0;

  static const Duration autoScrollInterval = Duration(seconds: 4);
  static const double cardWidthWithMargin = 296.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _stopAutoScroll();
    _autoScrollTimer = Timer.periodic(autoScrollInterval, (timer) {
      if (!_isUserInteracting &&
          _scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollToNextItem();
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _scrollToNextItem() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    double nextScroll = currentScroll + cardWidthWithMargin;

    if (nextScroll >= maxScroll) {
      nextScroll = 0;
      setState(() => _currentIndex = 0);
    } else {
      setState(() => _currentIndex = (nextScroll / cardWidthWithMargin).round());
    }

    _scrollController.animateTo(
      nextScroll,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onUserInteractionStart() {
    setState(() => _isUserInteracting = true);
    _stopAutoScroll();
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _isUserInteracting) {
        setState(() => _isUserInteracting = false);
        _startAutoScroll();
      }
    });
  }

  void _onUserInteractionEnd() {
    _stopAutoScroll();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.notices.isEmpty) {
          return _buildLoadingShimmer();
        }

        if (provider.notices.isEmpty) {
          return _buildEmptyState();
        }

        final activeNotices = provider.notices.where((n) => !n.isExpired).toList();

        if (activeNotices.isEmpty) return _buildEmptyState();

        final displayNotices =
            activeNotices.length > 10 ? activeNotices.sublist(0, 10) : activeNotices;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Latest Updates',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.grey900,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (!_isUserInteracting && displayNotices.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Auto-scrolling',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/notices'),
                    child: const Text('View All →'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTapDown: (_) => _onUserInteractionStart(),
              onTapUp: (_) => _onUserInteractionEnd(),
              onHorizontalDragStart: (_) => _onUserInteractionStart(),
              onHorizontalDragEnd: (_) => _onUserInteractionEnd(),
              child: SizedBox(
                height: 220,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayNotices.length,
                  itemBuilder: (context, index) {
                    final notice = displayNotices[index];
                    return _buildNoticeCard(
                        context, notice, index == _currentIndex && !_isUserInteracting);
                  },
                ),
              ),
            ),
            if (displayNotices.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(child: _buildDotIndicators(displayNotices.length)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNoticeCard(BuildContext context, Notice notice, bool isHighlighted) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: isHighlighted ? 8 : 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            _onUserInteractionStart();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationDetailScreen(notice: notice),
              ),
            ).then((_) => _onUserInteractionEnd());
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [notice.noticeColor, notice.noticeColor.withOpacity(0.7)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Text(notice.noticeIcon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice.noticeType,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _truncateText(notice.title, 25),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _truncateText(notice.message, 80),
                        style: TextStyle(fontSize: 14, color: AppColors.grey700, height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: AppColors.grey500),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(notice.createdAt),
                            style: TextStyle(fontSize: 11, color: AppColors.grey500),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: notice.noticeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Read More',
                              style: TextStyle(
                                fontSize: 11,
                                color: notice.noticeColor,
                                fontWeight: FontWeight.w600,
                              ),
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
      ),
    );
  }

  Widget _buildDotIndicators(int itemCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == index ? AppColors.info : AppColors.grey400,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                    color: AppColors.info, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 150,
                height: 24,
                decoration:
                    BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) => Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                  color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_none, size: 48, color: AppColors.grey400),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Updates',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey700)),
                  const SizedBox(height: 4),
                  Text('Check back later for latest announcements',
                      style: TextStyle(fontSize: 14, color: AppColors.grey500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (difference.inDays > 0) return '${difference.inDays} days ago';
    if (difference.inHours > 0) return '${difference.inHours} hours ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minutes ago';
    return 'Just now';
  }
}