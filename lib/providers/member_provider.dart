import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/error_utils.dart';
import '../models/member_model.dart';
import '../models/payment_model.dart';
import '../services/member_service.dart';

enum MemberQuickFilter { all, active, paid, unpaid, expiring, inactive }

enum MemberGenderFilter { all, male, female }

class MemberProvider extends ChangeNotifier {
  final MemberService _service = MemberService();
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<MemberModel>>? _sub;
  final Set<String> _autoExpiring = {};

  List<MemberModel> _members = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  MemberQuickFilter _quickFilter = MemberQuickFilter.all;
  MemberGenderFilter _genderFilter = MemberGenderFilter.all;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  MemberQuickFilter get quickFilter => _quickFilter;
  MemberGenderFilter get genderFilter => _genderFilter;
  List<MemberModel> get allMembers => _members;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _quickFilter != MemberQuickFilter.all ||
      _genderFilter != MemberGenderFilter.all;

  void bind(bool loggedIn) {
    if (loggedIn) {
      if (_sub != null) return;
      _subscribe();
    } else {
      _sub?.cancel();
      _sub = null;
      _members = [];
      _isLoading = true;
      _error = null;
      _autoExpiring.clear();
    }
  }

  void _subscribe() {
    _isLoading = true;
    _error = null;
    _sub = _service.streamMembers().listen(
      (members) {
        _members = members;
        _isLoading = false;
        _error = null;
        notifyListeners();
        _autoExpireOverdue(members);
      },
      onError: (Object e) {
        _error = friendlyError(e);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _autoExpireOverdue(List<MemberModel> members) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final m in members) {
      final isPastDue =
          DateTime(m.nextDueDate.year, m.nextDueDate.month, m.nextDueDate.day)
              .isBefore(today);
      if (m.status == MemberStatus.active &&
          m.currentMonthPaid &&
          isPastDue &&
          !_autoExpiring.contains(m.id)) {
        _autoExpiring.add(m.id);
        final log = PaymentModel(
          id: _uuid.v4(),
          memberId: m.id,
          memberName: m.name,
          amount: 0,
          paidDate: now,
          method: PaymentMethod.cash,
          monthLabel: DateFormat('MMMM yyyy').format(now),
          createdAt: now,
          isPaid: false,
        );
        _service
            .markPaymentStatus(memberId: m.id, paid: false, unpaidLog: log)
            .whenComplete(() => _autoExpiring.remove(m.id));
      }
    }
  }

  void retry() {
    _sub?.cancel();
    _sub = null;
    _subscribe();
    notifyListeners();
  }

  bool _matchesQuick(MemberModel m, MemberQuickFilter filter) {
    final isActive = m.status == MemberStatus.active;
    switch (filter) {
      case MemberQuickFilter.all:
        return true;
      case MemberQuickFilter.active:
        return isActive;
      case MemberQuickFilter.paid:
        return isActive && m.currentMonthPaid;
      case MemberQuickFilter.unpaid:
        return isActive && !m.currentMonthPaid;
      case MemberQuickFilter.expiring:
        return isActive && m.isExpiringSoon;
      case MemberQuickFilter.inactive:
        return !isActive;
    }
  }

  int countFor(MemberQuickFilter filter) =>
      _members.where((m) => _matchesQuick(m, filter)).length;

  List<MemberModel> get filteredMembers {
    final query = _searchQuery.trim().toLowerCase();
    return _members.where((m) {
      final matchesSearch =
          query.isEmpty || m.name.toLowerCase().contains(query);
      final matchesGender = _genderFilter == MemberGenderFilter.all ||
          (_genderFilter == MemberGenderFilter.male &&
              m.gender == Gender.male) ||
          (_genderFilter == MemberGenderFilter.female &&
              m.gender == Gender.female);
      return matchesSearch && matchesGender && _matchesQuick(m, _quickFilter);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setQuickFilter(MemberQuickFilter filter) {
    _quickFilter = filter;
    notifyListeners();
  }

  void setGenderFilter(MemberGenderFilter filter) {
    _genderFilter = filter;
    notifyListeners();
  }

  void applyDashboardFilter({
    MemberQuickFilter quick = MemberQuickFilter.all,
    MemberGenderFilter gender = MemberGenderFilter.all,
  }) {
    _searchQuery = '';
    _quickFilter = quick;
    _genderFilter = gender;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _quickFilter = MemberQuickFilter.all;
    _genderFilter = MemberGenderFilter.all;
    notifyListeners();
  }

  MemberModel? getById(String id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addMember({
    required String name,
    required Gender gender,
    required String whatsappNumber,
    String? photoUrl,
    required DateTime dateOfBirth,
    required String cnicNumber,
    required String profession,
    required String address,
    required DateTime joinDate,
    required String planId,
    required String planName,
    required double feeAmount,
    required DateTime nextDueDate,
    required MemberStatus initialStatus,
    required bool initialPaid,
  }) {
    resetFilters();
    final now = DateTime.now();
    final member = MemberModel(
      id: _uuid.v4(),
      name: name,
      gender: gender,
      whatsappNumber: whatsappNumber,
      photoUrl: photoUrl,
      dateOfBirth: dateOfBirth,
      cnicNumber: cnicNumber,
      profession: profession,
      address: address,
      joinDate: joinDate,
      planId: planId,
      planName: planName,
      feeAmount: feeAmount,
      nextDueDate: nextDueDate,
      status: initialStatus,
      currentMonthPaid: initialPaid,
      createdAt: now,
    );
    final payment = initialPaid
        ? PaymentModel(
            id: _uuid.v4(),
            memberId: member.id,
            memberName: name,
            amount: feeAmount,
            paidDate: now,
            method: PaymentMethod.cash,
            monthLabel: DateFormat('MMMM yyyy').format(now),
            createdAt: now,
            isPaid: true,
          )
        : null;
    return _service.addMemberWithPayment(member, payment);
  }

  Future<void> confirmPayment(MemberModel member, {String method = 'cash'}) {
    final now = DateTime.now();
    final payment = PaymentModel(
      id: _uuid.v4(),
      memberId: member.id,
      memberName: member.name,
      amount: member.feeAmount,
      paidDate: now,
      method: method == 'cash' ? PaymentMethod.cash : PaymentMethod.online,
      monthLabel: DateFormat('MMMM yyyy').format(now),
      createdAt: now,
      isPaid: true,
    );
    final planDays = member.planDurationDays > 0 ? member.planDurationDays : 30;
    return _service.recordPaid(
        member.id, payment, now.add(Duration(days: planDays)));
  }

  Future<void> updateMember(MemberModel member) {
    return _service.updateMember(member);
  }

  Future<void> toggleActiveStatus(String memberId, bool isActive) {
    return _service.setActiveStatus(memberId, isActive);
  }

  Future<void> deleteMember(String memberId) {
    return _service.deleteMember(memberId);
  }

  Future<void> markPaid(
      {required String memberId, required DateTime newDueDate}) {
    return _service.markPaymentStatus(
        memberId: memberId, paid: true, newDueDate: newDueDate);
  }

  Future<void> markUnpaid(String memberId) {
    final member = getById(memberId);
    final now = DateTime.now();
    final log = member != null
        ? PaymentModel(
            id: _uuid.v4(),
            memberId: memberId,
            memberName: member.name,
            amount: 0,
            paidDate: now,
            method: PaymentMethod.cash,
            monthLabel: DateFormat('MMMM yyyy').format(now),
            createdAt: now,
            isPaid: false,
          )
        : null;
    return _service.markPaymentStatus(
        memberId: memberId, paid: false, unpaidLog: log);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
