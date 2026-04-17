// lib/presentation/screens/matrimonial/user_registration_screen.dart
//
// Registration with profile photo, bio-data PDF, and optional kundali upload.
// Uses multipart/form-data via the http package.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/matrimonial_provider.dart';
import '../../../core/providers/auth_provider.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _educationController;
  late TextEditingController _professionController;

  // Dropdown values
  String? _selectedGender;
  String? _selectedReligion;
  String? _selectedMaritalStatus;

  // File selections
  File?   _profileImage;
  File?   _bioDataFile;
  String? _bioDataFileName;
  File?   _kundaliFile;
  String? _kundaliFileName;

  final _imagePicker = ImagePicker();

  static const genders         = ['Male', 'Female', 'Other'];
  static const religions       = ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 'Jain', 'Other'];
  static const maritalStatuses = ['Single', 'Divorced', 'Widowed', 'Separated'];

  @override
  void initState() {
    super.initState();
    _firstNameController  = TextEditingController();
    _lastNameController   = TextEditingController();
    _ageController        = TextEditingController();
    _locationController   = TextEditingController();
    _descriptionController = TextEditingController();
    _emailController      = TextEditingController();
    _phoneController      = TextEditingController();
    _educationController  = TextEditingController();
    _professionController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.email != null) {
        _emailController.text = authProvider.user!.email!;
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _educationController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  // ── Image picker ────────────────────────────────────────────────────────────

  Future<void> _pickProfileImage() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
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
            const Text('Select Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Document pickers ─────────────────────────────────────────────────────────

  Future<void> _pickBioData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _bioDataFile     = File(result.files.single.path!);
        _bioDataFileName = result.files.single.name;
      });
    }
  }

  Future<void> _pickKundali() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _kundaliFile     = File(result.files.single.path!);
        _kundaliFileName = result.files.single.name;
      });
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final age = int.parse(_ageController.text);
    if (age < 18) {
      _showSnack('You must be at least 18 years old', Colors.red);
      return;
    }

    final matrimonialProvider = context.read<MatrimonialProvider>();

    // Build the date-of-birth from age (approximate; backend can refine)
    final dob = DateTime(
      DateTime.now().year - age,
      DateTime.now().month,
      DateTime.now().day,
    ).toIso8601String().split('T').first;

    final userData = {
      'first_name':     _firstNameController.text.trim(),
      'last_name':      _lastNameController.text.trim(),
      'email':          _emailController.text.trim(),
      'phone':          _phoneController.text.trim(),
      'gender':         _selectedGender ?? '',
      'date_of_birth':  dob,
      'marital_status': _selectedMaritalStatus ?? '',
      'location':       _locationController.text.trim(),
      'bio':            _descriptionController.text.trim(),
      'education':      _educationController.text.trim(),
      'occupation':     _professionController.text.trim(),
      'religion':       _selectedReligion ?? '',
    };

    final success = await matrimonialProvider.registerAsUserWithFiles(
      userData:     userData,
      profileImage: _profileImage,
      bioData:      _bioDataFile,
      kundali:      _kundaliFile,
    );

    if (!mounted) return;

    if (success) {
      _showSnack('Registration successful!', Colors.green);
      Navigator.pop(context);
    } else {
      _showSnack(matrimonialProvider.errorMessage ?? 'Registration failed', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Individual'),
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
              _buildInfoBanner(),
              const SizedBox(height: 24),

              // ── Profile photo ─────────────────────────────────────────────
              _buildSectionTitle('Profile Photo'),
              const SizedBox(height: 12),
              _buildProfileImagePicker(),
              const SizedBox(height: 24),

              // ── Personal info ─────────────────────────────────────────────
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 16),
              _buildTextField(_firstNameController, 'First Name *', Icons.person,
                  validator: (v) => (v?.isEmpty ?? true) ? 'First name is required' : null),
              _buildTextField(_lastNameController, 'Last Name *', Icons.person_outline,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Last name is required' : null),
              _buildTextField(_emailController, 'Email *', Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Email is required';
                    if (!v!.contains('@')) return 'Enter a valid email';
                    return null;
                  }),
              _buildTextField(_phoneController, 'Phone Number *', Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Phone number is required';
                    if (v!.length < 10) return 'Enter a valid phone number';
                    return null;
                  }),
              _buildTextField(_ageController, 'Age *', Icons.cake,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Age is required';
                    final a = int.tryParse(v!);
                    if (a == null) return 'Enter a valid age';
                    if (a < 18) return 'Must be at least 18';
                    if (a > 100) return 'Enter a valid age';
                    return null;
                  }),
              _buildDropdown('Gender *', Icons.wc, genders, _selectedGender,
                  (v) => setState(() => _selectedGender = v),
                  validator: (v) => v == null ? 'Gender is required' : null),
              _buildDropdown('Religion *', Icons.temple_buddhist, religions, _selectedReligion,
                  (v) => setState(() => _selectedReligion = v),
                  validator: (v) => v == null ? 'Religion is required' : null),
              _buildDropdown('Marital Status *', Icons.favorite, maritalStatuses, _selectedMaritalStatus,
                  (v) => setState(() => _selectedMaritalStatus = v),
                  validator: (v) => v == null ? 'Marital status is required' : null),
              _buildTextField(_locationController, 'Location / City *', Icons.location_on,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Location is required' : null),

              const SizedBox(height: 24),
              _buildSectionTitle('Professional Details'),
              const SizedBox(height: 16),
              _buildTextField(_professionController, 'Profession / Occupation', Icons.work),
              _buildTextField(_educationController, 'Education', Icons.school),

              const SizedBox(height: 24),
              _buildSectionTitle('About You'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'About Yourself',
                  hintText: 'Tell us about your interests, values...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    Text('$currentLength/$maxLength',
                        style: TextStyle(fontSize: 12, color: AppColors.grey500)),
              ),

              const SizedBox(height: 24),
              // ── Documents ─────────────────────────────────────────────────
              _buildSectionTitle('Documents'),
              const SizedBox(height: 4),
              Text('Upload your bio-data and optionally your kundali.',
                  style: TextStyle(fontSize: 13, color: AppColors.grey500)),
              const SizedBox(height: 16),
              _buildDocumentPicker(
                label: 'Bio Data *',
                subtitle: 'PDF, JPG or PNG – max 10 MB',
                icon: Icons.description,
                fileName: _bioDataFileName,
                onPick: _pickBioData,
                onRemove: () => setState(() { _bioDataFile = null; _bioDataFileName = null; }),
              ),
              const SizedBox(height: 12),
              _buildDocumentPicker(
                label: 'Kundali (Optional)',
                subtitle: 'PDF, JPG or PNG – max 10 MB',
                icon: Icons.auto_awesome,
                fileName: _kundaliFileName,
                onPick: _pickKundali,
                onRemove: () => setState(() { _kundaliFile = null; _kundaliFileName = null; }),
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
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Text('Register',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reusable widgets ─────────────────────────────────────────────────────────

  Widget _buildInfoBanner() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.favorite, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Complete your profile to find your perfect match',
                style: TextStyle(color: AppColors.grey700, fontSize: 14),
              ),
            ),
          ],
        ),
      );

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey900),
      );

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
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

  Widget _buildDropdown(
    String label,
    IconData icon,
    List<String> items,
    String? value,
    void Function(String?) onChanged, {
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(icon),
          ),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      );

  Widget _buildProfileImagePicker() => Center(
        child: Stack(
          children: [
            GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(_profileImage!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, size: 48, color: AppColors.primary),
                            const SizedBox(height: 4),
                            Text('Add Photo',
                                style: TextStyle(fontSize: 11, color: AppColors.primary)),
                          ],
                        ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickProfileImage,
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

  Widget _buildDocumentPicker({
    required String label,
    required String subtitle,
    required IconData icon,
    required String? fileName,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final picked = fileName != null;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: picked ? AppColors.primary : AppColors.grey300,
            width: picked ? 2 : 1,
          ),
          color: picked ? AppColors.primary.withOpacity(0.04) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: picked
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                picked ? Icons.check_circle : icon,
                color: picked ? AppColors.primary : AppColors.grey500,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: picked ? AppColors.primary : AppColors.grey900)),
                  const SizedBox(height: 2),
                  Text(
                    picked ? fileName! : subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: picked ? AppColors.grey700 : AppColors.grey500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (picked)
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: onRemove,
              )
            else
              Icon(Icons.upload_file, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}