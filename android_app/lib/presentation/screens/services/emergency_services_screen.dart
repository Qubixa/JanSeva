import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/service_models.dart';
import '../../../core/providers/services_provider.dart';

class EmergencyServicesScreen extends StatefulWidget {
  const EmergencyServicesScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyServicesScreen> createState() => _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState extends State<EmergencyServicesScreen> {
  String? _selectedType;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  bool _isExporting = false;

  final Map<String, IconData> _typeIcons = {
    'Hospital': Icons.local_hospital,
    'School': Icons.school,
    'Fire Brigade': Icons.local_fire_department,
    'Library': Icons.local_library,
    'Night Shelter': Icons.night_shelter,
    'Senior Citizen Centre': Icons.elderly,
  };

  final Map<String, Color> _typeColors = {
    'Hospital': AppColors.error,
    'School': AppColors.info,
    'Fire Brigade': Color(0xFFFF6B00),
    'Library': AppColors.secondary,
    'Night Shelter': Color(0xFF9C27B0),
    'Senior Citizen Centre': Color(0xFF4CAF50),
  };

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchServices() {
    final servicesProvider = context.read<ServicesProvider>();
    servicesProvider.fetchEmergencyServices();
  }

  List<EmergencyService> _getFilteredServices(List<EmergencyService> allServices) {
    var filtered = allServices;

    // Filter by type
    if (_selectedType != null) {
      filtered = filtered.where((s) => s.type == _selectedType).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.name.toLowerCase().contains(query) ||
            s.type.toLowerCase().contains(query) ||
            (s.category?.toLowerCase().contains(query) ?? false) ||
            s.address.toLowerCase().contains(query) ||
            s.phone.contains(query);
      }).toList();
    }

