import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/theme_extensions.dart';

/// A reusable row widget for triggering date/time pickers.
class PickerRow extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The label text to display.
  final String label;

  /// Callback function when the row is tapped.
  final VoidCallback onTap;

  /// Whether the value associated with this picker is selected.
  final bool isSelected;

  /// Creates a picker row.
  const PickerRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.r(4)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.h(12), // Increased vertical padding
          horizontal: context.w(0), // Use card's horizontal padding
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: context.w(14)),
              child: Icon(
                icon,
                color:
                    isSelected
                        ? context.colorScheme.primary
                        : context.colorScheme.secondary,
                size: context.r(22),
              ),
            ),
            Gap(context.w(16)), // Increased gap
            Expanded(
              child: Text(
                label,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontSize: context.sp(16),
                  color:
                      isSelected
                          ? context.colorScheme.onSurface
                          : context.colorScheme.outline,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: context.r(16),
              color: context.colorScheme.outline.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
