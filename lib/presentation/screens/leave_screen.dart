import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../core/extensions/theme_extensions.dart';

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
            Icon(Icons.build_outlined, size: context.r(64)),
            Gap(context.h(16)),
            Text(
              '開發中',
              style: context.textTheme.titleLarge?.copyWith(
                fontSize: context.sp(22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
