import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/theme_extensions.dart'; // Import theme extension

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
        borderRadius: BorderRadius.circular(context.r(4)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shimmerColor = context.colorScheme.onSurface.withValues(alpha: 0.08);

    return Card(
      elevation: 0.5,
      margin: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(4.5),
      ),
      color: context.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(10),
        ),
        child: Row(
          children: [
            // Left side: Date and Weekday placeholder
            SizedBox(
              width: context.w(65),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPlaceholder(
                    context,
                    width: context.w(40),
                    height: context.h(16),
                    color: shimmerColor,
                  ),
                  Gap(context.h(5)),
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
              width: context.w(16),
              thickness: context.w(1),
              indent: context.h(5),
              endIndent: context.h(5),
            ),
            // Middle: Details placeholder
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: context.w(4)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlaceholder(
                      context,
                      width: double.infinity,
                      height: context.h(14),
                      color: shimmerColor,
                    ),
                    Gap(context.h(5)),
                    _buildPlaceholder(
                      context,
                      width: context.w(100),
                      height: context.h(14),
                      color: shimmerColor,
                    ),
                    Gap(context.h(5)),
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
            Gap(context.w(8)),
            // Right side: Status Tag placeholder
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: context.w(75)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(4),
                ),
                decoration: BoxDecoration(
                  color: shimmerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(context.r(12)),
                  border: Border.all(color: shimmerColor, width: context.w(1)),
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
                    Gap(context.w(4)),
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
