import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../../core/config/storage_keys.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../core/extensions/list_holiday_extensions.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/utils/calendar_utils.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../../core/widgets/refresh_button.dart';
import '../../../holiday/data/models/holiday.dart';
import '../../../holiday/domain/entities/holiday_state.dart';
import '../../../holiday/presentation/presenters/holiday_presenter.dart';
import '../../data/models/attendance_details.dart';
import '../../domain/entities/attendance_state.dart';
import '../presenters/attendance_presenter.dart';
import '../widgets/calendar_view_widget.dart';
import '../widgets/filter_area.dart';
import '../widgets/query_result_list.dart';
import '../widgets/selected_day_details_card.dart';

@RoutePage()
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final HolidayPresenter _holidayPresenter;
  late final AttendancePresenter _attendancePresenter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _attendancePresenter = Circus.find<AttendancePresenter>();
    _holidayPresenter = Circus.find<HolidayPresenter>();
    _loadInitialHolidays();
  }

  Future<void> _loadInitialHolidays() async {
    try {
      final cachedHolidayStrings = LocalStorage.get<List<String>>(
        StorageKeys.holidays,
        defaultValue: [],
      );

      if (cachedHolidayStrings.isNotEmpty) {
        final List<Holiday> cachedHolidays =
            cachedHolidayStrings
                .map(
                  (jsonString) => Holiday.fromJson(
                    jsonDecode(jsonString) as Map<String, dynamic>,
                  ),
                )
                .toList();

        if (cachedHolidays.coversRequiredYears()) {
          debugPrint('Using valid cached holiday data.');
          // If presenter hasn't loaded yet, set its initial state
          if (_holidayPresenter.state is HolidayInitial) {
            _holidayPresenter.trick(HolidayState.success(cachedHolidays));
          }
          // Removed setState for _holidays
          return;
        } else {
          debugPrint('Cached holiday data is outdated or incomplete.');
        }
      } else {
        debugPrint('No cached holiday data found.');
      }
    } catch (e) {
      debugPrint('Error reading or validating cached holidays: $e');
    }
    debugPrint('Fetching fresh holiday data...');
    // Only fetch if presenter is not already loading or successful
    if (_holidayPresenter.state is HolidayInitial ||
        _holidayPresenter.state is HolidayError) {
      // Use await to ensure fetch completes before proceeding in some scenarios
      await _holidayPresenter.fetchHolidays();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _holidayPresenter.perform(
      builder: (context, holidayState) {
        // Derive holiday data directly from the state within the builder
        List<Holiday> currentHolidays = [];
        Set<DateTime> holidayDateTimes = {};
        bool isLoadingHolidays = holidayState is HolidayLoading;
        bool hasHolidayError = holidayState is HolidayError;

        if (holidayState is HolidaySuccess) {
          currentHolidays = holidayState.holidays;
        } else if (holidayState is HolidayInitial) {
          isLoadingHolidays = true;
        }

        if (currentHolidays.isNotEmpty) {
          holidayDateTimes =
              currentHolidays
                  .map((h) {
                    try {
                      // Assumes date is "YYYYMMDD"
                      if (h.date.length >= 8) {
                        final year = int.parse(h.date.substring(0, 4));
                        final month = int.parse(h.date.substring(4, 6));
                        final day = int.parse(h.date.substring(6, 8));
                        if (month >= 1 &&
                            month <= 12 &&
                            day >= 1 &&
                            day <= 31) {
                          return DateTime(year, month, day);
                        } else {
                          debugPrint(
                            'Invalid month/day in date string: ${h.date}',
                          );
                          return null;
                        }
                      } else {
                        debugPrint('Invalid date string length: ${h.date}');
                        return null;
                      }
                    } catch (e) {
                      debugPrint(
                        'Error parsing holiday date for calendar: ${h.date}',
                      );
                      return null; // Skip invalid dates
                    }
                  })
                  .where((e) => e != null)
                  .cast<DateTime>()
                  .toSet();
        }

        // --- Scaffold and TabBarView structure ---
        return Scaffold(
          appBar: AppBar(
            title: const Text('出勤日曆'),
            elevation: 1,
            centerTitle: true,
            actions: [const RefreshButton(type: 'attendance')],
            bottom: TabBar(
              controller: _tabController,
              labelColor:
                  !context.isDarkMode
                      ? context.colorScheme.surface
                      : context.colorScheme.onSurfaceVariant,
              unselectedLabelColor: context.colorScheme.onSurfaceVariant,
              indicatorColor: context.colorScheme.primary,
              indicatorWeight: context.h(3.0),
              labelStyle: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: context.sp(14),
              ),
              unselectedLabelStyle: context.textTheme.titleSmall?.copyWith(
                fontSize: context.sp(14),
              ),
              tabs: const [Tab(text: '單日檢視'), Tab(text: '區間查詢')],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _SingleDayViewTab(
                holidayDateTimes: holidayDateTimes,
                holidays: currentHolidays,
                isLoadingHolidays: isLoadingHolidays,
                hasHolidayError: hasHolidayError,
                holidayPresenter: _holidayPresenter,
                attendancePresenter: _attendancePresenter,
              ),
              _RangeQueryTabView(
                attendancePresenter: _attendancePresenter,
                holidayDateTimes: holidayDateTimes,
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- _SingleDayViewTab definition ---
class _SingleDayViewTab extends StatefulWidget {
  final Set<DateTime> holidayDateTimes;
  final List<Holiday> holidays;
  final bool isLoadingHolidays;
  final bool hasHolidayError;
  final HolidayPresenter holidayPresenter;
  final AttendancePresenter attendancePresenter;

  const _SingleDayViewTab({
    required this.holidayDateTimes,
    required this.holidays,
    required this.isLoadingHolidays,
    required this.hasHolidayError,
    required this.holidayPresenter,
    required this.attendancePresenter,
  });

  @override
  State<_SingleDayViewTab> createState() => _SingleDayViewTabState();
}

class _SingleDayViewTabState extends State<_SingleDayViewTab>
    with SingleTickerProviderStateMixin {
  // Keep selected date Joker
  late final Joker<DateTime> _selectedDateJoker;

  final CalendarController _calendarController = CalendarController();
  late VoidCallback _dateListener;

  @override
  void initState() {
    super.initState();
    final initialDate = DateUtils.dateOnly(DateTime.now());
    _selectedDateJoker = Joker<DateTime>(initialDate);

    _dateListener = () {
      final newDate = _selectedDateJoker.state;
      _fetchSingleDayDetails(newDate);
    };
    _selectedDateJoker.addListener(_dateListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkHolidayDataAndLoadDetails(initialDate);
    });
  }

  void _checkHolidayDataAndLoadDetails(DateTime date) {
    // Fetch details immediately if holiday data is ready
    if (!widget.isLoadingHolidays && !widget.hasHolidayError) {
      _fetchSingleDayDetails(date);
    } // Otherwise, didUpdateWidget will handle it when holiday data arrives
  }

  @override
  void didUpdateWidget(_SingleDayViewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload details if holiday data becomes available
    if (oldWidget.isLoadingHolidays &&
        !widget.isLoadingHolidays &&
        !widget.hasHolidayError) {
      final currentState = widget.attendancePresenter.state;
      if (currentState is AttendanceInitial ||
          currentState is AttendanceError) {
        _fetchSingleDayDetails(_selectedDateJoker.state);
      }
    }
  }

  @override
  void dispose() {
    // Ensure correct usage of removeListener
    _selectedDateJoker.removeListener(_dateListener);
    _calendarController.dispose();
    super.dispose();
  }

  // _getHolidayDescription remains the same
  String? _getHolidayDescription(DateTime date) {
    final normalizedDate = DateUtils.dateOnly(date);
    final holiday = widget.holidays.firstWhereOrNull((h) {
      try {
        if (h.date.length >= 8) {
          final hYear = int.parse(h.date.substring(0, 4));
          final hMonth = int.parse(h.date.substring(4, 6));
          final hDay = int.parse(h.date.substring(6, 8));
          if (hMonth >= 1 && hMonth <= 12 && hDay >= 1 && hDay <= 31) {
            return DateUtils.isSameDay(
              DateTime(hYear, hMonth, hDay),
              normalizedDate,
            );
          }
        }
        return false;
      } catch (e) {
        debugPrint(
          'Error comparing holiday date ${h.date} with $normalizedDate: $e',
        );
        return false;
      }
    });
    return holiday?.description;
  }

  // Updated to use AttendancePresenter - Verify date format
  Future<void> _fetchSingleDayDetails(DateTime day) async {
    if (widget.isLoadingHolidays || widget.hasHolidayError) {
      return;
    }
    if (!mounted) return;

    final normalizedDay = DateUtils.dateOnly(day);
    try {
      // Ensure date format is yyyy-MM-dd as requested by user
      await widget.attendancePresenter.getDailyAttendanceRecord(
        date: DateFormat('yyyy-MM-dd').format(normalizedDay),
      );
    } catch (e) {
      debugPrint(
        "Error calling getDailyAttendanceRecord for $normalizedDay: $e",
      );
    }
  }

  void _onCalendarDateSelected(DateTime date) {
    final newSelectedDate = DateUtils.dateOnly(date);
    if (_selectedDateJoker.state != newSelectedDate) {
      _selectedDateJoker.trick(newSelectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingHolidays) {
      return const Center(
        child: CircularProgressIndicator(key: ValueKey('holidays_loading')),
      );
    }
    if (widget.hasHolidayError) {
      return Center(
        key: const ValueKey('holidays_error'),
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
                '無法載入假日資料',
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colorScheme.error,
                  fontSize: context.sp(16),
                ),
                textAlign: TextAlign.center,
              ),
              Gap(context.h(16)),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('重試'),
                onPressed: () => widget.holidayPresenter.fetchHolidays(),
              ),
            ],
          ),
        ),
      );
    }

    // Wrap the main Column with SingleChildScrollView
    return SingleChildScrollView(
      child: Column(
        children: [
          _selectedDateJoker.perform(
            builder: (context, currentSelectedDate) {
              return CalendarViewWidget(
                key: const ValueKey('calendar_view'),
                initialDate: currentSelectedDate,
                holidays: widget.holidayDateTimes,
                onSelectionChanged: _onCalendarDateSelected,
                controller: _calendarController,
                selectedDate: currentSelectedDate,
              );
            },
          ),
          const Gap(8.0),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(8),
              0,
              context.w(8),
              context.h(8),
            ),
            // Combine selected date and attendance state
            // No need to listen to _selectedDateJoker again here, already passed
            child: widget.attendancePresenter.focusOn<AttendanceState>(
              selector: (state) => state,
              builder: (context, attendanceState) {
                // Use the date from the Joker directly, as it's the source of truth
                final selectedDate = _selectedDateJoker.state;
                bool isLoadingDetails = attendanceState is AttendanceLoading;
                AttendanceRecord? attendanceRecord;
                if (attendanceState is AttendanceSuccess) {
                  attendanceRecord = attendanceState.dailyAttendanceRecord;
                }
                return SelectedDayDetailsCard(
                  key: ValueKey(selectedDate),
                  selectedDate: selectedDate,
                  attendanceRecord: attendanceRecord,
                  holidayDescription: _getHolidayDescription(selectedDate),
                  isLoading: isLoadingDetails,
                  isKnownHoliday: widget.holidayDateTimes.contains(
                    selectedDate,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Define a record type for data passed to the tile
typedef AttendanceTileData =
    ({
      AttendanceRecord record,
      String statusTag,
      Color statusColor,
      IconData statusIcon,
      String formattedDate, // This will now hold M/d or yyyy/M/d
      bool showYear, // Flag to indicate if year should be shown
    });

// --- _RangeQueryTabView definition ---
class _RangeQueryTabView extends StatefulWidget {
  final AttendancePresenter attendancePresenter;
  final Set<DateTime> holidayDateTimes;

  const _RangeQueryTabView({
    required this.attendancePresenter,
    required this.holidayDateTimes,
  });

  @override
  State<_RangeQueryTabView> createState() => _RangeQueryTabViewState();
}

class _RangeQueryTabViewState extends State<_RangeQueryTabView> {
  late final Joker<DateTime?> _startDateJoker;
  late final Joker<DateTime?> _endDateJoker;

  DateTime? _lastQueryStartDate;
  DateTime? _lastQueryEndDate;

  @override
  void initState() {
    super.initState();
    _startDateJoker = Joker<DateTime?>(null);
    _endDateJoker = Joker<DateTime?>(null);
  }

  // --- Restore original methods ---
  void _showDateRangePickerInSheet() {
    PickerDateRange? initialRange;
    final currentStart = _startDateJoker.state;
    final currentEnd = _endDateJoker.state;
    if (currentStart != null && currentEnd != null) {
      initialRange = PickerDateRange(currentStart, currentEnd);
    } else if (currentStart != null) {
      initialRange = PickerDateRange(currentStart, currentStart);
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
            constraints: BoxConstraints(maxHeight: context.vh * 0.5),
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
                    "選擇日期範圍",
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
                        onPressed: () => sheetContext.pop(),
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

                            _startDateJoker.trick(newStartDate);
                            _endDateJoker.trick(newEndDate);
                          }
                          sheetContext.pop();
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

  void _setRange(DateTime start, DateTime end) {
    final normStart = DateUtils.dateOnly(start);
    final normEnd = DateUtils.dateOnly(end);
    _startDateJoker.trick(normStart);
    _endDateJoker.trick(normEnd);
  }

  void _setRangeToYesterday() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    _setRange(y, y);
  }

  void _setRangeToToday() {
    final n = DateTime.now();
    _setRange(n, n);
  }

  void _setRangeToThisWeek() {
    final n = DateTime.now();
    final startOfWeek = n.subtract(
      Duration(days: n.weekday - 1),
    ); // Assuming Monday is 1
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    _setRange(startOfWeek, endOfWeek);
  }

  void _setRangeToThisMonth() {
    final n = DateTime.now();
    final firstDay = DateTime(n.year, n.month, 1);
    final lastDay = DateTime(n.year, n.month + 1, 0);
    _setRange(firstDay, lastDay);
  }

  Future<void> _performQuery() async {
    final startDate = _startDateJoker.state;
    final endDate = _endDateJoker.state;

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('請先選擇日期範圍', style: TextStyle(fontSize: context.sp(14))),
        ),
      );
      return;
    }
    if (endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '結束日期不能早於開始日期',
            style: TextStyle(fontSize: context.sp(14)),
          ),
        ),
      );
      return;
    }

    _lastQueryStartDate = startDate;
    _lastQueryEndDate = endDate;
    // setState(() {}); // No longer needed

    try {
      await widget.attendancePresenter.getAttendanceRecords(
        startDate: DateFormat('yyyy-MM-dd').format(startDate),
        endDate: DateFormat('yyyy-MM-dd').format(endDate),
      );
    } catch (e) {
      debugPrint("Error calling getAttendanceRecords: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '查詢失敗: $e',
              style: TextStyle(fontSize: context.sp(14)),
            ),
          ),
        );
      }
    }
  }

  void _clearQuery() {
    _startDateJoker.trick(null);
    _endDateJoker.trick(null);
    _lastQueryStartDate = null;
    _lastQueryEndDate = null;
    widget.attendancePresenter.reset();
    widget.attendancePresenter.trick(const AttendanceState.initial());
    // No need for setState here
  }
  // --- End of restored methods ---

  @override
  Widget build(BuildContext context) {
    return [_startDateJoker, _endDateJoker].assemble<(DateTime?, DateTime?)>(
      converter: (values) => (values[0] as DateTime?, values[1] as DateTime?),
      builder: (context, dateData) {
        final (currentStartDate, currentEndDate) = dateData;

        // Note: shouldShowYear calculation is moved inside the presenter builder below

        return widget.attendancePresenter.perform(
          builder: (context, attendanceState) {
            // Calculate shouldShowYear based on the range of the last successful query
            final bool shouldShowYear =
                _lastQueryStartDate != null &&
                _lastQueryEndDate != null &&
                _lastQueryStartDate!.year != _lastQueryEndDate!.year;

            bool isLoading = attendanceState is AttendanceLoading;
            List<AttendanceTileData> tileDataList = [];

            if (attendanceState is AttendanceSuccess) {
              final results =
                  attendanceState.attendanceRecords?.values.toList() ?? [];
              results.sort(
                (a, b) =>
                    (a.dateInfo?.date ?? '').compareTo(b.dateInfo?.date ?? ''),
              );

              tileDataList =
                  results.map((record) {
                    DateTime? recordDate;
                    bool isHoliday = false;
                    String formattedDateStr = record.dateInfo?.date ?? '未知日期';

                    try {
                      final dateString = record.dateInfo?.date;
                      if (dateString != null) {
                        DateTime? date;
                        try {
                          date = DateFormat(
                            'yyyy-MM-dd',
                          ).parseStrict(dateString);
                        } catch (e) {
                          debugPrint(
                            'Failed to parse date: $dateString - Error: $e',
                          );
                        }

                        if (date != null) {
                          final formatString =
                              shouldShowYear ? 'yyyy/M/d' : 'M/d';
                          formattedDateStr = DateFormat(
                            formatString,
                          ).format(date);
                          recordDate = date;
                          isHoliday = widget.holidayDateTimes.contains(
                            DateUtils.dateOnly(recordDate),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint(
                        'Error processing date for list tile: ${record.dateInfo?.date} - $e',
                      );
                      formattedDateStr = record.dateInfo?.date ?? '解析錯誤';
                    }

                    final statusTag = CalendarUtils.getAttendanceStatusTag(
                      record.punch,
                      record.attendance,
                      record.timeoff,
                      record.overtime,
                      isHoliday,
                    );
                    final statusColor = CalendarUtils.getStatusTagColor(
                      statusTag,
                      context.colorScheme,
                    );
                    final statusIcon = CalendarUtils.getStatusTagIcon(
                      statusTag,
                    );

                    return (
                      record: record,
                      statusTag: statusTag,
                      statusColor: statusColor,
                      statusIcon: statusIcon,
                      formattedDate: formattedDateStr,
                      showYear: shouldShowYear,
                    );
                  }).toList();
            }

            return Column(
              children: [
                // Restore FilterArea usage
                FilterArea(
                  selectedStartDate: currentStartDate,
                  selectedEndDate: currentEndDate,
                  onSelectRange: _showDateRangePickerInSheet,
                  onSetYesterday: _setRangeToYesterday,
                  onSetToday: _setRangeToToday,
                  onSetThisWeek: _setRangeToThisWeek,
                  onSetThisMonth: _setRangeToThisMonth,
                  onClear: _clearQuery,
                  onQuery: _performQuery,
                ),
                Gap(context.h(10)),
                Expanded(
                  child: QueryResultList(
                    isLoading: isLoading,
                    results: tileDataList,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
