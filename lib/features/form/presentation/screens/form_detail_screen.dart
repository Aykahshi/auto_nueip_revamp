import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../data/models/leave_record.dart'; // Import LeaveRecord
import '../widgets/leave_form_details.dart'; // Import the new widget
import 'form_screen.dart'; // Import FormHistoryType and mock data

@RoutePage()
class FormDetailScreen extends StatelessWidget {
  // Updated parameters
  final FormHistoryType formType;
  final String formId; // Represents qryNo, now required
  final LeaveRecord? leaveRecord; // Still nullable for expense type

  FormDetailScreen({
    super.key,
    required this.formType,
    required this.formId, // Make formId required
    this.leaveRecord,
    // Update assertion: formId is always required
    // leaveRecord is required only when formType is leave
  }) : assert(formId.isNotEmpty, 'formId (qryNo) cannot be empty'),
       assert(
         (formType == FormHistoryType.expense) ||
             (formType == FormHistoryType.leave && leaveRecord != null),
         'leaveRecord must be provided when formType is leave',
       );

  // --- Helper for Mock Expense Data ---
  Color _getMockExpenseStatusColor(FormStatus status, BuildContext context) {
    // This helper uses the FormStatus enum for mock data
    switch (status) {
      case FormStatus.approved:
        return Colors.green.shade600;
      case FormStatus.pending:
        return Colors.orange.shade700;
      case FormStatus.rejected:
        return context.colorScheme.error;
    }
  }
  // --- End Mock Expense Helper ---

  @override
  Widget build(BuildContext context) {
    // Determine title based on type
    final String title = formType == FormHistoryType.leave ? '請假詳情' : '請款詳情';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: const AutoLeadingButton(),
        centerTitle: true,
        elevation: 1,
      ),
      // Build body based on type
      body:
          formType == FormHistoryType.leave
              ? leaveRecord != null
                  ? LeaveFormDetails(leaveRecord: leaveRecord!)
                  : _buildNotFound(context)
              : _buildExpenseDetails(context), // Keep using mock for expense
    );
  }

  // Build Expense Details View (Uses mock data for now)
  Widget _buildExpenseDetails(BuildContext context) {
    // Find the mock expense data based on formId using manual iteration
    MockExpenseRequest? data;
    for (final item in mockExpenseData) {
      if (item.id == formId) {
        data = item;
        break;
      }
    }
    // final data = mockExpenseData.firstWhereOrNull((d) => d.id == formId);

    if (data == null) {
      return _buildNotFound(context);
    }

    // Copied/Adapted from old _buildDetails logic for expense
    final dateFormat = DateFormat('yyyy/MM/dd');
    final amountFormat = NumberFormat.currency(
      locale: 'zh_TW',
      symbol: 'NT\$',
      decimalDigits: 0,
    );
    // Use the correctly scoped helper for mock data
    final statusColor = _getMockExpenseStatusColor(data.status, context);

    return ListView(
      padding: EdgeInsets.all(context.i(16)),
      children: [
        _buildDetailItem(
          context,
          icon: Icons.person_outline,
          label: '申請人',
          value: data.applicant,
        ),
        _buildDetailItem(
          context,
          icon: Icons.category_outlined,
          label: '請款類型',
          value: data.expenseType,
        ),
        _buildDetailItem(
          context,
          icon: Icons.receipt_long_outlined,
          label: '表單編號',
          value: formId,
        ),
        _buildDetailItem(
          context,
          icon: Icons.calendar_today_outlined,
          label: '申請日期',
          value: dateFormat.format(data.requestDate),
        ),
        _buildDetailItem(
          context,
          icon: Icons.attach_money_outlined,
          label: '申請金額',
          value: amountFormat.format(data.amount),
          valueColor: context.colorScheme.primary,
        ),
        _buildDetailItem(
          context,
          icon: Icons.info_outline,
          label: '狀態',
          value: data.status.name.toUpperCase(),
          valueColor: statusColor,
        ),
        // Add Stepper for expense if needed later
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  // Not found widget (remains the same)
  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: context.r(64),
            color: context.colorScheme.outline.withValues(alpha: 0.7),
          ),
          Gap(context.h(16)),
          Text(
            '找不到指定的表單紀錄',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.outline,
              fontSize: context.sp(16),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // Generic detail item builder (copied from old implementation)
  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    int? maxLines = 1, // Allow maxLines override
  }) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)), // Reduced padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: context.r(18),
            color: colorScheme.secondary,
          ), // Slightly smaller icon
          Gap(context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.outline,
                    fontSize: context.sp(13),
                  ),
                ),
                Gap(context.h(3)),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    // Use bodyMedium for consistency
                    color: valueColor ?? colorScheme.onSurface,
                    fontSize: context.sp(14),
                    // fontWeight: FontWeight.w500, // Removed bold
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
