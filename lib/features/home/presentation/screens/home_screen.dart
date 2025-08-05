import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/notification.dart';
import '../../../../core/widgets/refresh_button.dart';
import '../../../calendar/data/models/daily_clock_detail.dart';
import '../../domain/entities/clock_action_enum.dart';
import '../../domain/entities/clock_state.dart';
import '../presenters/clock_presenter.dart';
import '../widgets/time_card.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final addressJoker = Circus.find<Joker<String>>('companyAddress');

    final ClockPresenter presenter = Circus.find<ClockPresenter>();

    final dateTextStyle = context.textTheme.titleMedium?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
      fontSize: context.sp(16),
    );
    final dayTextStyle = context.textTheme.titleSmall?.copyWith(
      color: context.colorScheme.outline,
      fontSize: context.sp(14),
    );
    final timeTextStyle = context.textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: context.w(2.0),
      color: context.colorScheme.primary,
      fontSize: context.sp(45),
    );

    return presenter.watch(
      onStateChange: (context, state) {
        if (state.status == ClockActionStatus.success) {
          NotificationUtils.showSimpleNotification(
            87,
            '打卡成功！',
            '打卡時間：${DateFormat('yyyy/MM/dd kk:mm:ss').format(DateTime.now())}',
          );
        } else if (state.status == ClockActionStatus.failure) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('打卡失敗，請重新嘗試')));
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('打卡鐘'),
          elevation: 1,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: '通知中心',
              onPressed: () {
                context.pushRoute(const NoticeRoute());
              },
            ),
            const RefreshButton(type: 'clock'),
          ],
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(20)),
            child: addressJoker.perform(
              builder: (context, companyAddress) {
                final bool isAddressSet = companyAddress.isNotEmpty;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // --- Address Warning Section --- (Conditional display based on Joker state)
                    if (!isAddressSet)
                      Card(
                            color: context.colorScheme.errorContainer
                                .withValues(alpha: 0.8),
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: context.h(20)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                context.r(12),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: context.h(12),
                                horizontal: context.w(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: context.colorScheme.onErrorContainer,
                                  ),
                                  Gap(context.w(12)),
                                  Expanded(
                                    child: Text(
                                      '尚未設定公司地址，打卡功能已禁用。\n請至「設定 > 編輯帳號資訊」設定。',
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(
                                            color:
                                                context
                                                    .colorScheme
                                                    .onErrorContainer,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.settings,
                                      color:
                                          context.colorScheme.onErrorContainer,
                                    ),
                                    tooltip: '前往設定',
                                    onPressed: () {
                                      context.pushRoute(
                                        const ProfileEditingRoute(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .shakeX(hz: 3, amount: 4),

                    Card(
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(16)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: context.h(24),
                              horizontal: context.w(32),
                            ),
                            child: presenter.timeJoker.perform(
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
                                    Gap(context.h(4)),
                                    Text(
                                      formattedDay,
                                      style: dayTextStyle,
                                    ).animate().fadeIn(delay: 300.ms),
                                    Gap(context.h(16)),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedFlipCounter(
                                          value: currentTime.hour,
                                          duration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          textStyle: timeTextStyle,
                                          prefix:
                                              currentTime.hour < 10 ? "0" : "",
                                        ),
                                        Text(
                                          ":",
                                          style: timeTextStyle?.copyWith(
                                            fontWeight: FontWeight.normal,
                                            fontSize: context.sp(45),
                                          ),
                                        ),
                                        AnimatedFlipCounter(
                                          value: currentTime.minute,
                                          duration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          textStyle: timeTextStyle,
                                          prefix:
                                              currentTime.minute < 10
                                                  ? "0"
                                                  : "",
                                        ),
                                        Text(
                                          ":",
                                          style: timeTextStyle?.copyWith(
                                            fontWeight: FontWeight.normal,
                                            fontSize: context.sp(45),
                                          ),
                                        ),
                                        AnimatedFlipCounter(
                                          value: currentTime.second,
                                          duration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          textStyle: timeTextStyle,
                                          prefix:
                                              currentTime.second < 10
                                                  ? "0"
                                                  : "",
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
                        .slideY(
                          begin: 0.2,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        )
                        .then(delay: 1500.ms)
                        .shimmer(
                          duration: 1800.ms,
                          delay: 500.ms,
                          color: context.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                        ),

                    Gap(context.h(40)),

                    // --- Clock Action Buttons ---
                    presenter.focusOn<
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
                        final isActionLoading =
                            status == ClockActionStatus.loading;

                        final bool canProcess =
                            canClockIn && isAddressSet && !isActionLoading;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // --- Clock In Button ---
                            ElevatedButton.icon(
                                  icon:
                                      isActionLoading &&
                                              activeAction == ClockAction.IN
                                          ? SizedBox(
                                            width: context.r(20),
                                            height: context.r(20),
                                            child: CircularProgressIndicator(
                                              strokeWidth: context.w(2),
                                            ),
                                          )
                                          : const Icon(Icons.work_outline),
                                  label: const Text('上班打卡'),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.w(32),
                                      vertical: context.h(16),
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: context.sp(18),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        context.r(30),
                                      ),
                                    ),
                                  ),
                                  onPressed:
                                      canProcess
                                          ? () => presenter.performClockAction(
                                            ClockAction.IN,
                                          )
                                          : null,
                                )
                                .animate(target: canProcess ? 1.0 : 0.8)
                                .scaleXY(
                                  end: canProcess ? 1.0 : 0.95,
                                  duration: 200.ms,
                                )
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
                                          ? SizedBox(
                                            width: context.r(20),
                                            height: context.r(20),
                                            child: CircularProgressIndicator(
                                              strokeWidth: context.w(2),
                                            ),
                                          )
                                          : const Icon(Icons.work_off_outlined),
                                  label: const Text('下班打卡'),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.w(32),
                                      vertical: context.h(16),
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: context.sp(18),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    backgroundColor:
                                        context.colorScheme.secondary,
                                    foregroundColor:
                                        context.colorScheme.onSecondary,
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        context.r(30),
                                      ),
                                    ),
                                  ),
                                  onPressed:
                                      canClockOut &&
                                              isAddressSet &&
                                              !isActionLoading
                                          ? () => presenter.performClockAction(
                                            ClockAction.OUT,
                                          )
                                          : null,
                                )
                                .animate(
                                  target:
                                      canClockOut &&
                                              isAddressSet &&
                                              !isActionLoading
                                          ? 1.0
                                          : 0.8,
                                )
                                .scaleXY(
                                  end:
                                      canClockOut &&
                                              isAddressSet &&
                                              !isActionLoading
                                          ? 1.0
                                          : 0.95,
                                  duration: 200.ms,
                                )
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

                    Gap(context.h(30)),

                    // --- Time Cards Display ---
                    presenter.focusOn<(ClockTimeStatus, DailyClockDetail?)>(
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

                        final isTimeLoading =
                            timeStatus == ClockTimeStatus.loading;

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
                                  Gap(context.w(16)),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

const List<String> _zhWeekdays = [
  '星期一',
  '星期二',
  '星期三',
  '星期四',
  '星期五',
  '星期六',
  '星期日',
];
