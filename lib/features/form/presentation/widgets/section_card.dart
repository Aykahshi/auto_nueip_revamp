import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/theme_extensions.dart';

/// A reusable card widget with consistent styling for form sections.
class SectionCard extends StatelessWidget {
  /// The list of widgets to display inside the card.
  final List<Widget> children;

  /// Creates a section card.
  const SectionCard({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5, // Subtle elevation
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          context.r(12),
        ), // Slightly more rounded
        side: BorderSide(
          color: context.colorScheme.outline.withValues(
            alpha: 0.2,
          ), // Subtle border
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(8),
        ), // Adjust padding
        child: Column(children: children),
      ),
    );
  }
}
