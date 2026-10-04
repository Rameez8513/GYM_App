import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

extension BuildContextExtensions on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;

  double get screenWidth => MediaQuery.of(this).size.width;

  bool get isMobile => screenWidth < AppSpacing.mobileBreakpoint;

  bool get isTablet =>
      screenWidth >= AppSpacing.mobileBreakpoint &&
      screenWidth < AppSpacing.tabletBreakpoint;

  bool get isDesktop => screenWidth >= AppSpacing.tabletBreakpoint;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