    return filtered;
  }

  List<EmergencyService> _getPaginatedServices(List<EmergencyService> services) {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, services.length);

    if (startIndex >= services.length) return [];
    return services.sublist(startIndex, endIndex);
  }

  int _getTotalPages(int totalItems) {
    return (totalItems / _itemsPerPage).ceil();
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 0;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _openInGoogleMaps(String address) async {
    try {
      // URL encode the address
      final encodedAddress = Uri.encodeComponent(address);

      // Try Google Maps app first (mobile)
      final googleMapsUrl = 'comgooglemaps://?q=$encodedAddress';
      final googleMapsUri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri);
      } else {
        // Fallback to web version
        final webUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
        final webUri = Uri.parse(webUrl);

        await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportToPDF(List<EmergencyService> services) async {
    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No services to export'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final pdf = pw.Document();

      // Get type for title
      final typeTitle = _selectedType ?? 'All Emergency Services';
      final exportDate = DateTime.now().toString().split('.')[0];

      // Group services by type for better organization
      final groupedServices = <String, List<EmergencyService>>{};
      for (var service in services) {
        if (!groupedServices.containsKey(service.type)) {
          groupedServices[service.type] = [];
        }
        groupedServices[service.type]!.add(service);
      }

      // Add pages to PDF
      for (var entry in groupedServices.entries) {
        final type = entry.key;
        final typeServices = entry.value;

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (context) {
              return [
                // Header
                pw.Header(
                  level: 0,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Emergency Services Directory',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Type: $type',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Total Services: ${typeServices.length}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Generated: $exportDate',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Divider(thickness: 2),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Services list
                ...typeServices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 16),
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Service number and name
                        pw.Row(
                          children: [
                            pw.Container(
                              width: 30,
                              height: 30,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue100,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '${index + 1}',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.blue800,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    service.name,
                                    style: pw.TextStyle(
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  if (service.category != null && service.category!.isNotEmpty)
                                    pw.Text(
                                      service.category!,
                                      style: const pw.TextStyle(
                                        fontSize: 10,
                                        color: PdfColors.blue700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Divider(color: PdfColors.grey300),
                        pw.SizedBox(height: 8),

                        // Contact information
                        _buildPdfInfoRow('Phone', service.phone),
                        if (service.alternatePhone != null && service.alternatePhone!.isNotEmpty)
                          _buildPdfInfoRow('Alt. Phone', service.alternatePhone!),
                        if (service.email != null && service.email!.isNotEmpty)
                          _buildPdfInfoRow('Email', service.email!),
                        _buildPdfInfoRow('Address', service.address),

                        // 24x7 badge
                        if (service.is24x7 == 'Y')
                          pw.Container(
                            margin: const pw.EdgeInsets.only(top: 8),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.green100,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              '24x7 Available',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ];
            },
            footer: (context) {
              return pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 16),
                child: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              );
            },
          ),
        );
      }

      // Save and share PDF
      final output = await getTemporaryDirectory();
      final fileName = 'emergency_services_${typeTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share/Open PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.error,
        elevation: 0,
        title: const Text(
          'Emergency Services',
          style: TextStyle(color: AppColors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: () {
              _fetchServices();
              _resetPagination();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<ServicesProvider>(
        builder: (context, servicesProvider, _) {
          if (servicesProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
              ),
            );
          }

          if (servicesProvider.error != null) {
            return _buildErrorState(servicesProvider.error!);
          }

          if (servicesProvider.emergencyServices.isEmpty) {
            return _buildEmptyState();
          }

          final allServices = servicesProvider.emergencyServices;
          final serviceTypes = allServices.map((s) => s.type).toSet().toList()..sort();
          final filteredServices = _getFilteredServices(allServices);
          final paginatedServices = _getPaginatedServices(filteredServices);
          final totalPages = _getTotalPages(filteredServices.length);

          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey300.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, address, phone...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.grey400),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.grey400),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _resetPagination();
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.grey300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.grey300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.grey100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          _resetPagination();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Export button
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: _isExporting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                            : const Icon(Icons.picture_as_pdf, color: AppColors.white),
                        onPressed: _isExporting
                            ? null
                            : () => _exportToPDF(filteredServices),
                        tooltip: 'Export to PDF',
                      ),
                    ),
                  ],
                ),
              ),

              // Type Filter Chips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey300.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by Type',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.grey900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // All filter
                          _buildFilterChip(
                            label: 'All',
                            count: allServices.length,
                            isSelected: _selectedType == null,
                            onTap: () {
                              setState(() {
                                _selectedType = null;
                              });
                              _resetPagination();
                            },
                          ),
                          const SizedBox(width: 8),
                          // Type-specific filters
                          ...serviceTypes.map((type) {
                            final count = allServices.where((s) => s.type == type).length;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildFilterChip(
                                label: type,
                                count: count,
                                icon: _typeIcons[type],
                                color: _typeColors[type],
                                isSelected: _selectedType == type,
                                onTap: () {
                                  setState(() {
                                    _selectedType = type;
                                  });
                                  _resetPagination();
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Results count
              if (filteredServices.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Showing ${paginatedServices.length} of ${filteredServices.length} services',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey700,
                    ),
                  ),
                ),

              // Services List
              Expanded(
                child: filteredServices.isEmpty
                    ? _buildNoResultsState()
                    : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  itemCount: paginatedServices.length,
                  itemBuilder: (context, index) {
                    final service = paginatedServices[index];
                    return EmergencyServiceCard(
                      service: service,
                      icon: _typeIcons[service.type] ?? Icons.info,
                      color: _typeColors[service.type] ?? AppColors.primary,
                      onOpenMap: () => _openInGoogleMaps(service.address),
                    );
                  },
                ),
              ),

              // Pagination
              if (totalPages > 1)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.grey300.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous button
                      ElevatedButton.icon(
                        onPressed: _currentPage > 0
                            ? () {
                          setState(() {
                            _currentPage--;
                          });
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Previous'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.grey300,
                        ),
                      ),

                      // Page indicator
                      Text(
                        'Page ${_currentPage + 1} of $totalPages',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // Next button
                      ElevatedButton.icon(
                        onPressed: _currentPage < totalPages - 1
                            ? () {
                          setState(() {
                            _currentPage++;
                          });
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Next'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.grey300,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    IconData? icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.primary)
                : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.white : AppColors.grey700,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.grey900,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.white.withOpacity(0.3)
                    : AppColors.grey300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.grey900,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading services',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchServices,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'No emergency services available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.grey400,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchServices,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'No services found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.grey400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search or filter',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedType = null;
                  _searchQuery = '';
                  _searchController.clear();
                });
                _resetPagination();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmergencyServiceCard extends StatelessWidget {
  final EmergencyService service;
  final IconData icon;
  final Color color;
  final VoidCallback onOpenMap;

  const EmergencyServiceCard({
    Key? key,
    required this.service,
    required this.icon,
    required this.color,
    required this.onOpenMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.grey900,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.type,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Category (if available)
            if (service.category != null && service.category!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  service.category!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Contact Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phone
                  Row(
                    children: [
                      Icon(Icons.phone, size: 18, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service.phone,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.call, size: 20, color: color),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _launchPhone(service.phone);
                        },
                      ),
                    ],
                  ),
                  // Alternate Phone
                  if (service.alternatePhone != null && service.alternatePhone!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 18, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service.alternatePhone!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.call, size: 20, color: color),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _launchPhone(service.alternatePhone!);
                          },
                        ),
                      ],
                    ),
                  ],
                  // Address with Map button
                  if (service.address.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 18, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.address,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.grey700,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: onOpenMap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: color.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.map, size: 14, color: color),
                                      const SizedBox(width: 4),
                                      Text(
                                        'View on Map',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                  ],
                  // 24x7 badge
                  if (service.is24x7 == 'Y') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            '24x7 Available',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Call Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _launchPhone(service.phone);
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('Error launching phone: $e');
    }
  }
}

extension on Color {
  Color withOpacity(double opacity) {
    return Color.fromARGB(
      (255 * opacity).toInt(),
      red,
      green,
      blue,
    );
  }
}