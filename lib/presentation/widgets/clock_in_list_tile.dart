import 'package:flutter/material.dart';

import '../../domain/entities/clock_in_data.dart';

class ClockInListTile extends StatelessWidget {
  final ClockInData item;

  const ClockInListTile({super.key, required this.item});

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'normal':
        return Icons.check_circle_outline;
      case 'late':
        return Icons.watch_later_outlined;
      case 'absent':
        return Icons.person_off_outlined;
      case 'holiday':
        return Icons.celebration_outlined;
      default:
        return Icons.help_outline;
    }
  }

  static Color getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'normal':
        return Colors.green.shade600;
      case 'late':
        return Colors.orange.shade700;
      case 'absent':
        return colorScheme.error;
      case 'holiday':
        return Colors.blueGrey.shade400;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = ClockInListTile.getStatusColor(
      item.status,
      colorScheme,
    );
    final statusIcon = ClockInListTile.getStatusIcon(item.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          foregroundColor: statusColor,
          radius: 20,
          child: Icon(statusIcon, size: 20),
        ),
        title: Text(
          item.primaryInfo,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            item.secondaryInfo,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        dense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 8.0,
        ),
      ),
    );
  }
}
