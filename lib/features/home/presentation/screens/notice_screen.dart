import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:joker_state/joker_state.dart';

import '../presenters/notice_presenter.dart';
import '../widgets/notice_list_tile.dart';

@RoutePage()
class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final presenter = Circus.find<NoticePresenter>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知中心'),
        centerTitle: true,
        elevation: 1,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200 &&
              !presenter.state.isLoading) {
            presenter.fetchNextPage();
          }
          return false;
        },
        child: presenter.perform(
          builder: (context, state) {
            if (state.isLoading && state.notices.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.failure != null && state.notices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: context.r(48)),
                    Gap(context.h(16)),
                    Text('無法載入通知：${state.failure!.message}'),
                    Gap(context.h(16)),
                    ElevatedButton(
                      onPressed: () => presenter.refresh(),
                      child: const Text('重試'),
                    ),
                  ],
                ),
              );
            }

            if (state.notices.isEmpty) {
              return const Center(child: Text('沒有任何通知'));
            }

            return RefreshIndicator(
              onRefresh: () => presenter.refresh(),
              child: AnimationLimiter(
                child: ListView.builder(
                  itemCount: state.notices.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.notices.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final notice = state.notices[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: NoticeListTile(notice: notice),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
