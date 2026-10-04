import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

bool isWideScreen(BuildContext context) =>
    MediaQuery.of(context).size.width >= AppSpacing.tabletBreakpoint;

void showAppSnackBar(BuildContext context, String message,
    {Color? backgroundColor, SnackBarAction? action}) {
  final wide = isWideScreen(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      width: wide ? 420 : null,
      action: action,
    ),
  );
}

Future<T?> showAppDialog<T>(BuildContext context,
    {required WidgetBuilder builder}) {
  final wide = isWideScreen(context);
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      final dialog = builder(ctx);
      if (!wide) return dialog;
      return Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420), child: dialog));
    },
  );
}

Future<T?> showAppBottomSheet<T>(BuildContext context,
    {required WidgetBuilder builder, bool scrollControlled = false}) {
  final wide = isWideScreen(context);
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: scrollControlled,
    builder: (ctx) {
      final sheet = builder(ctx);
      if (!wide) return sheet;
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480), child: sheet),
      );
    },
  );
}
