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
  late final VoidCallback _cancel;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeJoker = Joker<DateTime>(DateTime.now());
    _clockPresenter = ClockPresenter();

    _cancel = _clockPresenter.listen((previous, current) {
      if (current is ClockSuccess) {
        final time = DateFormat('yyyy/MM/dd kk:mm:ss').format(DateTime.now());
        NotificationUtils.showSimpleNotification(87, '打卡成功！', '打卡時間：$time');
      }

      if (current is ClockFailure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('打卡失敗，請重新嘗試')));
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _timeJoker.trick(DateTime.now());
      }
    });
  }

  Future<void> _performClockAction(ClockAction action) async {
    final session = AuthUtils.getAuthSession();

    double latitude = 22.6283906;
    double longitude = 120.2932479;

    await _clockPresenter.clockAction(
      action: action,
      cookie: session.cookie ?? '',
      csrfToken: session.csrfToken ?? '',
      latitude: latitude,
      longitude: longitude,
      accessToken: session.accessToken ?? '',
    );
  }

  @override
  void dispose() {
    _cancel();
    _timer?.cancel();
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

              _clockPresenter.perform(
                builder: (context, clockState) {
                  bool canClockIn = false;
                  bool canClockOut = false;

                  if (clockState is ClockSuccess) {
                    final detail = clockState.details;
                    canClockIn = detail.clockInTime == null;
                    canClockOut = detail.clockOutTime == null;
                  } else if (clockState is ClockInitial) {
                    canClockIn = true;
                    canClockOut = true;
                  }

                  final isLoading = clockState is ClockLoading;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                            icon:
                                isLoading
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
                                canClockIn && !isLoading
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
                      ElevatedButton.icon(
                            icon:
                                isLoading
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
                                canClockOut && !isLoading
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

              _clockPresenter.perform(
                builder: (context, clockState) {
                  DateTime? clockInTime;
                  DateTime? clockOutTime;

                  if (clockState is ClockSuccess) {
                    final detail = clockState.details;
                    clockInTime =
                        detail.clockInTime != null
                            ? DateFormat('HH:mm:ss').parse(detail.clockInTime!)
                            : null;
                    clockOutTime =
                        detail.clockOutTime != null
                            ? DateFormat('HH:mm:ss').parse(detail.clockOutTime!)
                            : null;
                  }

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
                                isLoading: clockState is ClockLoading,
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: TimeCard(
                                time: clockOutTime,
                                title: '下班時間',
                                icon: Icons.logout,
                                iconColor: Colors.redAccent,
                                isLoading: clockState is ClockLoading,
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
