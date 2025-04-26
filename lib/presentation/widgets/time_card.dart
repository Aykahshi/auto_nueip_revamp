import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/extensions/theme_extensions.dart';

/// A card widget to display clock-in or clock-out time information.
class TimeCard extends StatelessWidget {
  /// The title text displayed on the card.
  final String title;

  /// The icon displayed next to the title.
  final IconData icon;

  /// The color of the icon.
  final Color iconColor;

  /// The time to display. Used when timeJoker is not provided.
  final DateTime? time;

  /// Whether the card is in loading state.
  final bool isLoading;

  /// Creates a TimeCard widget.
  /// Either [timeJoker] or [time] must be provided, or [isLoading] must be true.
  const TimeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    this.time,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = context.colorScheme.surfaceContainerHighest;
    final titleStyle = context.textTheme.bodyMedium?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontSize: context.sp(14),
    );
    final timeStyle = context.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: context.colorScheme.primary,
      fontSize: context.sp(22),
    );
    // For placeholder text
    final placeholderStyle = context.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: context.colorScheme.outline.withValues(alpha: 0.5),
      fontSize: context.sp(22),
    );

    return Card(
      elevation: 2.0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.r(12)),
        side: BorderSide(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: context.w(1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: context.r(18), color: iconColor),
                Gap(context.w(6)),
                Text(title, style: titleStyle),
              ],
            ),
            Gap(context.h(8)),
            isLoading.reveal(
              whenTrue: SizedBox(
                height: context.h(40),
                child: Center(
                  child: SizedBox(
                    width: context.r(20),
                    height: context.r(20),
                    child: CircularProgressIndicator(
                      strokeWidth: context.w(2),
                      color: context.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              whenFalse: _buildTimeDisplay(
                context,
                time,
                timeStyle,
                placeholderStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build time display widget
  Widget _buildTimeDisplay(
    BuildContext context,
    DateTime? time,
    TextStyle? timeStyle,
    TextStyle? placeholderStyle,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        // Fade and scale transition
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Text(
        // Use ValueKey to ensure AnimatedSwitcher recognizes the change
        key: ValueKey<DateTime?>(time),
        // Format time or display placeholder
        time == null ? '-- : -- : --' : DateFormat('HH : mm : ss').format(time),
        style: time == null ? placeholderStyle : timeStyle,
      ),
    );
  }
}
