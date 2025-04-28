import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../core/extensions/theme_extensions.dart';
import '../screens/calendar_screen.dart';
import './shimmer_list_tile.dart';
import 'attendance_list_tile.dart';

class QueryResultList extends StatelessWidget {
  final bool isLoading;
  // Change List<AttendanceRecord> to List<AttendanceTileData>
  final List<AttendanceTileData> results;

  const QueryResultList({
    super.key,
    required this.isLoading,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Show shimmer effect while loading
      return ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) => const ShimmerListTile(),
      );
    }

    if (results.isEmpty) {
      return _buildEmptyState(context, '無查詢結果或請點擊查詢');
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        // Change type to AttendanceTileData
        final AttendanceTileData itemData = results[index];
        // Pass the entire itemData record to the tile
        return AttendanceListTile(
          tileData: itemData,
        ).animate().fadeIn(delay: (index * 30).ms).moveX(begin: -15);
      },
    );
  }
}

Widget _buildEmptyState(BuildContext context, String message) {
  return Center(
    key: ValueKey(message),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.calendar_month_outlined,
          size: context.r(64),
          color: context.colorScheme.outline.withValues(alpha: 0.7),
        ),
        Gap(context.h(16)),
        Text(
          message,
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colorScheme.outline,
            fontSize: context.sp(16),
          ),
        ),
      ],
    ),
  );
}
