import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('SettingScreen')));
  }
}
