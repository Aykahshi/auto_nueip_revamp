import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

import '../utils/global_presenter.dart';

class RefreshButton extends StatelessWidget {
  const RefreshButton({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () => _onRefresh(type),
    );
  }
}

Future<void> _onRefresh(String type) async {
  Circus.find<GlobalPresenter>().refresh(type);
}
