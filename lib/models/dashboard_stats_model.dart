class MonthlyRevenuePoint {
  final String monthLabel;
  final double amount;
  MonthlyRevenuePoint({required this.monthLabel, required this.amount});
}

class DashboardStatsModel {
  final int totalActiveMembers;
  final double currentMonthRevenue;
  final int paidCount;
  final int unpaidCount;
  final int overdueCount;
  final int expiringSoonCount;
  final int maleCount;
  final int femaleCount;
  final List<MonthlyRevenuePoint> revenueTrend;

  DashboardStatsModel({
    required this.totalActiveMembers,
    required this.currentMonthRevenue,
    required this.paidCount,
    required this.unpaidCount,
    required this.overdueCount,
    required this.expiringSoonCount,
    required this.maleCount,
    required this.femaleCount,
    required this.revenueTrend,
  });

  factory DashboardStatsModel.empty() {
    return DashboardStatsModel(
      totalActiveMembers: 0,
      currentMonthRevenue: 0,
      paidCount: 0,
      unpaidCount: 0,
      overdueCount: 0,
      expiringSoonCount: 0,
      maleCount: 0,
      femaleCount: 0,
      revenueTrend: const [],
    );
  }
}
