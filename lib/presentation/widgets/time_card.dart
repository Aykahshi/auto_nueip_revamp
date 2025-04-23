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

  /// The Joker holding the DateTime state to display. Null indicates no time recorded yet.
  final Joker<DateTime?> timeJoker;

  /// Creates a TimeCard widget.
  const TimeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.timeJoker,
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
    // Use outline color with reduced alpha for placeholder
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
            // Observe the timeJoker to update the displayed time
            timeJoker.perform(
              builder: (context, time) {
                // Use AnimatedSwitcher for smooth transition when time changes
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
                    time == null
                        ? '-- : -- : --'
                        : DateFormat('HH : mm : ss').format(time),
                    style: time == null ? placeholderStyle : timeStyle,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
