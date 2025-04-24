import 'dart:async'; // For Future.delayed, StreamSubscription
import 'dart:convert'; // For jsonDecode

import 'package:auto_route/annotations.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull, whereNotNull
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:joker_state/joker_state.dart'; // Import JokerState
import 'package:syncfusion_flutter_calendar/calendar.dart'; // Import SfCalendar controller
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../core/config/storage_keys.dart'; // Import StorageKeys
// Corrected import path for the extension
import '../../core/extensions/list_holiday_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/local_storage.dart'; // Import LocalStorage
import '../../data/models/holiday.dart'; // Import Holiday model
import '../../domain/entities/clock_in_data.dart';
import '../../domain/entities/holiday_state.dart'; // Import HolidayState
import '../presenters/holiday_presenter.dart'; // Import HolidayPresenter
import '../widgets/calendar_view_widget.dart'; // Import new widget
import '../widgets/filter_area.dart';
import '../widgets/query_result_list.dart';
import '../widgets/selected_day_details_card.dart'; // Import new widget

Future<List<ClockInData>> fetchPunchInDataForRange(
  DateTime start,
  DateTime end,
) async {
  final startDate = DateTime(start.year, start.month, start.day);
  final endDate = DateTime(end.year, end.month, end.day);
  List<ClockInData> results = [];
  await Future.delayed(const Duration(milliseconds: 500));
  for (var day = 0; day <= endDate.difference(startDate).inDays; day++) {
    final currentDate = startDate.add(Duration(days: day));
    // Fetch mock data as map first
    final mockDataMap = await _fetchClockInDataMap(currentDate);
    // Create freezed object
    results.add(
      ClockInData(
        date: currentDate,
        status: mockDataMap['status']!,
        clockIn: mockDataMap['clockIn'],
        clockOut: mockDataMap['clockOut'],
        reason: mockDataMap['reason'],
      ),
    );
  }
  results.sort((a, b) => b.date.compareTo(a.date));
  return results;
}

// Renamed helper to avoid conflict and return Map
Future<Map<String, String>> _fetchClockInDataMap(DateTime date) async {
  await Future.delayed(const Duration(milliseconds: 5));
  final normalizedDate = DateTime(date.year, date.month, date.day);
  if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
    return {'status': 'holiday'};
  }
  if (date.day % 7 == 0) {
    return {'status': 'absent', 'reason': 'personal_leave'};
  }
  if (date.day % 4 == 0) {
    return {'status': 'late', 'clockIn': '09:15', 'clockOut': '18:01'};
  }
  if (date.day % 11 == 0) {
    return {'status': 'normal', 'clockIn': '08:55'};
  }
  return {'status': 'normal', 'clockIn': '09:03', 'clockOut': '18:05'};
}

