// lib/presentation/screens/matrimonial/agency_registration_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/matrimonial_provider.dart';

class AgencyRegistrationScreen extends StatefulWidget {
  const AgencyRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<AgencyRegistrationScreen> createState() => _AgencyRegistrationScreenState();
}

class _AgencyRegistrationScreenState extends State<AgencyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _agencyNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _aboutController = TextEditingController();
  
  File? _logo;
  
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _agencyNameController.dispose();
    _contactEmailController.dispose();
    _phoneController.dispose();
    _ownerNameController.dispose();
    _registrationNumberController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;
    
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _logo = File(picked.path));
    }
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Select Logo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MatrimonialProvider>();
    
    final success = await provider.registerAgency(
      agencyName: _agencyNameController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      phone: _phoneController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      registrationNumber: _registrationNumberController.text.trim(),
      location: _locationController.text.trim(),
      about: _aboutController.text.trim().isNotEmpty ? _aboutController.text.trim() : null,
      logo: _logo,
    );

    if (!mounted) return;

    if (success) {
      _showSnack('Agency registration submitted for approval!', Colors.green);
      Navigator.pop(context);
    } else {
      _showSnack(provider.errorMessage ?? 'Registration failed', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Registration'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogoPicker(),
              const SizedBox(height: 24),
              
              const Text('Agency Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              _buildTextField(_agencyNameController, 'Agency Name *', Icons.business,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              _buildTextField(_contactEmailController, 'Contact Email *', Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              _buildTextField(_phoneController, 'Phone Number *', Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              _buildTextField(_ownerNameController, 'Owner Name *', Icons.person,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              _buildTextField(_registrationNumberController, 'Registration Number *', Icons.numbers,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              _buildTextField(_locationController, 'Location *', Icons.location_on,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              
              const SizedBox(height: 16),
              const Text('About Agency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aboutController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell us about your agency...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your registration will be reviewed by an admin. You will be notified once approved.',
                        style: TextStyle(color: Colors.orange[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              Consumer<MatrimonialProvider>(
                builder: (context, provider, _) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Register Agency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPicker() => Center(
        child: Stack(
          children: [
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: ClipOval(
                  child: _logo != null
                      ? Image.file(_logo!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business, size: 40, color: AppColors.primary),
                            const SizedBox(height: 4),
                            Text('Logo', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                          ],
                        ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(icon),
          ),
          validator: validator,
        ),
      );
}