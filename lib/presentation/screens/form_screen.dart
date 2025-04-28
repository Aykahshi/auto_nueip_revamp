import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../core/extensions/theme_extensions.dart';
import '../../core/router/app_router.dart';
import '../../domain/entities/form_history_query.dart';
import '../widgets/filter_area.dart';

// --- Mock Data Definitions (can be moved later) ---

enum FormStatus { pending, approved, rejected }

class MockLeaveRequest {
  final String id;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final FormStatus status;
  final String applicant;

  MockLeaveRequest({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.applicant,
  });
}

class MockExpenseRequest {
  final String id;
  final String expenseType;
  final double amount;
  final DateTime requestDate;
  final FormStatus status;
  final String applicant;

  MockExpenseRequest({
    required this.id,
    required this.expenseType,
    required this.amount,
    required this.requestDate,
    required this.status,
    required this.applicant,
  });
}

final List<MockLeaveRequest> mockLeaveData = [
  MockLeaveRequest(
    id: 'L001',
    leaveType: '特休',
    startDate: DateTime(2023, 10, 26),
    endDate: DateTime(2023, 10, 26),
    status: FormStatus.approved,
    applicant: '王大明',
  ),
  MockLeaveRequest(
    id: 'L002',
    leaveType: '病假',
    startDate: DateTime(2023, 11, 1),
    endDate: DateTime(2023, 11, 2),
    status: FormStatus.pending,
    applicant: '陳小美',
  ),
  MockLeaveRequest(
    id: 'L003',
    leaveType: '事假',
    startDate: DateTime(2023, 11, 5),
    endDate: DateTime(2023, 11, 5),
    status: FormStatus.rejected,
    applicant: '王大明',
  ),
];

final List<MockExpenseRequest> mockExpenseData = [
  MockExpenseRequest(
    id: 'E001',
    expenseType: '交通費',
    amount: 350.0,
    requestDate: DateTime(2023, 10, 28),
    status: FormStatus.approved,
    applicant: '李四',
  ),
  MockExpenseRequest(
    id: 'E002',
    expenseType: '餐費',
    amount: 1200.5,
    requestDate: DateTime(2023, 11, 3),
    status: FormStatus.pending,
    applicant: '張三',
  ),
];

// --- End of Mock Data ---

enum FormHistoryType { leave, expense }

// --- Router Wrapper Screen ---
@RoutePage()
class FormScreen extends StatelessWidget {
  const FormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This screen just provides the nested router outlet
    return const AutoRouter();
  }
}

// --- Actual UI Screen for History ---
@RoutePage()
class FormHistoryScreen extends StatefulWidget {
  const FormHistoryScreen({super.key});

  @override
  State<FormHistoryScreen> createState() => _FormHistoryScreenState();
}

class _FormHistoryScreenState extends State<FormHistoryScreen> {
  // Use Joker to manage the *applied* query state
  late final Joker<FormHistoryQuery> _historyJoker;

