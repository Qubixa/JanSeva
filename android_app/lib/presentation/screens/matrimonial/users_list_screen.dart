// lib/presentation/screens/matrimonial/users_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/matrimonial_provider.dart';

class MatrimonialUsersListScreen extends StatefulWidget {
  const MatrimonialUsersListScreen({Key? key}) : super(key: key);

  @override
  State<MatrimonialUsersListScreen> createState() => _MatrimonialUsersListScreenState();
}

class _MatrimonialUsersListScreenState extends State<MatrimonialUsersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatrimonialProvider>().getAllProfiles();
    });
  }

  String _getDisplayName(dynamic profile) {
    if (profile.name != null && profile.name!.isNotEmpty) {
      return profile.name!;
    }
    if (profile.firstName != null) {
      return profile.lastName != null 
          ? '${profile.firstName} ${profile.lastName}' 
          : profile.firstName!;
    }
    return 'Anonymous';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual Profiles'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<MatrimonialProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.profiles.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No profiles found'),
                  SizedBox(height: 8),
                  Text('Check back later for new registrations'),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.profiles.length,
            itemBuilder: (context, index) {
              final profile = provider.profiles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF4081).withOpacity(0.1),
                    child: Text(
                      _getDisplayName(profile).substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Color(0xFFFF4081), fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    _getDisplayName(profile),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile.age != null) Text('Age: ${profile.age} years'),
                      if (profile.location != null && profile.location!.isNotEmpty) 
                        Text('📍 ${profile.location}'),
                      if (profile.profession != null && profile.profession!.isNotEmpty) 
                        Text('💼 ${profile.profession}'),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pushNamed(
                      context, 
                      '/matrimonial/profile/${profile.id}',
                      arguments: profile.id,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedGender;
        int? minAge;
        int? maxAge;
        
        return AlertDialog(
          title: const Text('Filter Profiles'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (value) => selectedGender = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min Age'),
                onChanged: (value) => minAge = int.tryParse(value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Age'),
                onChanged: (value) => maxAge = int.tryParse(value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<MatrimonialProvider>().getAllProfiles(
                  gender: selectedGender,
                  minAge: minAge,
                  maxAge: maxAge,
                );
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}