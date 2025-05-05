import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/theme_extensions.dart';

/// A reusable text form field with consistent styling.
class FormTextField extends StatelessWidget {
  /// The controller for the text field.
  final TextEditingController controller;

  /// The icon to display before the input area.
  final IconData icon;

  /// The text to display as the label.
  final String labelText;

  /// The text to display as a hint when the field is empty.
  final String hintText;

  /// The maximum number of lines for the input field.
  final int maxLines;

  /// A flag to indicate if this is a remark field for special styling.
  final bool isRemarkField;

  /// The animation delay for the field.
  final Duration delay;

  /// Callback function when the text changes.
  final ValueChanged<String>? onChanged;

  /// Creates a form text field.
  const FormTextField({
    required this.controller,
    required this.icon,
    required this.labelText,
    required this.hintText,
    required this.delay,
    this.maxLines = 1,
    this.isRemarkField = false,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          size: context.r(20),
          color: context.colorScheme.secondary,
        ),
        labelText: labelText,
        hintText: hintText,
        border: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.symmetric(
          vertical: context.h(12),
          horizontal: context.w(0), // Use card's padding
        ),
        // Apply different padding/alignment for remark field
        floatingLabelBehavior:
            isRemarkField
                ? FloatingLabelBehavior
                    .always // Keep label always visible
                : FloatingLabelBehavior.auto,
        isDense: isRemarkField, // Reduce vertical density for remark
        labelStyle: TextStyle(
          fontSize: context.sp(16),
          // Adjust label position slightly for remark
          height: isRemarkField ? 0.9 : null,
        ),
        hintStyle: TextStyle(
          fontSize: context.sp(16),
          color: context.colorScheme.outline,
        ),
        alignLabelWithHint: true, // Better alignment for multiline
      ),
      style: TextStyle(fontSize: context.sp(16)),
      maxLines: maxLines,
      onChanged: onChanged,
    ).animate().fadeIn(delay: delay).slideX(begin: -0.1);
  }
}