  // Temporary state for date selection before query
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    _historyJoker = Joker<FormHistoryQuery>(
      // Initialize with default query (no date filter)
      const FormHistoryQuery(historyType: FormHistoryType.leave),
    );
    // Initialize temp dates based on joker state (optional, start clean)
    // _tempStartDate = _historyJoker.state.startDate;
    // _tempEndDate = _historyJoker.state.endDate;
  }

  void _showDateRangePickerInSheet() {
    // Use temp dates for initial selection
    PickerDateRange? initialRange;
    if (_tempStartDate != null && _tempEndDate != null) {
      initialRange = PickerDateRange(_tempStartDate!, _tempEndDate!);
    } else if (_tempStartDate != null) {
      initialRange = PickerDateRange(_tempStartDate!, _tempStartDate!);
    }

    PickerDateRange? currentSheetSelection = initialRange;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final sheetTheme = sheetContext.theme;
        final sheetColorScheme = sheetTheme.colorScheme;
        final safeAreaBottom = MediaQuery.viewInsetsOf(sheetContext).bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: safeAreaBottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            decoration: BoxDecoration(
              color: sheetColorScheme.surfaceContainer,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.r(20)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.h(10)),
                  child: Container(
                    width: context.w(40),
                    height: context.h(5),
                    decoration: BoxDecoration(
                      color: sheetColorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(context.r(10)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                  child: Text(
                    // Read history type from Joker state
                    _historyJoker.state.historyType == FormHistoryType.leave
                        ? "篩選請假日期"
                        : "篩選請款申請日期",
                    style: sheetTheme.textTheme.titleLarge?.copyWith(
                      color: sheetColorScheme.onSurface,
                      fontSize: context.sp(22),
                    ),
                  ),
                ),
                Divider(height: context.h(16), thickness: context.w(0.5)),
                Flexible(
                  child: SfDateRangePicker(
                    initialSelectedRange: currentSheetSelection,
                    onSelectionChanged: (args) {
                      if (args.value is PickerDateRange) {
                        currentSheetSelection = args.value;
                      }
                    },
                    selectionMode: DateRangePickerSelectionMode.range,
                    view: DateRangePickerView.month,
                    backgroundColor: Colors.transparent,
                    monthViewSettings: DateRangePickerMonthViewSettings(
                      firstDayOfWeek: 1,
                      viewHeaderStyle: DateRangePickerViewHeaderStyle(
                        textStyle: TextStyle(
                          color: sheetColorScheme.onSurfaceVariant,
                          fontSize: context.sp(12),
                        ),
                      ),
                    ),
                    headerStyle: DateRangePickerHeaderStyle(
                      backgroundColor: Colors.transparent,
                      textAlign: TextAlign.center,
                      textStyle: sheetTheme.textTheme.titleMedium?.copyWith(
                        color: sheetColorScheme.onSurface,
                        fontSize: context.sp(16),
                      ),
                    ),
                    monthCellStyle: DateRangePickerMonthCellStyle(
                      textStyle: TextStyle(
                        color: sheetColorScheme.onSurface,
                        fontSize: context.sp(14),
                      ),
                      todayTextStyle: TextStyle(
                        color: sheetColorScheme.primary,
                        fontSize: context.sp(14),
                      ),
                      todayCellDecoration: BoxDecoration(
                        border: Border.all(color: sheetColorScheme.primary),
                        shape: BoxShape.circle,
                      ),
                      disabledDatesTextStyle: TextStyle(
                        color: sheetColorScheme.outline.withValues(alpha: 0.5),
                        fontSize: context.sp(14),
                      ),
                    ),
                    yearCellStyle: DateRangePickerYearCellStyle(
                      textStyle: TextStyle(
                        color: sheetColorScheme.onSurface,
                        fontSize: context.sp(14),
                      ),
                      todayTextStyle: TextStyle(
                        color: sheetColorScheme.primary,
                        fontSize: context.sp(14),
                      ),
                      disabledDatesTextStyle: TextStyle(
                        color: sheetColorScheme.outline.withValues(alpha: 0.5),
                        fontSize: context.sp(14),
                      ),
                    ),
                    rangeSelectionColor: sheetColorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    startRangeSelectionColor: sheetColorScheme.primary,
                    endRangeSelectionColor: sheetColorScheme.primary,
                    selectionTextStyle: TextStyle(
                      color: sheetColorScheme.onPrimary,
                      fontSize: context.sp(14),
                    ),
                    rangeTextStyle: TextStyle(
                      color: sheetColorScheme.onPrimaryContainer,
                      fontSize: context.sp(14),
                    ),
                    minDate: DateTime(2010),
                    maxDate: DateTime(2030),
                    showNavigationArrow: true,
                    showActionButtons: false,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(16),
                    vertical: context.h(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text(
                          '取消',
                          style: TextStyle(
                            color: sheetColorScheme.secondary,
                            fontSize: context.sp(14),
                          ),
                        ),
                        onPressed: () => sheetContext.router.pop(),
                      ),
                      Gap(context.w(8)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sheetColorScheme.primary,
                          foregroundColor: sheetColorScheme.onPrimary,
                        ),
                        child: const Text('確定'),
                        onPressed: () {
                          if (currentSheetSelection?.startDate != null) {
                            final newStartDate = DateUtils.dateOnly(
                              currentSheetSelection!.startDate!,
                            );
                            final newEndDate =
                                currentSheetSelection!.endDate != null
                                    ? DateUtils.dateOnly(
                                      currentSheetSelection!.endDate!,
                                    )
                                    : newStartDate;
                            // Update temp dates using setState
                            setState(() {
                              _tempStartDate = newStartDate;
                              _tempEndDate = newEndDate;
                            });
                            // DO NOT update _historyJoker here
                            // _historyJoker.trickWith(
                            //   (state) => state.copyWith(
                            //     startDate: newStartDate,
                            //     endDate: newEndDate,
                            //   ),
                            // );
                          }
                          sheetContext.router.pop();
                        },
                      ),
                    ],
                  ),
                ),
                Gap(context.h(20)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to set temporary date range
  void _setTempRange(DateTime start, DateTime end) {
    final normStart = DateUtils.dateOnly(start);
    final normEnd = DateUtils.dateOnly(end);
    setState(() {
      _tempStartDate = normStart;
      _tempEndDate = normEnd;
    });
  }

  void _setRangeToYesterday() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    _setTempRange(y, y);
  }

  void _setRangeToToday() {
    final n = DateTime.now();
    _setTempRange(n, n);
  }

  void _setRangeToThisWeek() {
    final n = DateTime.now();
    final startOfWeek = n.subtract(Duration(days: n.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    _setTempRange(startOfWeek, endOfWeek);
  }

  void _setRangeToThisMonth() {
    final n = DateTime.now();
    final firstDay = DateTime(n.year, n.month, 1);
    final lastDay = DateTime(n.year, n.month + 1, 0);
    _setTempRange(firstDay, lastDay);
  }

  void _clearQuery() {
    // Clear temporary dates
    setState(() {
      _tempStartDate = null;
      _tempEndDate = null;
    });
    // Also clear applied dates in Joker state immediately?
    // Or only clear applied on next query? Let's clear applied immediately.
    _historyJoker.trickWith(
      (state) => state.copyWith(startDate: null, endDate: null),
    );
  }

  // This function is now called ONLY when the query button is pressed
  void _performQuery() {
    // Apply the temporary dates to the Joker state
    _historyJoker.trickWith(
      (state) =>
          state.copyWith(startDate: _tempStartDate, endDate: _tempEndDate),
    );
    debugPrint(
      'Performing query for: ${_historyJoker.state.startDate} to ${_historyJoker.state.endDate}',
    );
    // You might trigger data fetching here based on _historyJoker.state
  }

  // Helper to get status color
  Color _getStatusColor(FormStatus status, BuildContext context) {
    switch (status) {
      case FormStatus.approved:
        return Colors.green.shade600;
      case FormStatus.pending:
        return Colors.orange.shade700;
      case FormStatus.rejected:
        return context.colorScheme.error;
    }
  }

  // Helper to get status icon
  IconData _getStatusIcon(FormStatus status) {
    switch (status) {
      case FormStatus.approved:
        return Icons.check_circle_outline;
      case FormStatus.pending:
        return Icons.hourglass_empty_outlined;
      case FormStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('表單專區'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.build_outlined, size: context.r(64)),
            Gap(context.h(16)),
            Text(
              '開發中',
              style: context.textTheme.titleLarge?.copyWith(
                fontSize: context.sp(22),
              ),
            ),
          ],
        ),
      ),
    );

    // Use Joker.perform to listen to *applied* state changes
    return _historyJoker.perform(
      builder: (context, historyState) {
        // historyState is FormHistoryQuery
        return Scaffold(
          appBar: AppBar(
            title: Text(
              historyState.historyType == FormHistoryType.leave
                  ? '請假紀錄'
                  : '請款紀錄',
            ),
            centerTitle: true,
            elevation: 1,
            actions: [
              IconButton(
                icon: Icon(
                  historyState.historyType == FormHistoryType.leave
                      ? Icons.receipt_long_outlined
                      : Icons.edit_calendar_outlined,
                ),
                tooltip:
                    historyState.historyType == FormHistoryType.leave
                        ? '切換至請款紀錄'
                        : '切換至請假紀錄',
                onPressed: () {
                  final nextType =
                      historyState.historyType == FormHistoryType.leave
                          ? FormHistoryType.expense
                          : FormHistoryType.leave;
                  // Clear temporary dates
                  setState(() {
                    _tempStartDate = null;
                    _tempEndDate = null;
                  });
                  // Update Joker state: change type and clear applied dates
                  _historyJoker.trickWith(
                    (state) => state.copyWith(
                      historyType: nextType,
                      startDate: null, // Clear applied dates on type switch
                      endDate: null,
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              FilterArea(
                // Pass temporary dates to FilterArea for display
                selectedStartDate: _tempStartDate,
                selectedEndDate: _tempEndDate,
                onSelectRange: _showDateRangePickerInSheet,
                onSetYesterday: _setRangeToYesterday,
                onSetToday: _setRangeToToday,
                onSetThisWeek: _setRangeToThisWeek,
                onSetThisMonth: _setRangeToThisMonth,
                onClear: _clearQuery,
                onQuery: _performQuery, // Trigger query application
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child:
                      // Build list based on *applied* filter state from Joker
                      historyState.historyType == FormHistoryType.leave
                          ? _buildLeaveHistoryList(
                            context,
                            historyState.startDate, // Use applied start date
                            historyState.endDate, // Use applied end date
                          )
                          : _buildExpenseHistoryList(
                            context,
                            historyState.startDate, // Use applied start date
                            historyState.endDate, // Use applied end date
                          ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.router.push(const ApplyFormRoute());
            },
            label: const Text('申請新表單'),
            icon: const Icon(Icons.add),
            tooltip: '申請請假或請款單',
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5),
        );
      },
    );
  }

  // Builds the list for Leave History
  Widget _buildLeaveHistoryList(
    BuildContext context,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final filteredData =
        mockLeaveData.where((req) {
          if (startDate == null || endDate == null) return true;
          return !(req.endDate.isBefore(startDate) ||
              req.startDate.isAfter(endDate));
        }).toList();

    if (filteredData.isEmpty) {
      return _buildEmptyState(context, '此區間尚無請假紀錄');
    }
    return ListView.builder(
      key: const ValueKey('leave_list'),
      padding: EdgeInsets.all(context.i(12)),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final request = filteredData[index];
        final statusColor = _getStatusColor(request.status, context);
        final statusIcon = _getStatusIcon(request.status);
        final dateFormat = DateFormat('yyyy/MM/dd');

        return Card(
          elevation: 1.5,
          margin: EdgeInsets.only(bottom: context.h(10)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          child: ListTile(
            leading: Icon(statusIcon, color: statusColor, size: context.r(30)),
            title: Text(
              '${request.leaveType} - ${request.applicant}',
              style: context.textTheme.titleMedium?.copyWith(
                fontSize: context.sp(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${dateFormat.format(request.startDate)} - ${dateFormat.format(request.endDate)}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.outline,
                fontSize: context.sp(14),
              ),
            ),
            trailing: Text(
              request.status.name.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: context.sp(12),
              ),
            ),
            onTap: () {
              /* TODO: Show details */
            },
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1);
      },
    );
  }

  // Builds the list for Expense History
  Widget _buildExpenseHistoryList(
    BuildContext context,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final filteredData =
        mockExpenseData.where((req) {
          if (startDate == null || endDate == null) return true;
          return !(req.requestDate.isBefore(startDate) ||
              req.requestDate.isAfter(endDate));
        }).toList();

    if (filteredData.isEmpty) {
      return _buildEmptyState(context, '此區間尚無請款紀錄');
    }
    return ListView.builder(
      key: const ValueKey('expense_list'),
      padding: EdgeInsets.all(context.i(12)),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final request = filteredData[index];
        final statusColor = _getStatusColor(request.status, context);
        final statusIcon = _getStatusIcon(request.status);
        final dateFormat = DateFormat('yyyy/MM/dd');
        final amountFormat = NumberFormat.currency(
          locale: 'zh_TW',
          symbol: 'NT\$',
          decimalDigits: 0,
        );

        return Card(
          elevation: 1.5,
          margin: EdgeInsets.only(bottom: context.h(10)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          child: ListTile(
            leading: Icon(statusIcon, color: statusColor, size: context.r(30)),
            title: Text(
              '${request.expenseType} - ${request.applicant}',
              style: context.textTheme.titleMedium?.copyWith(
                fontSize: context.sp(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '申請日期: ${dateFormat.format(request.requestDate)}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.outline,
                fontSize: context.sp(14),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountFormat.format(request.amount),
                  style: TextStyle(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: context.sp(14),
                  ),
                ),
                Text(
                  request.status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: context.sp(12),
                  ),
                ),
              ],
            ),
            onTap: () {
              /* TODO: Show details */
            },
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1);
      },
    );
  }

  // Builds the empty state widget
  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      key: ValueKey(message),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
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
}
