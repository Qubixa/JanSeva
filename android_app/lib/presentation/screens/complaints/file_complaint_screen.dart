import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/complaint_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class FileComplaintScreen extends StatefulWidget {
  const FileComplaintScreen({Key? key}) : super(key: key);

  @override
  State<FileComplaintScreen> createState() => _FileComplaintScreenState();
}

class _FileComplaintScreenState extends State<FileComplaintScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  void _fetchCategories() {
    context.read<ComplaintProvider>().fetchCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFFFF9800),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFF9800),
                          const Color(0xFFFF9800).withOpacity(0.8),
                          const Color(0xFFF57C00),
                        ],
                      ),
                    ),
                  ),
                  // Decorative elements
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Title
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.report_problem,
                              color: AppColors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'File Complaint',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Report civic issues in your ward',
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF9800).withOpacity(0.1),
                                const Color(0xFFF57C00).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFF9800).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: AppColors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Your complaint will be automatically assigned to your ward and tracked for resolution.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey900,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Card
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.grey300.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Dropdown
                                Consumer<ComplaintProvider>(
                                  builder: (context, complaintProvider, _) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF9800).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.category,
                                                size: 20,
                                                color: Color(0xFFFF9800),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Category',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: AppColors.grey900,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '*',
                                              style: TextStyle(
                                                color: AppColors.error,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (complaintProvider.categoriesLoading)
                                          const SizedBox(
                                            height: 56,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                                              ),
                                            ),
                                          )
                                        else if (complaintProvider.categories.isEmpty)
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.grey100,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppColors.grey300),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.warning_amber, color: AppColors.grey500, size: 20),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'No categories available',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: AppColors.grey700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          DropdownButtonFormField<String>(
                                            value: _selectedCategory,
                                            items: complaintProvider.categories
                                                .map((category) => DropdownMenuItem(
                                              value: category,
                                              child: Text(category),
                                            ))
                                                .toList(),
                                            onChanged: (value) {
                                              setState(() => _selectedCategory = value);
                                            },
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: AppColors.grey100,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: AppColors.grey300),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: AppColors.grey300),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: AppColors.error),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              hintText: 'Select a category',
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please select a category';
                                              }
                                              return null;
                                            },
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Title Field
                                _buildFieldLabel(context, Icons.title, 'Issue Title', true),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  hint: 'Brief title of the issue',
                                  controller: _titleController,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Title is required';
                                    if ((value?.length ?? 0) < 5) return 'Title must be at least 5 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Description Field
                                _buildFieldLabel(context, Icons.description, 'Description', true),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  hint: 'Describe the issue in detail',
                                  controller: _descriptionController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 5,
                                  minLines: 5,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Description is required';
                                    if ((value?.length ?? 0) < 10) return 'Description must be at least 10 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Address Field
                                _buildFieldLabel(context, Icons.location_on, 'Location/Address', true),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  hint: 'Where is the issue located?',
                                  controller: _addressController,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Location is required';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        Consumer<ComplaintProvider>(
                          builder: (context, complaintProvider, _) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9800).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: complaintProvider.isLoading
                                    ? null
                                    : () {
                                  if (_formKey.currentState!.validate()) {
                                    _handleSubmit(context, complaintProvider);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9800),
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: complaintProvider.isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                  ),
                                )
                                    : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.send, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Submit Complaint',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, IconData icon, String label, bool required) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFFFF9800)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.grey900,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleSubmit(BuildContext context, ComplaintProvider complaintProvider) async {
    final success = await complaintProvider.createComplaint(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      address: _addressController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.white),
                const SizedBox(width: 12),
                const Expanded(child: Text('Complaint submitted successfully!')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(complaintProvider.error ?? 'Failed to submit complaint')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
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