import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';

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
    final cardColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    final timeStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );
    // For placeholder text
    final placeholderStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
    );

    return Card(
      elevation: 2.0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const Gap(6),
                Text(title, style: titleStyle),
              ],
            ),
            const Gap(8),
            isLoading.reveal(
              whenTrue: SizedBox(
                height: 40,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
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
