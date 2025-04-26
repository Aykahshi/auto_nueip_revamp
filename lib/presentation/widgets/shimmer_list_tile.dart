import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../core/extensions/theme_extensions.dart'; // Import theme extension

/// A shimmer placeholder widget mimicking the layout of [AttendanceListTile].
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  Widget _buildPlaceholder(
    BuildContext context, {
    double? width,
    double? height,
    Color? color,
  }) {
    // Ensure height has a default value handled by screenutil
    final placeholderHeight = height ?? context.h(14);
    return Container(
      width: width,
      height: placeholderHeight,
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade300,
        borderRadius: BorderRadius.circular(context.r(4)), // Use context.r
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shimmerColor = context.colorScheme.onSurface.withValues(
      alpha: 0.08,
    ); // Use context.colorScheme

    return Card(
      elevation: 0.5,
      margin: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(4.5),
      ), // Use context.w/h
      color:
          context
              .colorScheme
              .surfaceContainerHighest, // Use context.colorScheme
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.r(10)),
      ), // Use context.r
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(10),
        ), // Use context.w/h
        child: Row(
          children: [
            // Left side: Date and Weekday placeholder
            SizedBox(
              width: context.w(65), // Use context.w
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPlaceholder(
                    context,
                    width: context.w(40),
                    height: context.h(16),
                    color: shimmerColor,
                  ),
                  Gap(context.h(5)), // Use context.h
                  _buildPlaceholder(
                    context,
                    width: context.w(30),
                    height: context.h(12),
                    color: shimmerColor,
                  ),
                ],
              ),
            ),
            VerticalDivider(
              width: context.w(16), // Use context.w
              thickness: context.w(1), // Use context.w
              indent: context.h(5), // Use context.h
              endIndent: context.h(5), // Use context.h
            ),
            // Middle: Details placeholder
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: context.w(4)), // Use context.w
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlaceholder(
                      context,
                      width: double.infinity,
                      height: context.h(14), // Explicitly provide height
                      color: shimmerColor,
                    ),
                    Gap(context.h(5)), // Use context.h
                    _buildPlaceholder(
                      context,
                      width: context.w(100),
                      height: context.h(14),
                      color: shimmerColor,
                    ),
                    Gap(context.h(5)), // Use context.h
                    _buildPlaceholder(
                      context,
                      width: context.w(120),
                      height: context.h(10),
                      color: shimmerColor,
                    ), // Optional third line
                  ],
                ),
              ),
            ),
            Gap(context.w(8)), // Use context.w
            // Right side: Status Tag placeholder
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: context.w(75),
              ), // Use context.w
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(4),
                ), // Use context.w/h
                decoration: BoxDecoration(
                  color: shimmerColor.withValues(
                    alpha: 0.5,
                  ), // Lighter background
                  borderRadius: BorderRadius.circular(
                    context.r(12),
                  ), // Use context.r
                  border: Border.all(
                    color: shimmerColor, // Use shimmer color for border too
                    width: context.w(1), // Use context.w
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPlaceholder(
                      context,
                      width: context.w(14),
                      height: context.h(14),
                      color: shimmerColor,
                    ),
                    Gap(context.w(4)), // Use context.w
                    _buildPlaceholder(
                      context,
                      width: context.w(35),
                      height: context.h(12),
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
