// lib/presentation/screens/matrimonial/individual_registration_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/matrimonial_provider.dart';

class IndividualRegistrationScreen extends StatefulWidget {
  const IndividualRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<IndividualRegistrationScreen> createState() => _IndividualRegistrationScreenState();
}

class _IndividualRegistrationScreenState extends State<IndividualRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _educationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _religionController = TextEditingController();
  final _casteController = TextEditingController();
  final _heightController = TextEditingController();
  
  // Dropdown values
  String? _selectedGender;
  String? _selectedMaritalStatus;
  DateTime? _selectedDateOfBirth;
  
  // Files
  File? _profileImage;
  File? _bioDataFile;
  String? _bioDataFileName;
  File? _kundaliFile;
  String? _kundaliFileName;
  
  final _imagePicker = ImagePicker();
  
  final List<String> _genders = ['MALE', 'FEMALE', 'OTHER'];
  final List<String> _maritalStatuses = ['SINGLE', 'DIVORCED', 'WIDOWED'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _religionController.dispose();
    _casteController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) {
      setState(() => _selectedDateOfBirth = picked);
    }
  }

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
          ],
        ),
      ),
    );
  }

  Future<void> _pickBioData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _bioDataFile = File(result.files.single.path!);
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
        _kundaliFile = File(result.files.single.path!);
        _kundaliFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateOfBirth == null) {
      _showSnack('Please select date of birth', Colors.red);
      return;
    }
    if (_selectedGender == null) {
      _showSnack('Please select gender', Colors.red);
      return;
    }
    if (_selectedMaritalStatus == null) {
      _showSnack('Please select marital status', Colors.red);
      return;
    }

    final provider = context.read<MatrimonialProvider>();
    
    final success = await provider.registerIndividual(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      gender: _selectedGender!,
      dateOfBirth: _selectedDateOfBirth!,
      maritalStatus: _selectedMaritalStatus!,
      location: _locationController.text.trim(),
      religion: _religionController.text.trim().isNotEmpty ? _religionController.text.trim() : null,
      caste: _casteController.text.trim().isNotEmpty ? _casteController.text.trim() : null,
      height: _heightController.text.trim().isNotEmpty ? _heightController.text.trim() : null,
      occupation: _occupationController.text.trim().isNotEmpty ? _occupationController.text.trim() : null,
      education: _educationController.text.trim().isNotEmpty ? _educationController.text.trim() : null,
      bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
      profileImage: _profileImage,
      bioData: _bioDataFile,
      kundali: _kundaliFile,
    );

    if (!mounted) return;

    if (success) {
      _showSnack('Registration successful!', Colors.green);
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
        title: const Text('Individual Registration'),
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
              _buildProfileImagePicker(),
              const SizedBox(height: 24),
              
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 16),
              _buildTextField(_firstNameController, 'First Name *', Icons.person,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              _buildTextField(_lastNameController, 'Last Name *', Icons.person_outline,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              _buildTextField(_emailController, 'Email *', Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              _buildTextField(_phoneController, 'Phone *', Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              
              _buildDatePicker(),
              _buildDropdown('Gender *', Icons.wc, _genders, _selectedGender,
                  (v) => setState(() => _selectedGender = v)),
              _buildDropdown('Marital Status *', Icons.favorite, _maritalStatuses, _selectedMaritalStatus,
                  (v) => setState(() => _selectedMaritalStatus = v)),
              _buildTextField(_locationController, 'Location/City *', Icons.location_on,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Additional Information'),
              const SizedBox(height: 16),
              _buildTextField(_religionController, 'Religion', Icons.temple_buddhist),
              _buildTextField(_casteController, 'Caste', Icons.group),
              _buildTextField(_heightController, 'Height (e.g., 5\'8")', Icons.height),
              _buildTextField(_occupationController, 'Occupation', Icons.work),
              _buildTextField(_educationController, 'Education', Icons.school),
              
              const SizedBox(height: 24),
              _buildSectionTitle('About You'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell us about yourself...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Documents'),
              const SizedBox(height: 4),
              Text('Bio-data is required. Kundali is optional.',
                  style: TextStyle(fontSize: 13, color: AppColors.grey500)),
              const SizedBox(height: 16),
              _buildDocumentPicker(
                label: 'Bio Data *',
                subtitle: 'PDF, JPG or PNG (max 10 MB)',
                icon: Icons.description,
                fileName: _bioDataFileName,
                onPick: _pickBioData,
                onRemove: () => setState(() { _bioDataFile = null; _bioDataFileName = null; }),
              ),
              const SizedBox(height: 12),
              _buildDocumentPicker(
                label: 'Kundali (Optional)',
                subtitle: 'PDF, JPG or PNG (max 10 MB)',
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
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                            Text('Add Photo', style: TextStyle(fontSize: 11, color: AppColors.primary)),
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

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildDatePicker() => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: _selectDateOfBirth,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date of Birth *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.cake),
            ),
            child: Text(
              _selectedDateOfBirth != null
                  ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                  : 'Select date',
              style: TextStyle(color: _selectedDateOfBirth != null ? Colors.black : Colors.grey),
            ),
          ),
        ),
      );

  Widget _buildDropdown(String label, IconData icon, List<String> items, String? value,
      void Function(String?) onChanged) =>
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
          validator: (v) => v == null ? 'Required' : null,
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
          border: Border.all(color: picked ? AppColors.primary : AppColors.grey300, width: picked ? 2 : 1),
          color: picked ? AppColors.primary.withOpacity(0.04) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: picked ? AppColors.primary.withOpacity(0.12) : AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(picked ? Icons.check_circle : icon, color: picked ? AppColors.primary : AppColors.grey500),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: picked ? AppColors.primary : null)),
                  const SizedBox(height: 2),
                  Text(picked ? fileName! : subtitle,
                      style: TextStyle(fontSize: 12, color: picked ? AppColors.grey700 : AppColors.grey500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (picked)
              IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.red), onPressed: onRemove)
            else
              Icon(Icons.upload_file, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}