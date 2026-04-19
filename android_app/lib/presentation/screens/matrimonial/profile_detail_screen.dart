// lib/presentation/screens/matrimonial/profile_detail_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/matrimonial_provider.dart';

class MatrimonialProfileDetailScreen extends StatefulWidget {
  final int profileId;
  const MatrimonialProfileDetailScreen({Key? key, required this.profileId}) : super(key: key);

  @override
  State<MatrimonialProfileDetailScreen> createState() => _MatrimonialProfileDetailScreenState();
}

class _MatrimonialProfileDetailScreenState extends State<MatrimonialProfileDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatrimonialProvider>().getProfileById(widget.profileId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Details'), centerTitle: true),
      body: Consumer<MatrimonialProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = provider.currentProfile;
          if (profile == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Profile not found'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(profile),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildSection('Personal Details', [
                  _info('Age', profile.age?.toString() ?? 'Not specified'),
                  _info('Gender', profile.gender ?? 'Not specified'),
                  _info('Marital Status', profile.maritalStatus ?? 'Not specified'),
                  _info('Religion', profile.religion ?? 'Not specified'),
                  _info('Location', profile.location ?? 'Not specified'),
                  if (profile.caste?.isNotEmpty == true) _info('Caste', profile.caste!),
                ]),
                const Divider(),
                const SizedBox(height: 16),
                _buildSection('Professional Details', [
                  _info('Education', profile.education ?? 'Not specified'),
                  _info('Profession', profile.profession ?? 'Not specified'),
                  if (profile.annualIncome?.isNotEmpty == true)
                    _info('Annual Income', profile.annualIncome!),
                ]),
                if (profile.about?.isNotEmpty == true) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('About',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(profile.about!, style: const TextStyle(height: 1.5)),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                // ── Documents section ──────────────────────────────────────
                _buildDocumentsSection(context, profile),
                const SizedBox(height: 24),
                // ── Send interest button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showInterestDialog(context, provider, profile.id),
                    icon: const Icon(Icons.favorite),
                    label: const Text('Send Interest'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4081),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // ── Header with photo ──────────────────────────────────────────────────────

  Widget _buildHeader(MatrimonialProfile profile) {
    return Center(
      child: Column(
        children: [
          _buildAvatar(profile),
          const SizedBox(height: 16),
          Text(profile.displayName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (profile.email != null)
            Text(profile.email!, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          if (profile.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Verified Profile', style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(MatrimonialProfile profile) {
    ImageProvider? imageProvider;

    if (profile.photoBase64 != null) {
      // base64 data-URI: "data:image/jpeg;base64,..."
      try {
        final parts = profile.photoBase64!.split(',');
        if (parts.length == 2) {
          imageProvider = MemoryImage(base64Decode(parts[1]));
        }
      } catch (_) {}
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFF4081).withOpacity(0.1),
        border: Border.all(color: const Color(0xFFFF4081), width: 3),
      ),
      child: ClipOval(
        child: imageProvider != null
            ? Image(image: imageProvider, fit: BoxFit.cover)
            : profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                ? Image.network(
                    profile.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(),
                  )
                : _avatarFallback(),
      ),
    );
  }

  Widget _avatarFallback() => const Icon(Icons.person, size: 60, color: Color(0xFFFF4081));

  // ── Documents section ──────────────────────────────────────────────────────

  Widget _buildDocumentsSection(BuildContext context, MatrimonialProfile profile) {
    final hasDocs = profile.hasBioData || profile.hasKundali;
    if (!hasDocs) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Documents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (profile.hasBioData)
          _buildDocumentTile(
            icon: Icons.description,
            label: 'Bio Data',
            filename: profile.bioDataFilename ?? 'bio_data.pdf',
            url: '${_apiService(context)}/matrimonial/users/${profile.id}/bio-data',
            color: Colors.blue,
          ),
        if (profile.hasKundali) ...[
          const SizedBox(height: 8),
          _buildDocumentTile(
            icon: Icons.auto_awesome,
            label: 'Kundali',
            filename: profile.kundaliFilename ?? 'kundali.pdf',
            url: '${_apiService(context)}/matrimonial/users/${profile.id}/kundali',
            color: Colors.deepPurple,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  String _apiService(BuildContext context) {
    // Retrieve base URL from ApiService exposed through provider
    // Adjust if your ApiService exposes baseUrl differently
    return context.read<MatrimonialProvider>().toString();
  }

  Widget _buildDocumentTile({
    required IconData icon,
    required String label,
    required String filename,
    required String url,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        color: color.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(filename,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.download, color: color),
            tooltip: 'Download $label',
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...rows,
          const SizedBox(height: 16),
        ],
      );

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.grey600, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  void _showInterestDialog(
      BuildContext context, MatrimonialProvider provider, int profileId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Color(0xFFFF4081)),
            SizedBox(width: 8),
            Text('Send Interest'),
          ],
        ),
        content: const Text(
            'Would you like to send an interest to this profile? '
            'They will be notified of your interest.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.sendInterest(profileId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Interest sent successfully!'
                      : 'Failed to send interest'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4081)),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}