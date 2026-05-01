// lib/presentation/screens/matrimonial/agencies_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/matrimonial_provider.dart';

class MatrimonialAgenciesListScreen extends StatefulWidget {
  const MatrimonialAgenciesListScreen({Key? key}) : super(key: key);

  @override
  State<MatrimonialAgenciesListScreen> createState() => _MatrimonialAgenciesListScreenState();
}

class _MatrimonialAgenciesListScreenState extends State<MatrimonialAgenciesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAgencies();
    });
  }

  Future<void> _loadAgencies() async {
    await context.read<MatrimonialProvider>().getAllAgencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrimonial Agencies'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAgencies,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<MatrimonialProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.agencies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.agencies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No agencies found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for verified agencies',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadAgencies,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadAgencies,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.agencies.length,
              itemBuilder: (context, index) {
                final agency = provider.agencies[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _showAgencyDetailsDialog(context, agency),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Logo or Initials
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C27B0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                (agency.agencyName.isNotEmpty ? agency.agencyName[0] : 'A').toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF9C27B0),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Agency Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        agency.agencyName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (agency.isVerified)
                                      const Icon(Icons.verified, color: Colors.green, size: 16),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        agency.location,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (agency.about != null && agency.about!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    agency.about!,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAgencyDetailsDialog(BuildContext context, MatrimonialAgency agency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.business, color: Color(0xFF9C27B0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                agency.agencyName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Owner', agency.ownerName),
              const Divider(),
              _detailRow('Email', agency.contactEmail),
              const Divider(),
              _detailRow('Phone', agency.phone),
              const Divider(),
              _detailRow('Registration No', agency.registrationNumber),
              const Divider(),
              _detailRow('Location', agency.location),
              if (agency.about != null && agency.about!.isNotEmpty) ...[
                const Divider(),
                _detailRow('About', agency.about!),
              ],
              const Divider(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: agency.isVerified 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      agency.isVerified ? Icons.verified : Icons.pending,
                      color: agency.isVerified ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      agency.isVerified ? 'Verified Agency' : 'Pending Verification',
                      style: TextStyle(
                        color: agency.isVerified ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}