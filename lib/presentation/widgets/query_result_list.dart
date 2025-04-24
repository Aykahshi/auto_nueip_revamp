import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Import the freezed entity
import '../../domain/entities/clock_in_data.dart';
import './shimmer_list_tile.dart';
import 'clock_in_list_tile.dart';

class QueryResultList extends StatelessWidget {
  final bool isLoading;
  final List<ClockInData> results;

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
      // Show shimmer effect while loading instead of just indicator
      return ListView.builder(
        itemCount: 8, // Show 8 shimmer items
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
        final ClockInData item = results[index];
        return ClockInListTile(item: item)
            .animate()
            .fadeIn(delay: (index * 30).ms)
            .moveX(begin: -15); // Adjusted animation
      },
    );
  }
}