@RoutePage()
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Hire the presenter directly
  late final HolidayPresenter _holidayPresenter = Circus.hire<HolidayPresenter>(
    HolidayPresenter(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Use focusOn builder to react to holiday state changes
    return _holidayPresenter.focusOn<HolidayState>(
      selector: (state) => state, // Select the entire state object
      builder: (context, holidayState) {
        // Derive holiday data directly from the state within the builder
        List<Holiday> currentHolidays = [];
        Set<DateTime> holidayDateTimes = {};
        bool isLoadingHolidays = holidayState is HolidayLoading;
        bool hasHolidayError = holidayState is HolidayError;

        if (holidayState is HolidaySuccess) {
          currentHolidays = holidayState.holidays;
          // Removed Future.microtask and setState
        } else if (holidayState is HolidayInitial) {
          // Still in initial state, treat as loading
          isLoadingHolidays = true;
        }
        // If error, currentHolidays remains empty. Loading state is handled above.

        // Calculate Set<DateTime> for SfCalendar based on derived currentHolidays
        // Ensure this runs only if holidays are available
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

        final themeMode = context.joker<AppThemeMode>();
        final isDarkMode = themeMode.state == AppThemeMode.dark;

        // --- Scaffold and TabBarView structure ---
        return Scaffold(
          appBar: AppBar(
            title: const Text('出勤日曆'),
            elevation: 1,
            bottom: TabBar(
              controller: _tabController,
              // Updated colors for better visibility
              labelColor:
                  !isDarkMode
                      ? colorScheme.surface
                      : colorScheme.onSurfaceVariant,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              indicatorWeight: 3.0,
              labelStyle: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: textTheme.titleSmall,
              tabs: const [Tab(text: '單日檢視'), Tab(text: '區間查詢')],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Pass derived data directly to the tab view
              _SingleDayViewTab(
                // Pass the calculated holiday sets and state flags
                holidayDateTimes: holidayDateTimes,
                holidays: currentHolidays, // Pass the derived list
                isLoadingHolidays: isLoadingHolidays,
                hasHolidayError: hasHolidayError,
                // Pass the presenter down for retry action
                holidayPresenter: _holidayPresenter,
              ),
              const _RangeQueryTabView(), // Range query tab remains the same for now
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

  const _SingleDayViewTab({
    required this.holidayDateTimes,
    required this.holidays,
    required this.isLoadingHolidays,
    required this.hasHolidayError,
    required this.holidayPresenter,
  });

  @override
  State<_SingleDayViewTab> createState() => _SingleDayViewTabState();
}

class _SingleDayViewTabState extends State<_SingleDayViewTab>
    with SingleTickerProviderStateMixin {
  // Jokers for state management
  late final Joker<DateTime> _selectedDateJoker;
  late final Joker<ClockInData?> _selectedClockInDataJoker;
  late final Joker<bool> _isLoadingDetailsJoker;

  final CalendarController _calendarController = CalendarController();
  // Listener function to be added/removed
  late VoidCallback _dateListener;

  @override
  void initState() {
    super.initState();
    final initialDate = DateUtils.dateOnly(DateTime.now());
    _selectedDateJoker = Joker<DateTime>(initialDate);
    _selectedClockInDataJoker = Joker<ClockInData?>(null);
    _isLoadingDetailsJoker = Joker<bool>(false);

    // Define the listener function
    _dateListener = () {
      final newDate = _selectedDateJoker.state;
      _fetchSingleDayDetails(newDate);
      // Update calendar controller if needed
      if (_calendarController.selectedDate != newDate) {
        _calendarController.selectedDate = newDate;
      }
    };

    // Add the listener
    _selectedDateJoker.addListener(_dateListener);

    // Initial detail loading
    if (!widget.isLoadingHolidays && !widget.hasHolidayError) {
      _fetchSingleDayDetails(initialDate);
    } else {
      _isLoadingDetailsJoker.trick(true);

      // Schedule details loading after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkHolidayDataAndLoadDetails(initialDate);
      });
    }
  }

  // Check holiday data status and load details if ready
  void _checkHolidayDataAndLoadDetails(DateTime date) {
    if (!widget.isLoadingHolidays && !widget.hasHolidayError) {
      _fetchSingleDayDetails(date);
    }
  }

  @override
  void didUpdateWidget(_SingleDayViewTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-load details when holiday data finishes loading
    if (oldWidget.isLoadingHolidays &&
        !widget.isLoadingHolidays &&
        !widget.hasHolidayError &&
        _isLoadingDetailsJoker.state) {
      _fetchSingleDayDetails(_selectedDateJoker.state);
    }
  }

  @override
  void dispose() {
    // Remove the listener
    _dateListener();
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

  // _fetchSingleDayDetails remains the same
  Future<void> _fetchSingleDayDetails(DateTime day) async {
    if (widget.isLoadingHolidays || widget.hasHolidayError) {
      if (_isLoadingDetailsJoker.state) _isLoadingDetailsJoker.trick(false);
      return;
    }
    if (!mounted) return;
    _isLoadingDetailsJoker.trick(true);
    _selectedClockInDataJoker.trick(null);
    final normalizedDay = DateUtils.dateOnly(day);
    final isHoliday = widget.holidayDateTimes.contains(normalizedDay);
    try {
      ClockInData details;
      if (isHoliday) {
        final holidayDesc = _getHolidayDescription(normalizedDay);
        details = ClockInData(
          date: normalizedDay,
          status: 'holiday',
          reason: holidayDesc ?? '國定假日',
        );
      } else {
        final dataMap = await _fetchClockInDataMap(normalizedDay);
        details = ClockInData(
          date: normalizedDay,
          status: dataMap['status']!,
          clockIn: dataMap['clockIn'],
          clockOut: dataMap['clockOut'],
          reason: dataMap['reason'],
        );
      }
      if (mounted) {
        _selectedClockInDataJoker.trick(details);
      }
    } catch (e) {
      debugPrint("Error fetching single day details for $normalizedDay: $e");
      if (mounted) {
        _selectedClockInDataJoker.trick(null);
      }
    } finally {
      if (mounted) {
        _isLoadingDetailsJoker.trick(false);
      }
    }
  }

  // Modify _onCalendarDateSelected to only update the Joker
  // The listener will handle the rest.
  void _onCalendarDateSelected(DateTime date) {
    final newSelectedDate = DateUtils.dateOnly(date);
    if (_selectedDateJoker.state != newSelectedDate) {
      _selectedDateJoker.trick(newSelectedDate);
      // No need to call fetch or update controller here anymore
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Holiday loading/error check remains the same
    if (widget.isLoadingHolidays) {
      return const Center(
        child: CircularProgressIndicator(key: ValueKey('holidays_loading')),
      );
    }
    if (widget.hasHolidayError) {
      return Center(
        key: const ValueKey('holidays_error'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                '無法載入假日資料',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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

    // Main Column layout
    return Column(
      children: [
        // CalendarViewWidget setup remains the same
        CalendarViewWidget(
          key: const ValueKey('calendar_view'),
          initialDate: _selectedDateJoker.state,
          holidays: widget.holidayDateTimes,
          onSelectionChanged: _onCalendarDateSelected, // Only updates Joker
          controller: _calendarController,
        ),
        const Gap(8.0),
        // Details Card - Correctly use variables from Joker performers
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
            child: [
              _selectedDateJoker,
              _selectedClockInDataJoker,
              _isLoadingDetailsJoker,
            ].assemble<(DateTime, ClockInData?, bool)>(
              converter:
                  (values) => (
                    values[0] as DateTime,
                    values[1] as ClockInData?,
                    values[2] as bool,
                  ),
              builder: (context, data) {
                final (selectedDate, clockInData, isLoading) = data;
                return SelectedDayDetailsCard(
                  key: ValueKey(selectedDate),
                  selectedDate: selectedDate,
                  clockInData: clockInData,
                  holidayDescription: _getHolidayDescription(selectedDate),
                  isLoading: isLoading,
                  isKnownHoliday: widget.holidayDateTimes.contains(
                    selectedDate,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeQueryTabView extends StatefulWidget {
  const _RangeQueryTabView();
  @override
  State<_RangeQueryTabView> createState() => _RangeQueryTabViewState();
}

class _RangeQueryTabViewState extends State<_RangeQueryTabView> {
  // Replace state variables with Jokers
  late final Joker<DateTime?> _startDateJoker;
  late final Joker<DateTime?> _endDateJoker;
  late final Joker<List<ClockInData>> _resultsJoker;
  late final Joker<bool> _loadingJoker;

  @override
  void initState() {
    super.initState();
    // Initialize Jokers
    _startDateJoker = Joker<DateTime?>(null);
    _endDateJoker = Joker<DateTime?>(null);
    _resultsJoker = Joker<List<ClockInData>>([]);
    _loadingJoker = Joker<bool>(false);
  }

  // Methods updated to use Jokers instead of setState

  void _showDateRangePickerInSheet() {
    // Read initial range from Jokers
    PickerDateRange? initialRange;
    final currentStart = _startDateJoker.state;
    final currentEnd = _endDateJoker.state;
    if (currentStart != null && currentEnd != null) {
      initialRange = PickerDateRange(currentStart, currentEnd);
    } else if (currentStart != null) {
      initialRange = PickerDateRange(currentStart, currentStart);
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        PickerDateRange? currentSheetSelection = initialRange;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder:
              (_, scrollController) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "選擇日期範圍",
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(height: 10),
                    Expanded(
                      child: SfDateRangePicker(
                        initialSelectedRange: currentSheetSelection,
                        onSelectionChanged: (args) {
                          if (args.value is PickerDateRange) {
                            currentSheetSelection = args.value;
                          }
                        },
                        selectionMode: DateRangePickerSelectionMode.range,
                        view: DateRangePickerView.month,
                        monthViewSettings:
                            const DateRangePickerMonthViewSettings(
                              firstDayOfWeek: 1,
                            ),
                        headerStyle: DateRangePickerHeaderStyle(
                          textAlign: TextAlign.center,
                          textStyle:
                              Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                        monthCellStyle: DateRangePickerMonthCellStyle(
                          todayTextStyle: TextStyle(
                            color: Theme.of(sheetContext).colorScheme.primary,
                          ),
                          todayCellDecoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(sheetContext).colorScheme.primary,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        rangeSelectionColor: Theme.of(
                          sheetContext,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.4),
                        startRangeSelectionColor:
                            Theme.of(sheetContext).colorScheme.primaryContainer,
                        endRangeSelectionColor:
                            Theme.of(sheetContext).colorScheme.primaryContainer,
                        selectionTextStyle: TextStyle(
                          color:
                              Theme.of(
                                sheetContext,
                              ).colorScheme.onPrimaryContainer,
                        ),
                        rangeTextStyle: TextStyle(
                          color: Theme.of(sheetContext).colorScheme.onSurface,
                        ),
                        minDate: DateTime(2020),
                        maxDate: DateTime(2030),
                        showNavigationArrow: true,
                        showActionButtons: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text('取消'),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
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
                              Navigator.pop(sheetContext);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  // Update range setting methods to use Jokers (remove batch)
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
    final lastDay = DateTime(
      n.year,
      n.month + 1,
      0,
    ); // 0th day of next month is last day of current
    _setRange(firstDay, lastDay);
  }

  // Update query method (no batch needed here)
  Future<void> _performQuery() async {
    final startDate = _startDateJoker.state;
    final endDate = _endDateJoker.state;

    if (startDate == null || endDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先選擇日期範圍')));
      return;
    }
    if (endDate.isBefore(startDate)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('結束日期不能早於開始日期')));
      return;
    }

    _loadingJoker.trick(true);
    _resultsJoker.trick([]);

    try {
      final results = await fetchPunchInDataForRange(startDate, endDate);
      if (mounted) {
        _resultsJoker.trick(results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('查詢失敗: $e')));
        _resultsJoker.trick([]);
      }
    } finally {
      if (mounted) {
        _loadingJoker.trick(false);
      }
    }
  }

  // Update clear method to use Jokers (remove batch)
  void _clearQuery() {
    _startDateJoker.trick(null);
    _endDateJoker.trick(null);
    _resultsJoker.trick([]);
    _loadingJoker.trick(false);
  }

  @override
  Widget build(BuildContext context) {
    return [
      _startDateJoker,
      _endDateJoker,
      _loadingJoker,
      _resultsJoker,
    ].assemble<(DateTime?, DateTime?, bool, List<ClockInData>)>(
      converter:
          (values) => (
            values[0] as DateTime?,
            values[1] as DateTime?,
            values[2] as bool,
            values[3] as List<ClockInData>,
          ),
      builder: (context, queryState) {
        final (startDate, endDate, isLoading, results) = queryState;
        return Column(
          children: [
            FilterArea(
              selectedStartDate: startDate,
              selectedEndDate: endDate,
              onSelectRange: _showDateRangePickerInSheet,
              onSetYesterday: _setRangeToYesterday,
              onSetToday: _setRangeToToday,
              onSetThisWeek: _setRangeToThisWeek,
              onSetThisMonth: _setRangeToThisMonth,
              onClear: _clearQuery,
              onQuery: _performQuery,
            ),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: QueryResultList(isLoading: isLoading, results: results),
            ),
          ],
        );
      },
    );
  }
}
