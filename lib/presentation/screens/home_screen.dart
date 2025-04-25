import 'dart:async';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/utils/auth_utils.dart';
import '../../core/utils/notification.dart';
import '../../data/models/clock_action_enum.dart';
import '../../data/models/daily_clock_detail.dart';
import '../../domain/entities/clock_state.dart';
import '../presenters/clock_presenter.dart';
import '../widgets/time_card.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Define Chinese weekday names outside the state class for better organization
const List<String> _zhWeekdays = [
  '星期一',
  '星期二',
  '星期三',
  '星期四',
  '星期五',
  '星期六',
  '星期日',
];

class _HomeScreenState extends State<HomeScreen> {
  late final Joker<DateTime> _timeJoker;
  late final ClockPresenter _clockPresenter;
  // Listener specifically for clock action status (notifications/snackbars)
  late final VoidCallback _actionStatusCancel;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeJoker = Joker<DateTime>(DateTime.now());
    _clockPresenter = ClockPresenter();

    // Listen to all state changes, but only act on status change
    _actionStatusCancel = _clockPresenter.listen((previous, current) {
      // Only trigger notification/snackbar if action status has changed
      if (previous?.status != current.status) {
        if (current.status == ClockActionStatus.success) {
          final time = DateFormat('yyyy/MM/dd kk:mm:ss').format(DateTime.now());
          NotificationUtils.showSimpleNotification(87, '打卡成功！', '打卡時間：$time');
        } else if (current.status == ClockActionStatus.failure) {
          // Ensure context is available before showing SnackBar
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('打卡失敗，請重新嘗試')));
          }
        }
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _timeJoker.trick(DateTime.now());
      }
    });
    // Initial fetch of clock times should be handled by the presenter
    // e.g., in its onReady method or triggered by a cue.
  }

  Future<void> _performClockAction(ClockAction action) async {
    final session = AuthUtils.getAuthSession();

    // Consider fetching location dynamically if needed
    double latitude = 22.6283906;
    double longitude = 120.2932479;

    await _clockPresenter.clockAction(
      action: action,
      cookie: session.cookie ?? '',
      csrfToken: session.csrfToken ?? '',
      latitude: latitude,
      longitude: longitude,
      // Pass accessToken needed for fetching times after successful action
      accessToken: session.accessToken ?? '',
    );
  }

  @override
  void dispose() {
    _actionStatusCancel(); // Cancel the listener
    _timer?.cancel();
    // Assuming ClockPresenter is managed elsewhere (e.g., Circus)
    // If created locally and not keepAlive, JokerState handles disposal.
    // If keepAlive, ensure proper disposal mechanism is in place.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateTextStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final dayTextStyle = theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.outline,
    );
    final timeTextStyle = theme.textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 2.0,
      color: theme.colorScheme.primary,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('打卡鐘'), elevation: 1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24.0,
                        horizontal: 32.0,
                      ),
                      child: _timeJoker.perform(
                        builder: (context, currentTime) {
                          final formattedDate = DateFormat(
                            'yyyy / MM / dd',
                          ).format(currentTime);
                          final formattedDay =
                              _zhWeekdays[currentTime.weekday - 1];

                          return Column(
                            children: [
                              Text(
                                formattedDate,
                                style: dateTextStyle,
                              ).animate().fadeIn(delay: 200.ms),
                              const Gap(4),
                              Text(
                                formattedDay,
                                style: dayTextStyle,
                              ).animate().fadeIn(delay: 300.ms),
                              const Gap(16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedFlipCounter(
                                    value: currentTime.hour,
                                    duration: const Duration(milliseconds: 500),
                                    textStyle: timeTextStyle,
                                    prefix: currentTime.hour < 10 ? "0" : "",
                                  ),
                                  Text(
                                    ":",
                                    style: timeTextStyle?.copyWith(
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  AnimatedFlipCounter(
                                    value: currentTime.minute,
                                    duration: const Duration(milliseconds: 500),
                                    textStyle: timeTextStyle,
                                    prefix: currentTime.minute < 10 ? "0" : "",
                                  ),
                                  Text(
                                    ":",
                                    style: timeTextStyle?.copyWith(
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  AnimatedFlipCounter(
                                    value: currentTime.second,
                                    duration: const Duration(milliseconds: 500),
                                    textStyle: timeTextStyle,
                                    prefix: currentTime.second < 10 ? "0" : "",
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut)
                  .then(delay: 1500.ms)
                  .shimmer(
                    duration: 1800.ms,
                    delay: 500.ms,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                  ),

              const Gap(40),

              // --- Clock Action Buttons ---
              _clockPresenter.focusOn<
                (
                  ClockActionStatus, // status
                  DailyClockDetail?, // details
                  ClockAction?, // activeAction
                )
              >(
                selector:
                    (state) => (
                      state.status,
                      state.details,
                      state.activeAction,
                    ),
                builder: (context, data) {
                  final status = data.$1;
                  final details = data.$2;
                  final activeAction = data.$3;

                  final bool canClockIn = details?.clockInTime == null;
                  final bool canClockOut =
                      details?.clockInTime != null &&
                      details?.clockOutTime == null;
                  final isActionLoading = status == ClockActionStatus.loading;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // --- Clock In Button ---
                      ElevatedButton.icon(
                            icon:
                                isActionLoading &&
                                        activeAction == ClockAction.IN
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.work_outline),
                            label: const Text('上班打卡'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed:
                                canClockIn && !isActionLoading
                                    ? () => _performClockAction(ClockAction.IN)
                                    : null,
                          )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 600.ms)
                          .slideX(
                            begin: -0.5,
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          ),
                      // --- Clock Out Button ---
                      ElevatedButton.icon(
                            icon:
                                isActionLoading &&
                                        activeAction == ClockAction.OUT
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.work_off_outlined),
                            label: const Text('下班打卡'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSecondary,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed:
                                canClockOut && !isActionLoading
                                    ? () => _performClockAction(ClockAction.OUT)
                                    : null,
                          )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 600.ms)
                          .slideX(
                            begin: 0.5,
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          ),
                    ],
                  );
                },
              ),

              const Gap(30),

              // --- Time Cards Display ---
              _clockPresenter.focusOn<(ClockTimeStatus, DailyClockDetail?)>(
                selector: (state) => (state.timeStatus, state.details),
                builder: (context, data) {
                  final timeStatus = data.$1;
                  final details = data.$2;

                  DateTime? clockInTime;
                  DateTime? clockOutTime;

                  if (details != null) {
                    try {
                      clockInTime =
                          details.clockInTime != null
                              ? DateFormat(
                                'HH:mm:ss',
                              ).parse(details.clockInTime!)
                              : null;
                      clockOutTime =
                          details.clockOutTime != null
                              ? DateFormat(
                                'HH:mm:ss',
                              ).parse(details.clockOutTime!)
                              : null;
                    } catch (e) {
                      // Handle potential parsing errors if format is unexpected
                      debugPrint("Error parsing time string: $e");
                      // Optionally set times to null or show an error state in the card
                      clockInTime = null;
                      clockOutTime = null;
                    }
                  }

                  final isTimeLoading = timeStatus == ClockTimeStatus.loading;

                  return IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TimeCard(
                                time: clockInTime,
                                title: '上班時間',
                                icon: Icons.login,
                                iconColor: Colors.green,
                                isLoading: isTimeLoading,
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: TimeCard(
                                time: clockOutTime,
                                title: '下班時間',
                                icon: Icons.logout,
                                iconColor: Colors.redAccent,
                                isLoading: isTimeLoading,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 600.ms)
                      .slideY(
                        begin: 0.3,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
