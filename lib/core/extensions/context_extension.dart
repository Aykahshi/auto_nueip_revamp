import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  double get vw => MediaQuery.sizeOf(this).width;
  double get vh => MediaQuery.sizeOf(this).height;
  double get safeAreaBottom => MediaQuery.viewInsetsOf(this).bottom;
}
