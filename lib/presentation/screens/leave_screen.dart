import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

@RoutePage()
class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('請假專區'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.build_outlined, size: 64),
            const Gap(16),
            Text('開發中', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
