import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/theme_extensions.dart';

/// Builds the themed wrapper for the time picker dialog.
Widget buildTimePickerTheme({
  required BuildContext context,
  required Widget? child,
}) {
  final colorScheme = context.colorScheme;
  final textTheme = context.textTheme;

  return Theme(
    data: Theme.of(context).copyWith(
      timePickerTheme: TimePickerThemeData(
        backgroundColor:
            colorScheme.surfaceContainerLow, // Use lower surface for base
        // Dial styling
        dialBackgroundColor: colorScheme.surfaceContainer,
        dialHandColor: colorScheme.primary,
        dialTextColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected)
                  ? colorScheme
                      .onPrimary // Text on dial (selected number)
                  : colorScheme.onSurfaceVariant,
        ), // Text on dial (unselected number)
        // Hour/Minute display (top left)
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected)
                  ? colorScheme
                      .primary // Selected Hour/Minute text
                  : colorScheme.onSurfaceVariant,
        ), // Unselected Hour/Minute text
        hourMinuteColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected)
                  ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : colorScheme.surfaceContainerHighest,
        ), // Background for unselected HM
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(8)),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        // Day Period (AM/PM) styling
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected)
                  ? colorScheme
                      .onPrimary // Selected AM/PM text
                  : colorScheme.onSurfaceVariant,
        ), // Unselected AM/PM text
        dayPeriodColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected)
                  ? colorScheme
                      .primary // Selected AM/PM background
                  : colorScheme.surfaceContainerHighest,
        ), // Unselected AM/PM background
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(8)),
          side: BorderSide.none, // Remove border
        ),
        dayPeriodBorderSide: BorderSide(
          color: colorScheme.outline.withValues(
            alpha: 0.3,
          ), // Subtle border color
          width: 1,
        ),
        // Input mode styling
        inputDecorationTheme: InputDecorationTheme(
          border: InputBorder.none,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          hintStyle: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: context.w(12)),
          labelStyle: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        // General shape and text styles
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            context.r(24),
          ), // Slightly larger radius
        ),
        hourMinuteTextStyle: textTheme.displayLarge?.copyWith(
          fontSize: context.sp(48),
          fontWeight: FontWeight.w500, // Reduced weight
        ),
        dayPeriodTextStyle: textTheme.labelMedium?.copyWith(
          fontSize: context.sp(12),
          fontWeight: FontWeight.w600,
        ),
        helpTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: context.sp(14),
        ),
      ),
      // Button styling
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: context.sp(14),
            fontWeight: FontWeight.bold,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
        ),
      ),
    ),
    child: child!,
  );
}
