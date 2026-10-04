import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/error_utils.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<PaymentModel>>? _sub;

  List<PaymentModel> _allPayments = [];
  bool _isLoading = true;
  String? _error;

  List<PaymentModel> get allPayments => _allPayments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void bind(bool loggedIn) {
    if (loggedIn) {
      if (_sub != null) return;
      _subscribe();
    } else {
      _sub?.cancel();
      _sub = null;
      _allPayments = [];
      _isLoading = true;
      _error = null;
    }
  }

  void _subscribe() {
    _isLoading = true;
    _error = null;
    _sub = _service.streamAllPayments().listen(
      (payments) {
        _allPayments = payments;
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

  Stream<List<PaymentModel>> paymentsForMember(String memberId) {
    return _service.streamPaymentsForMember(memberId);
  }

  Future<void> recordPayment({
    required String memberId,
    required String memberName,
    required double amount,
    required String method,
  }) {
    final now = DateTime.now();
    final payment = PaymentModel(
      id: _uuid.v4(),
      memberId: memberId,
      memberName: memberName,
      amount: amount,
      paidDate: now,
      method: method == 'cash' ? PaymentMethod.cash : PaymentMethod.online,
      monthLabel: DateFormat('MMMM yyyy').format(now),
      createdAt: now,
    );
    return _service.recordPayment(payment);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
