import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      return Center(
        child:
            Text(
              '無查詢結果或請點擊查詢',
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontSize: context.sp(16),
              ),
            ).animate().fadeIn(),
      );
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
