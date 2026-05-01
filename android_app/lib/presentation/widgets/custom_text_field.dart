import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isPassword;
  final Widget? prefix;
  final Widget? suffix;
  final int maxLines;
  final int minLines;
  final bool enabled;
  final VoidCallback? onTap;
  final bool readOnly;

  const CustomTextField({
    Key? key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isPassword = false,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.minLines = 1,
    this.enabled = true,
    this.onTap,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.grey900,
              ),
            ),
          ),
        ],
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          validator: widget.validator,
          maxLines: _obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          enabled: widget.enabled,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grey400,
            ),
            prefixIcon: widget.prefix,
            suffixIcon: widget.isPassword
                ? GestureDetector(
              onTap: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
              child: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: AppColors.grey500,
              ),
            )
                : widget.suffix,
            filled: true,
            fillColor: widget.enabled ? AppColors.grey100 : AppColors.grey200,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}