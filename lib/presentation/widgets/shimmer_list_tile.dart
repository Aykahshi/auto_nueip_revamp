import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// A shimmer placeholder widget mimicking the layout of [AttendanceListTile].
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  Widget _buildPlaceholder({double? width, double height = 14, Color? color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shimmerColor = colorScheme.onSurface.withValues(alpha: 0.08);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.5),
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            // Left side: Date and Weekday placeholder
            SizedBox(
              width: 65, // Match approximate width
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPlaceholder(width: 40, height: 16, color: shimmerColor),
                  const Gap(5),
                  _buildPlaceholder(width: 30, height: 12, color: shimmerColor),
                ],
              ),
            ),
            const VerticalDivider(
              width: 16,
              thickness: 1,
              indent: 5,
              endIndent: 5,
            ),
            // Middle: Details placeholder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlaceholder(
                      width: double.infinity,
                      color: shimmerColor,
                    ),
                    const Gap(5),
                    _buildPlaceholder(width: 100, color: shimmerColor),
                    const Gap(5),
                    _buildPlaceholder(
                      width: 120,
                      height: 10,
                      color: shimmerColor,
                    ), // Optional third line
                  ],
                ),
              ),
            ),
            const Gap(8),
            // Right side: Status Tag placeholder
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 75),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: shimmerColor.withValues(
                    alpha: 0.5,
                  ), // Lighter background
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: shimmerColor, // Use shimmer color for border too
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPlaceholder(
                      width: 14,
                      height: 14,
                      color: shimmerColor,
                    ),
                    const Gap(4),
                    _buildPlaceholder(
                      width: 35,
                      height: 12,
                      color: shimmerColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
