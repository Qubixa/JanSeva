// lib/presentation/screens/complaint/file_complaint_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/providers/complaint_provider.dart';

class FileComplaintScreen extends StatefulWidget {
  const FileComplaintScreen({Key? key}) : super(key: key);

  @override
  State<FileComplaintScreen> createState() => _FileComplaintScreenState();
}

class _FileComplaintScreenState extends State<FileComplaintScreen>
    with SingleTickerProviderStateMixin {
  // ── Step state ────────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // ── Form controllers ──────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // ── Selection state ───────────────────────────────────────────────────────
  ComplaintCategory? _selectedCategory;
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _headerAnim;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplaintProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0:
        return _selectedCategory != null;
      case 1:
        return _titleCtrl.text.trim().length >= 5 &&
            _descriptionCtrl.text.trim().length >= 10 &&
            _addressCtrl.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  void _tryNext() {
    if (!_canProceedFromStep(_currentStep)) {
      _showStepValidation();
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    } else {
      _submit();
    }
  }

  void _showStepValidation() {
    String msg = '';
    if (_currentStep == 0) msg = 'Please select a category to continue.';
    if (_currentStep == 1) {
      if (_titleCtrl.text.trim().length < 5) {
        msg = 'Title must be at least 5 characters.';
      } else if (_descriptionCtrl.text.trim().length < 10) {
        msg = 'Description must be at least 10 characters.';
      } else {
        msg = 'Please enter the location/address.';
      }
    }
    if (msg.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: const Color(0xFFFF9800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 4) {
      _showSnack('Maximum 4 images allowed.', isError: true);
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1280,
      );
      if (picked != null) {
        setState(() => _selectedImages.add(File(picked.path)));
      }
    } catch (_) {
      _showSnack('Could not access camera/gallery.', isError: true);
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  // ── Submission ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final provider = context.read<ComplaintProvider>();
    final success = await provider.createComplaint(
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      category: _selectedCategory!.code,
      address: _addressCtrl.text.trim(),
      imageFiles: _selectedImages.isEmpty ? null : _selectedImages,
    );

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      _showSnack(provider.error ?? 'Failed to submit complaint.', isError: true);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Color(0xFF4CAF50), size: 56),
              ),
              const SizedBox(height: 24),
              const Text(
                'Complaint Filed!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your complaint has been submitted and will be assigned to your ward officer shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF757575), height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go to My Complaints',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error : Icons.check_circle,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: Column(
        children: [
          _buildHeader(),
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepCategorySelection(
                  selectedCategory: _selectedCategory,
                  onSelect: (cat) => setState(() => _selectedCategory = cat),
                ),
                _StepComplaintDetails(
                  formKey: _formKey,
                  titleCtrl: _titleCtrl,
                  descriptionCtrl: _descriptionCtrl,
                  addressCtrl: _addressCtrl,
                ),
                _StepAttachAndReview(
                  selectedImages: _selectedImages,
                  selectedCategory: _selectedCategory,
                  title: _titleCtrl.text,
                  description: _descriptionCtrl.text,
                  address: _addressCtrl.text,
                  onPickGallery: () => _pickImage(ImageSource.gallery),
                  onPickCamera: () => _pickImage(ImageSource.camera),
                  onRemoveImage: _removeImage,
                ),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final stepTitles = ['Choose Category', 'Describe Issue', 'Review & Submit'];
    final stepSubs = [
      'What type of problem?',
      'Tell us the details',
      'Add photos & submit',
    ];

    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    if (_currentStep > 0) {
                      _goToStep(_currentStep - 1);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepTitles[_currentStep],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        stepSubs[_currentStep],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Step ${_currentStep + 1} of $_totalSteps',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Container(
      color: const Color(0xFFF57C00),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final done = i < _currentStep;
          final active = i == _currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _totalSteps - 1 ? 8 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: (done || active)
                      ? Colors.white
                      : Colors.white.withOpacity(0.35),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Consumer<ComplaintProvider>(
      builder: (_, provider, __) {
        final isLast = _currentStep == _totalSteps - 1;
        return Container(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Upload progress
              if (provider.isSubmitting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploading… ${(provider.uploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFFF9800)),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: provider.uploadProgress,
                        backgroundColor: AppColors.grey200,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9800)),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.isSubmitting ? null : _tryNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.grey300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: provider.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Submit Complaint' : 'Continue',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Icon(isLast
                                ? Icons.send_rounded
                                : Icons.arrow_forward_rounded),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STEP 1 — Category Selection
// ═══════════════════════════════════════════════════════════════════════════

class _StepCategorySelection extends StatelessWidget {
  final ComplaintCategory? selectedCategory;
  final ValueChanged<ComplaintCategory> onSelect;

  const _StepCategorySelection({
    required this.selectedCategory,
    required this.onSelect,
  });

  static const _categoryIcons = <String, IconData>{
    'road_potholes': Icons.warning_amber_rounded,
    'water_supply': Icons.water_drop,
    'electricity': Icons.bolt,
    'garbage': Icons.delete_outline_rounded,
    'sewerage': Icons.water,
    'streetlight': Icons.lightbulb_outline,
    'park': Icons.park,
    'drainage': Icons.water_damage_outlined,
    'building': Icons.apartment,
    'noise': Icons.hearing,
    'public_health': Icons.health_and_safety_outlined,
    'other': Icons.more_horiz,
  };

  IconData _iconFor(ComplaintCategory cat) {
    for (final entry in _categoryIcons.entries) {
      if (cat.code.toLowerCase().contains(entry.key) ||
          cat.name.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    return Icons.report_problem_outlined;
  }

  Color _colorForIndex(int i) {
    const palette = [
      Color(0xFFFF9800),
      Color(0xFF2196F3),
      Color(0xFF4CAF50),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
      Color(0xFFFF5722),
      Color(0xFF607D8B),
    ];
    return palette[i % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintProvider>(
      builder: (_, provider, __) {
        if (provider.categoriesLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF9800)),
          );
        }

        if (provider.categories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined,
                      size: 64, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  const Text('No categories available',
                      style: TextStyle(color: AppColors.grey700)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => provider.fetchCategories(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final cats = provider.categories;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Select the category that best describes your issue.',
                style: TextStyle(color: AppColors.grey700, fontSize: 14),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (_, i) {
                  final cat = cats[i];
                  final selected = selectedCategory?.code == cat.code;
                  final color = _colorForIndex(i);

                  return GestureDetector(
                    onTap: () => onSelect(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected ? color : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? color : AppColors.grey200,
                          width: selected ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selected
                                ? color.withOpacity(0.25)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: selected ? 16 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withOpacity(0.25)
                                  : color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _iconFor(cat),
                              color: selected ? Colors.white : color,
                              size: 24,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            cat.name,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.grey900,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (cat.department != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              cat.department!,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white.withOpacity(0.8)
                                    : AppColors.grey500,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STEP 2 — Complaint Details
// ═══════════════════════════════════════════════════════════════════════════

class _StepComplaintDetails extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController addressCtrl;

  const _StepComplaintDetails({
    required this.formKey,
    required this.titleCtrl,
    required this.descriptionCtrl,
    required this.addressCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _FieldCard(
              icon: Icons.title_rounded,
              label: 'Issue Title',
              child: TextFormField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDeco('e.g., Large pothole on main road'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.trim().length < 5) return 'At least 5 characters';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            _FieldCard(
              icon: Icons.description_rounded,
              label: 'Detailed Description',
              child: TextFormField(
                controller: descriptionCtrl,
                maxLines: 5,
                minLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDeco(
                    'Describe the problem in detail. When did it start? How severe is it?'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description required';
                  if (v.trim().length < 10) return 'At least 10 characters';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            _FieldCard(
              icon: Icons.location_on_rounded,
              label: 'Location / Address',
              child: TextFormField(
                controller: addressCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDeco('Street name, landmark, area…'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Address is required';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your complaint will be auto-assigned to your ward based on your registered address.',
                      style: TextStyle(
                        color: Color(0xFF6D4C41),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
        filled: true,
        fillColor: AppColors.grey100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFFF9800), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      );
}

class _FieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _FieldCard(
      {required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: const Color(0xFFFF9800), size: 17),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.grey900)),
              const Text(' *',
                  style: TextStyle(color: AppColors.error, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STEP 3 — Attach Photos & Review
// ═══════════════════════════════════════════════════════════════════════════

class _StepAttachAndReview extends StatelessWidget {
  final List<File> selectedImages;
  final ComplaintCategory? selectedCategory;
  final String title;
  final String description;
  final String address;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final ValueChanged<int> onRemoveImage;

  const _StepAttachAndReview({
    required this.selectedImages,
    required this.selectedCategory,
    required this.title,
    required this.description,
    required this.address,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo section
          _SectionHeader(icon: Icons.photo_camera_rounded, title: 'Attach Evidence (Optional)'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ImagePickerButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        onTap: onPickCamera,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ImagePickerButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: onPickGallery,
                      ),
                    ),
                  ],
                ),
                if (selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedImages.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (_, i) => Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(selectedImages[i],
                              fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => onRemoveImage(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${selectedImages.length}/4 photos added',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.grey500),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Review summary
          _SectionHeader(
              icon: Icons.preview_rounded, title: 'Review Summary'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ReviewRow('Category', selectedCategory?.name ?? '—',
                    Icons.category_rounded),
                const Divider(height: 1, color: AppColors.grey100),
                _ReviewRow('Title', title.isEmpty ? '—' : title,
                    Icons.title_rounded),
                const Divider(height: 1, color: AppColors.grey100),
                _ReviewRow(
                    'Description',
                    description.isEmpty ? '—' : description,
                    Icons.description_rounded,
                    multiLine: true),
                const Divider(height: 1, color: AppColors.grey100),
                _ReviewRow('Location', address.isEmpty ? '—' : address,
                    Icons.location_on_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF9800), size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.grey900)),
      ],
    );
  }
}

class _ImagePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ImagePickerButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFCC80)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFF9800), size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFFF9800),
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool multiLine;

  const _ReviewRow(this.label, this.value, this.icon,
      {this.multiLine = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment:
            multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.grey400, size: 16),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.grey500, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: AppColors.grey900,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
              maxLines: multiLine ? 4 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

extension _ColorExt on Color {
  Color withOpacity(double opacity) => Color.fromARGB(
        (255 * opacity).round(),
        red,
        green,
        blue,
      );
}