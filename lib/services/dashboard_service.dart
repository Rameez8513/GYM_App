import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/constants/firestore_paths.dart';
import '../models/dashboard_stats_model.dart';
import '../models/member_model.dart';
import '../models/payment_model.dart';

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<DashboardStatsModel> streamDashboardStats() {
    late final StreamController<DashboardStatsModel> controller;
    StreamSubscription? memberSub;
    StreamSubscription? paymentSub;
    List<MemberModel>? members;
    List<PaymentModel>? payments;

    void emit() {
      if (members != null && payments != null && !controller.isClosed) {
        controller.add(_computeStats(members!, payments!));
      }
    }

    controller = StreamController<DashboardStatsModel>(
      onListen: () {
        final now = DateTime.now();
        final since = Timestamp.fromDate(DateTime(now.year, now.month - 5, 1));

        memberSub = _db.collection(FirestorePaths.members).snapshots().listen(
          (snap) {
            members = snap.docs
                .map((d) => MemberModel.fromMap(d.id, d.data()))
                .toList();
            emit();
          },
          onError: controller.addError,
        );

        paymentSub = _db
            .collection(FirestorePaths.payments)
            .where('paidDate', isGreaterThanOrEqualTo: since)
            .snapshots()
            .listen(
          (snap) {
            payments = snap.docs
                .map((d) => PaymentModel.fromMap(d.id, d.data()))
                .toList();
            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () {
        memberSub?.cancel();
        paymentSub?.cancel();
      },
    );

    return controller.stream;
  }

  DashboardStatsModel _computeStats(
      List<MemberModel> members, List<PaymentModel> payments) {
    final activeMembers =
        members.where((m) => m.status == MemberStatus.active).toList();

    final paid = activeMembers.where((m) => m.currentMonthPaid).length;
    final unpaid = activeMembers.length - paid;
    final overdue = activeMembers.where((m) => m.isOverdue).length;
    final expiringSoon = activeMembers.where((m) => m.isExpiringSoon).length;
    final male = activeMembers.where((m) => m.gender == Gender.male).length;
    final female = activeMembers.where((m) => m.gender == Gender.female).length;

    final now = DateTime.now();
    final thisMonthRevenue = payments
        .where(
            (p) => p.paidDate.year == now.year && p.paidDate.month == now.month)
        .fold<double>(0, (sum, p) => sum + p.amount);

    final trend = <MonthlyRevenuePoint>[];
    for (int i = 5; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      final label = DateFormat('MMM').format(target);
      final total = payments
          .where((p) =>
              p.paidDate.year == target.year &&
              p.paidDate.month == target.month)
          .fold<double>(0, (sum, p) => sum + p.amount);
      trend.add(MonthlyRevenuePoint(monthLabel: label, amount: total));
    }

    return DashboardStatsModel(
      totalActiveMembers: activeMembers.length,
      currentMonthRevenue: thisMonthRevenue,
      paidCount: paid,
      unpaidCount: unpaid,
      overdueCount: overdue,
      expiringSoonCount: expiringSoon,
      maleCount: male,
      femaleCount: female,
      revenueTrend: trend,
    );
  }
}
