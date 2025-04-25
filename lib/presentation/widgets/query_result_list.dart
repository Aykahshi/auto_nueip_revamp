import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../screens/calendar_screen.dart'; // Import for AttendanceTileData
import './shimmer_list_tile.dart';
// Import the new tile for AttendanceRecord (assuming it exists or will be created)
// If ClockInListTile is adapted, keep it. If not, create AttendanceListTile
// For now, assume ClockInListTile will be adapted or we need a new one.
// Let's create a placeholder `AttendanceListTile` import and use it.
import 'attendance_list_tile.dart'; // Placeholder import

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
        return AttendanceListTile(tileData: itemData) // Pass record
        .animate().fadeIn(delay: (index * 30).ms).moveX(begin: -15);
      },
    );
  }
}
