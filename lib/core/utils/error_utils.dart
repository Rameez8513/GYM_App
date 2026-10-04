import 'package:flutter/foundation.dart';

String friendlyError(Object error) {
  if (kDebugMode) debugPrint('App error: $error');
  final text = error.toString();
  if (text.contains('unavailable') || text.contains('network')) {
    return 'No internet connection. Please check your network and try again.';
  }
  return 'Unable to load data right now. Please try again.';
}
