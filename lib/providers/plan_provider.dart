import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/error_utils.dart';
import '../models/plan_model.dart';
import '../services/plan_service.dart';

class PlanProvider extends ChangeNotifier {
  final PlanService _service = PlanService();
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<PlanModel>>? _sub;

  List<PlanModel> _plans = [];
  bool _isLoading = true;
  String? _error;

  List<PlanModel> get plans => _plans;
  List<PlanModel> get activePlans => _plans.where((p) => p.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  void bind(bool loggedIn) {
    if (loggedIn) {
      if (_sub != null) return;
      _subscribe();
    } else {
      _sub?.cancel();
      _sub = null;
      _plans = [];
      _isLoading = true;
      _error = null;
    }
  }

  void _subscribe() {
    _isLoading = true;
    _error = null;
    _sub = _service.streamPlans().listen(
      (plans) {
        _plans = plans;
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

  PlanModel? getById(String id) {
    try {
      return _plans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> createPlan({
    required String name,
    required double price,
    required int durationInDays,
  }) {
    final plan = PlanModel(
      id: _uuid.v4(),
      name: name,
      price: price,
      durationInDays: durationInDays,
      isActive: true,
      createdAt: DateTime.now(),
    );
    return _service.addPlan(plan);
  }

  Future<void> updatePlan(PlanModel plan) {
    return _service.updatePlan(plan);
  }

  Future<void> deletePlan(String planId) {
    return _service.deletePlan(planId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
