import 'dart:async';

import 'package:animated_flip_counter/animated_flip_counter.dart';
// Import the new TimeCard widget
import 'package:auto_nueip/presentation/widgets/time_card.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';

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
  late final Joker<DateTime?> _clockInTimeJoker; // Joker for clock-in time
  late final Joker<DateTime?> _clockOutTimeJoker; // Joker for clock-out time
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeJoker = Joker(DateTime.now());
    _clockInTimeJoker = Joker(null); // Initialize with null
    _clockOutTimeJoker = Joker(null); // Initialize with null
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _timeJoker.trick(DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Jokers without keepAlive: true are disposed automatically by listeners
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateTextStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final dayTextStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.outline,
    );
    final timeTextStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 2.0,
      color: Theme.of(context).colorScheme.primary,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('打卡鐘')
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.2, duration: 400.ms),
        elevation: 0,
      ),
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

              _clockInTimeJoker.perform(
                builder:
                    (context, clockInState) => _clockOutTimeJoker.perform(
                      builder: (context, clockOutState) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Animate(
                              target: clockInState == null ? 1.0 : 0.0,
                              effects: [
                                ShakeEffect(
                                  hz: 4,
                                  curve: Curves.easeInOutCubic,
                                  duration: 500.ms,
                                ),
                              ],
                              child: ElevatedButton.icon(
                                    icon: const Icon(Icons.work_outline),
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
                                        clockInState == null
                                            ? () {
                                              _clockInTimeJoker.trick(
                                                DateTime.now(),
                                              );
                                            }
                                            : null,
                                  )
                                  .animate()
                                  .fadeIn(delay: 500.ms, duration: 600.ms)
                                  .slideX(
                                    begin: -0.5,
                                    duration: 500.ms,
                                    curve: Curves.easeOut,
                                  ),
                            ),

                            const Gap(30),

                            Animate(
                              target:
                                  clockOutState == null && clockInState != null
                                      ? 1.0
                                      : 0.0,
                              effects: [
                                ShakeEffect(
                                  hz: 4,
                                  curve: Curves.easeInOutCubic,
                                  duration: 500.ms,
                                ),
                              ],
                              child: ElevatedButton.icon(
                                    icon: const Icon(Icons.work_off_outlined),
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
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                      foregroundColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSecondary,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed:
                                        clockInState != null &&
                                                clockOutState == null
                                            ? () {
                                              _clockOutTimeJoker.trick(
                                                DateTime.now(),
                                              );
                                            }
                                            : null,
                                  )
                                  .animate()
                                  .fadeIn(delay: 500.ms, duration: 600.ms)
                                  .slideX(
                                    begin: 0.5,
                                    duration: 500.ms,
                                    curve: Curves.easeOut,
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
              ),

              const Gap(30),

              IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TimeCard(
                            timeJoker: _clockInTimeJoker,
                            title: '上班時間',
                            icon: Icons.login,
                            iconColor: Colors.green,
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: TimeCard(
                            timeJoker: _clockOutTimeJoker,
                            title: '下班時間',
                            icon: Icons.logout,
                            iconColor: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 600.ms)
                  .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }
}
