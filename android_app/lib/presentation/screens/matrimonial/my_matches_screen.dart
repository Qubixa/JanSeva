// lib/presentation/screens/matrimonial/my_matches_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/matrimonial_provider.dart';

class MyMatchesScreen extends StatefulWidget {
  const MyMatchesScreen({Key? key}) : super(key: key);

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'PENDING';
  bool _isProcessing = false;
  
  final List<String> _filters = ['PENDING', 'ACCEPTED', 'REJECTED', 'ALL'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  Future<void> _loadMatches() async {
    final provider = context.read<MatrimonialProvider>();
    await provider.getMyMatches(status: _selectedFilter == 'ALL' ? null : _selectedFilter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Matches'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildFilterChips(),
        ),
      ),
      body: Consumer<MatrimonialProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.myMatches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'ALL' ? 'No matches found' : 'No ${_selectedFilter.toLowerCase()} matches',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFilter == 'ALL' 
                        ? 'Send interests to see them here' 
                        : 'Try a different filter',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (_selectedFilter != 'ALL') ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedFilter = 'ALL');
                        _loadMatches();
                      },
                      child: const Text('View all matches'),
                    ),
                  ],
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _loadMatches,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.myMatches.length,
              itemBuilder: (context, index) {
                final match = provider.myMatches[index];
                // Determine if current user is sender or receiver
                // This logic depends on your API response structure
                final isIncoming = match.status == 'PENDING'; // Simplified - adjust based on your data
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(match.status),
                          child: Icon(_getStatusIcon(match.status), color: Colors.white, size: 20),
                        ),
                        title: Text(
                          isIncoming ? 'Interest Received' : 'Interest Sent',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(match.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Status: ${match.status}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(match.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (match.message != null && match.message!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '💬 ${match.message}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '📅 ${_formatDate(match.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: match.status == 'ACCEPTED'
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                            : match.status == 'REJECTED'
                                ? const Icon(Icons.cancel, color: Colors.red, size: 28)
                                : null,
                      ),
                      // Action buttons for pending incoming requests
                      if (match.status == 'PENDING')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isProcessing ? null : () => _updateMatchStatus(context, match.id, 'REJECTED'),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessing ? null : () => _updateMatchStatus(context, match.id, 'ACCEPTED'),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Accept'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
              });
              _loadMatches();
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: AppColors.primary.withOpacity(0.2),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateMatchStatus(BuildContext context, int matchId, String status) async {
    setState(() => _isProcessing = true);
    
    final provider = context.read<MatrimonialProvider>();
    final success = await provider.updateMatchStatus(matchId, status);
    
    setState(() => _isProcessing = false);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Match ${status.toLowerCase()} successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      // Reload matches
      await _loadMatches();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to update match'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'ACCEPTED': return Colors.green;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING': return Icons.hourglass_empty;
      case 'ACCEPTED': return Icons.check_circle;
      case 'REJECTED': return Icons.cancel;
      default: return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}