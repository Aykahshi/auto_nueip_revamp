import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../presenters/schedule_clock_presenter.dart';

@RoutePage()
class ScheduleClockScreen extends StatelessWidget {
  const ScheduleClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final presenter = Circus.find<ScheduleClockPresenter>();

    return presenter.perform(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('排程打卡功能')),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(context.r(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                    Card(
                      elevation: 4,
                      shadowColor: context.colorScheme.shadow.withValues(
                        alpha: 0.3,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(context.r(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                  '服務狀態: ${state.isServiceRunning ? '運行中' : '已停止'}',
                                  style: context.textTheme.titleLarge,
                                )
                                .animate(
                                  onPlay:
                                      (controller) =>
                                          controller.repeat(reverse: true),
                                )
                                .fadeIn(duration: 600.ms)
                                .then(delay: 200.ms)
                                .shimmer(
                                  duration: 1800.ms,
                                  color:
                                      state.isServiceRunning
                                          ? Colors.green
                                          : Colors.red,
                                ),
                            Gap(context.h(8)),
                            Text(state.lastStatus)
                                .animate()
                                .fadeIn(duration: 300.ms, delay: 300.ms)
                                .moveX(begin: -10, duration: 400.ms),
                          ],
                        ),
                      ),
                    ),
                    Gap(context.h(16)),
                    Card(
                      elevation: 4,
                      shadowColor: context.colorScheme.shadow.withValues(
                        alpha: 0.3,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(context.r(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('工作時間')
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  duration: 400.ms,
                                ),
                            ListTile(
                              tileColor: Colors.transparent,
                              title: const Text('工作開始時間'),
                              subtitle: Text(
                                '${state.workHoursStart.hour}:${state.workHoursStart.minute.toString().padLeft(2, '0')}',
                              ),
                              trailing: const Icon(Icons.access_time),
                              onTap:
                                  () => presenter.selectWorkHoursStart(context),
                            ),
                            ListTile(
                              tileColor: Colors.transparent,
                              title: const Text('工作結束時間'),
                              subtitle: Text(
                                '${state.workHoursEnd.hour}:${state.workHoursEnd.minute.toString().padLeft(2, '0')}',
                              ),
                              trailing: const Icon(Icons.access_time),
                              onTap:
                                  () => presenter.selectWorkHoursEnd(context),
                            ),
                            const Divider(),
                            ListTile(
                              tileColor: Colors.transparent,
                              title: const Text('上班打卡時間'),
                              subtitle: Text(
                                '${state.clockInTime.hour}:${state.clockInTime.minute.toString().padLeft(2, '0')}',
                              ),
                              trailing: const Icon(Icons.login),
                              onTap: () => presenter.selectClockInTime(context),
                            ),
                            ListTile(
                              tileColor: Colors.transparent,
                              title: const Text('下班打卡時間'),
                              subtitle: Text(
                                '${state.clockOutTime.hour}:${state.clockOutTime.minute.toString().padLeft(2, '0')}',
                              ),
                              trailing: const Icon(Icons.logout),
                              onTap:
                                  () => presenter.selectClockOutTime(context),
                            ),
                            const Divider(),
                            ListTile(
                              tileColor: Colors.transparent,
                              title: const Text('彈性時間 (分鐘)'),
                              subtitle: Text('${state.flexibleMinutes} 分鐘'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed:
                                        state.flexibleMinutes > 5
                                            ? () =>
                                                presenter.updateFlexibleMinutes(
                                                  state.flexibleMinutes - 5,
                                                )
                                            : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed:
                                        () => presenter.updateFlexibleMinutes(
                                          state.flexibleMinutes + 5,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            ListTile(
                              tileColor: Colors.transparent,
                              title: const Text('隨機時間範圍 (分鐘)'),
                              subtitle: Text('±${state.randomMinutes} 分鐘'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed:
                                        state.randomMinutes > 1
                                            ? () =>
                                                presenter.updateRandomMinutes(
                                                  state.randomMinutes - 1,
                                                )
                                            : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed:
                                        () => presenter.updateRandomMinutes(
                                          state.randomMinutes + 1,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap(context.h(16)),
                    ElevatedButton(
                      onPressed:
                          state.isLoading ? null : presenter.startService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: context.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: context.h(12)),
                        elevation: 3,
                        shadowColor: context.colorScheme.shadow.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      child:
                          state.isLoading
                              ? SizedBox(
                                    height: context.r(20),
                                    width: context.r(20),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .rotate(
                                    duration: 1500.ms,
                                    begin: 0,
                                    end: 2,
                                    curve: Curves.easeInOut,
                                  )
                              : const Text('啟動服務並設定打卡')
                                  .animate(
                                    onPlay:
                                        (controller) =>
                                            controller.repeat(reverse: true),
                                  )
                                  .fadeIn(duration: 300.ms)
                                  .then(delay: 500.ms)
                                  .shimmer(
                                    duration: 1000.ms,
                                    color: Colors.white70,
                                  ),
                    ),
                    Gap(context.h(8)),
                    ElevatedButton(
                      onPressed: state.isLoading ? null : presenter.stopService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.error,
                        foregroundColor: context.colorScheme.onError,
                        padding: EdgeInsets.symmetric(vertical: context.h(12)),
                        elevation: 3,
                        shadowColor: context.colorScheme.shadow.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      child:
                          state.isLoading
                              ? SizedBox(
                                    height: context.r(20),
                                    width: context.r(20),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .rotate(
                                    duration: 1500.ms,
                                    begin: 0,
                                    end: 2,
                                    curve: Curves.easeInOut,
                                  )
                              : const Text('停止服務')
                                  .animate(
                                    onPlay:
                                        (controller) =>
                                            controller.repeat(reverse: true),
                                  )
                                  .fadeIn(duration: 300.ms)
                                  .then(delay: 500.ms)
                                  .shimmer(
                                    duration: 1000.ms,
                                    color: Colors.white70,
                                  ),
                    ),
                    Gap(context.h(8)),
                  ]
                  .animate(interval: 100.ms)
                  .fadeIn(duration: 500.ms, delay: 100.ms)
                  .moveY(begin: 20, curve: Curves.easeOutQuad),
            ),
          ),
        );
      },
    );
  }
}
