import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/utils/error_utils.dart';
import '../models/dashboard_stats_model.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();
  StreamSubscription<DashboardStatsModel>? _sub;

  DashboardStatsModel _stats = DashboardStatsModel.empty();
  bool _isLoading = true;
  String? _error;

  DashboardStatsModel get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void bind(bool loggedIn) {
    if (loggedIn) {
      if (_sub != null) return;
      _subscribe();
    } else {
      _sub?.cancel();
      _sub = null;
      _stats = DashboardStatsModel.empty();
      _isLoading = true;
      _error = null;
    }
  }

  void _subscribe() {
    _isLoading = true;
    _error = null;
    _sub = _service.streamDashboardStats().listen(
      (stats) {
        _stats = stats;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = friendlyError(e);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void retry() {
    _sub?.cancel();
    _sub = null;
    _subscribe();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
