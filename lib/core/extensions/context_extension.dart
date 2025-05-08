import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension BuildContextExtension on BuildContext {
  /// Get responsive width
  double w(double width) => width.w;

  /// Get responsive height
  double h(double height) => height.h;

  /// Get responsive radius
  double r(double radius) => radius.r;

  /// Get responsive font size
  double sp(double fontSize) => fontSize.sp;

  /// Get responsive inset (margin/padding)
  double i(double inset) => inset.w;
}
