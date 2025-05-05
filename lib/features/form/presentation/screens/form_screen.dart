import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../calendar/presentation/widgets/filter_area.dart';
import '../../data/models/leave_record.dart'; // Import LeaveRecord model
import '../../domain/entities/form_history_query.dart';
import '../../domain/entities/leave_record_state.dart';
import '../presenters/leave_record_presenter.dart'; // Import LeaveRecordPresenter
import '../widgets/leave_record_list_tile.dart'; // Import List Tile

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
  // Joker for applied query state
  late final Joker<FormHistoryQuery> _historyJoker;
  // Joker Presenter for leave records state
  late final LeaveRecordPresenter _leaveRecordPresenter;

  // Temporary state for date selection
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    _historyJoker = Joker<FormHistoryQuery>(
      const FormHistoryQuery(historyType: FormHistoryType.leave),
    );
    // Directly create the presenter instance
    _leaveRecordPresenter = LeaveRecordPresenter();

    // Optional: Register with Circus if needed globally (using summon on the instance)
    // Circus.summon<LeaveRecordPresenter>(_leaveRecordPresenter, tag: 'leaveRecord');

    // Fetch initial data if needed (e.g., for the current month?)
    // Or wait for the first query by the user.
    // Let's wait for the user query for now.
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
    // Clear applied dates in Joker state
    _historyJoker.trickWith(
      (state) => state.copyWith(startDate: null, endDate: null),
    );
    // Reset leave record presenter state
    _leaveRecordPresenter.reset();
  }

  // Modified to trigger fetch from presenter
  void _performQuery() {
    // Apply the temporary dates to the Joker state for FilterArea display
    _historyJoker.trickWith(
      (state) =>
          state.copyWith(startDate: _tempStartDate, endDate: _tempEndDate),
    );
    // Trigger fetch in the presenter using the temporary dates
    _leaveRecordPresenter.fetchLeaveRecords(
      startDate: _tempStartDate,
      endDate: _tempEndDate,
    );
    debugPrint(
      'Triggering leave record fetch for: $_tempStartDate to $_tempEndDate',
    );
  }

  @override
  Widget build(BuildContext context) {
    return _historyJoker.perform(
      builder: (context, historyState) {
        // historyState is FormHistoryQuery (used for FilterArea and type switching)
        return Scaffold(
          appBar: AppBar(
            title: Text(
              historyState.historyType == FormHistoryType.leave
                  ? '請假紀錄'
                  : '請款紀錄', // Keep expense title
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
                      startDate: null,
                      endDate: null,
                    ),
                  );
                  // Reset presenter when switching tabs
                  _leaveRecordPresenter.reset();
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
                onQuery: _performQuery, // Trigger query application & fetch
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  // Use LeaveRecordPresenter for leave tab, mock data for expense tab
                  child:
                      historyState.historyType == FormHistoryType.leave
                          ? _leaveRecordPresenter.perform(
                            // Listen to presenter state
                            builder: (context, leaveState) {
                              if (leaveState is LeaveRecordLoading) {
                                return const Center(
                                  key: ValueKey('leave_loading'),
                                  child: CircularProgressIndicator(),
                                );
                              } else if (leaveState is LeaveRecordError) {
                                return _buildErrorState(
                                  context,
                                  leaveState.failure.message,
                                );
                              } else if (leaveState is LeaveRecordSuccess) {
                                return _buildLeaveHistoryList(
                                  context,
                                  leaveState.records,
                                );
                              } else {
                                // Initial state
                                return _buildEmptyState(
                                  context,
                                  '請選擇日期範圍並查詢請假紀錄',
                                  key: const ValueKey(
                                    'leave_initial',
                                  ), // Add key
                                );
                              }
                            },
                          )
                          : _buildExpenseHistoryList(
                            // Still uses mock data
                            context,
                            historyState.startDate,
                            historyState.endDate,
                          ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.router.push(
                ApplyFormRoute(formType: historyState.historyType),
              );
            },
            label: Text(
              historyState.historyType == FormHistoryType.leave
                  ? '申請請假'
                  : '申請請款',
            ),
            icon: const Icon(Icons.add),
            tooltip:
                historyState.historyType == FormHistoryType.leave
                    ? '申請新的請假單'
                    : '申請新的請款單',
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5),
        );
      },
    );
  }

  // Updated to use LeaveRecordListTile
  Widget _buildLeaveHistoryList(
    BuildContext context,
    List<LeaveRecord> records,
  ) {
    final filteredData = records.where((r) => !r.isCanceled).toList();

    if (filteredData.isEmpty) {
      return _buildEmptyState(
        context,
        '此區間尚無請假紀錄',
        key: const ValueKey('leave_empty'),
      );
    }
    // Wrap with AnimationLimiter for staggered animations (optional but nice)
    return AnimationLimiter(
      child: ListView.builder(
        key: const ValueKey('leave_list'),
        padding: EdgeInsets.symmetric(
          vertical: context.h(8),
        ), // Adjusted padding
        itemCount: filteredData.length,
        itemBuilder: (context, index) {
          final request = filteredData[index];
          // Use AnimationConfiguration for staggered effect
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: LeaveRecordListTile(
                  key: ValueKey(
                    'leave_${request.startTime}_${request.ruleName}',
                  ),
                  record: request,
                  onTap: () {
                    // Navigate to FormDetailScreen with LeaveRecord object and qryNo as formId
                    context.router.push(
                      FormDetailRoute(
                        formId: request.qryNo, // Pass qryNo as formId
                        leaveRecord: request,
                        formType: FormHistoryType.leave,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Builds the list for Expense History (remains unchanged, uses mock data)
  Widget _buildExpenseHistoryList(
    BuildContext context,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    // ... (implementation using mockExpenseData is unchanged)
    const currentType = FormHistoryType.expense;
    final filteredData =
        mockExpenseData.where((req) {
          if (startDate == null || endDate == null) return true;
          // Adjust date comparison if needed for Expense request date
          return !(req.requestDate.isBefore(startDate) ||
              req.requestDate.isAfter(endDate));
        }).toList();

    if (filteredData.isEmpty) {
      return _buildEmptyState(
        context,
        '此區間尚無請款紀錄',
        key: const ValueKey('expense_empty'),
      ); // Add key
    }
    // Add animation for consistency
    return AnimationLimiter(
      child: ListView.builder(
        key: const ValueKey('expense_list'),
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        itemCount: filteredData.length,
        itemBuilder: (context, index) {
          final request = filteredData[index];
          final statusColor = _getExpenseStatusColor(request.status, context);
          final statusIcon = _getExpenseStatusIcon(request.status);
          final dateFormat = DateFormat('yyyy/MM/dd');
          final amountFormat = NumberFormat.currency(
            locale: 'zh_TW',
            symbol: 'NT\$',
            decimalDigits: 0,
          );

          // Apply animation
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Card(
                  elevation: 1.5,
                  margin: EdgeInsets.symmetric(
                    vertical: context.h(5),
                    horizontal: context.w(8),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(8)),
                  ),
                  child: ListTile(
                    leading: Icon(
                      statusIcon,
                      color: statusColor,
                      size: context.r(30),
                    ),
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
                      // Navigate to detail screen with id (assuming it's qryNo for mock) and type
                      context.router.push(
                        FormDetailRoute(
                          formId: request.id,
                          formType: currentType,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Keep expense status helpers as they are used by the mock expense list
  Color _getExpenseStatusColor(FormStatus status, BuildContext context) {
    switch (status) {
      case FormStatus.approved:
        return Colors.green.shade600;
      case FormStatus.pending:
        return Colors.orange.shade700;
      case FormStatus.rejected:
        return context.colorScheme.error;
    }
  }

  IconData _getExpenseStatusIcon(FormStatus status) {
    switch (status) {
      case FormStatus.approved:
        return Icons.check_circle_outline;
      case FormStatus.pending:
        return Icons.hourglass_empty_outlined;
      case FormStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  // Builds the empty state widget (added optional key)
  Widget _buildEmptyState(BuildContext context, String message, {Key? key}) {
    return Center(
      key: key ?? ValueKey(message), // Use provided key or default
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Builds the error state widget
  Widget _buildErrorState(BuildContext context, String message, {Key? key}) {
    return Center(
      key: key ?? const ValueKey('error_state'),
      child: Padding(
        padding: EdgeInsets.all(context.i(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: context.colorScheme.error,
              size: context.r(48),
            ),
            Gap(context.h(16)),
            Text(
              message,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colorScheme.error,
                fontSize: context.sp(16),
              ),
              textAlign: TextAlign.center,
            ),
            // Add retry button?
            Gap(context.h(16)),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('重試'),
              onPressed: _performQuery, // Retry the query
              style: ElevatedButton.styleFrom(
                foregroundColor: context.colorScheme.onError,
                backgroundColor: context.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
