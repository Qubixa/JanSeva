import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/service_models.dart';
import '../../../core/providers/services_provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  void _fetchContacts() {
    context.read<ServicesProvider>().fetchContacts();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9800),
        elevation: 0,
        title: const Text('Important Contacts', style: TextStyle(color: AppColors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ServicesProvider>(
        builder: (context, servicesProvider, _) {
          if (servicesProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            );
          }

          if (servicesProvider.contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contacts, size: 64, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'No contacts available',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.grey100,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            itemCount: servicesProvider.contacts.length,
            itemBuilder: (context, index) {
              final contact = servicesProvider.contacts[index];
              return ContactCard(contact: contact);
            },
          );
        },
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final Contact contact;

  const ContactCard({
    Key? key,
    required this.contact,
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
                    color: const Color(0xFFFF9800).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.contacts, color: Color(0xFFFF9800), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        contact.department,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey100,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Contact Details
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
                      const Icon(Icons.phone, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          contact.phone,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call, size: 20, color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _launchPhone(contact.phone);
                        },
                      ),
                    ],
                  ),
                  // Email
                  if (contact.email != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            contact.email!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Address
                  if (contact.address != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            contact.address!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Website
                  if (contact.website != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.language, size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            contact.website!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                  _launchPhone(contact.phone);
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
      // Handle error if needed
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
