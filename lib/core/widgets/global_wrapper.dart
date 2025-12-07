import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';
import 'package:toastification/toastification.dart';

import '../utils/global_presenter.dart';

final toast = Toastification();

class GlobalWrapper extends StatelessWidget {
  const GlobalWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final globalPresenter = Circus.find<GlobalPresenter>();

    return globalPresenter.watch(
      onStateChange: (context, state) {
        // Always dismiss all toastifications first
        toast.dismissAll();

        state.when(
          idle: () {},
          networkConnected: () {
            toast.show(
              context: context,
              title: const Text('網路已重新連線'),
              type: ToastificationType.success,
              style: ToastificationStyle.flatColored,
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 2),
              dragToClose: true,
            );
          },
          networkDisconnected: () {
            toast.show(
              context: context,
              title: const Text('網路連線中斷，請檢查網路環境'),
              type: ToastificationType.error,
              style: ToastificationStyle.flatColored,
              alignment: Alignment.bottomCenter,
              dragToClose: true,
            );
          },
        );
      },
      child: child,
    );
  }
}
