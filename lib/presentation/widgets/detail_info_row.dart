import 'package:flutter/material.dart';

/// A reusable widget to display a single row of information with an icon, label, and value.
class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor; // Optional color for the value text

  const DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
        children: [
          Icon(
            icon,
            size: 20,
            color:
                valueColor ??
                colorScheme.secondary, // Use provided color or secondary
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 70, // Fixed width for the label ensures alignment
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant, // Subtle label color
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor ?? colorScheme.onSurface,
              ),
              // Allow text to wrap if it's too long
              // overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
