import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/dashboard_stats_model.dart';
import '../../models/member_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/member_provider.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/common/app_error_view.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../widgets/common/gender_icon.dart';
import '../../widgets/common/premium_app_bar.dart';

BoxDecoration _flatCard({Color? accent}) => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );

Widget _iconBadge(IconData icon,
    {Color color = AppColors.primary, double size = 44}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
    ),
    child: Icon(icon, size: size * 0.46, color: color),
  );
}

Widget _sectionLabel(String text) {
  return Text(
    text.toUpperCase(),
    style: AppTextStyles.label.copyWith(
      letterSpacing: 1,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _revenueVisible = false;

  void _goToMembers(
    BuildContext context, {
    MemberQuickFilter quick = MemberQuickFilter.all,
    MemberGenderFilter gender = MemberGenderFilter.all,
  }) {
    context
        .read<MemberProvider>()
        .applyDashboardFilter(quick: quick, gender: gender);
    context.go('/members');
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final members = context.watch<MemberProvider>().allMembers;
    final stats = dashboard.stats;
    final isDesktop =
        MediaQuery.of(context).size.width >= AppSpacing.tabletBreakpoint;

    final pendingMembers = members
        .where((m) => m.status == MemberStatus.active && !m.currentMonthPaid)
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    Widget body;
    if (dashboard.error != null) {
      body = AppErrorView(message: dashboard.error!, onRetry: dashboard.retry);
    } else if (dashboard.isLoading) {
      body = const AppLoadingIndicator();
    } else {
      final membersCard = _MembersCard(
        stats: stats,
        onTotal: () => _goToMembers(context, quick: MemberQuickFilter.active),
        onMale: () => _goToMembers(context,
            quick: MemberQuickFilter.active, gender: MemberGenderFilter.male),
        onFemale: () => _goToMembers(context,
            quick: MemberQuickFilter.active, gender: MemberGenderFilter.female),
      );

      final feeRow = Row(
        children: [
          Expanded(
            child: _FeeTile(
              label: 'Paid',
              count: stats.paidCount,
              color: AppColors.success,
              icon: PhosphorIconsFill.checkCircle,
              onTap: () => _goToMembers(context, quick: MemberQuickFilter.paid),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _FeeTile(
              label: 'Unpaid',
              count: stats.unpaidCount,
              color: AppColors.danger,
              icon: PhosphorIconsFill.xCircle,
              onTap: () =>
                  _goToMembers(context, quick: MemberQuickFilter.unpaid),
            ),
          ),
        ],
      );

      final expiringBanner = stats.expiringSoonCount > 0
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: _ExpiringBanner(
                count: stats.expiringSoonCount,
                onTap: () =>
                    _goToMembers(context, quick: MemberQuickFilter.expiring),
              ),
            )
          : const SizedBox.shrink();

      final pendingCard = _PendingCard(members: pendingMembers);
      final revenueCard = _RevenueCard(
        stats: stats,
        visible: _revenueVisible,
        onToggle: () => setState(() => _revenueVisible = !_revenueVisible),
      );
      final pieCard =
          _GenderPieCard(male: stats.maleCount, female: stats.femaleCount);

      body = LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 820;
          final children = wide
              ? <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            membersCard,
                            const SizedBox(height: AppSpacing.lg),
                            _sectionLabel('Fees This Month'),
                            const SizedBox(height: AppSpacing.sm),
                            feeRow,
                            expiringBanner,
                            const SizedBox(height: AppSpacing.md),
                            revenueCard,
                            const SizedBox(height: AppSpacing.md),
                            pieCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: pendingCard),
                    ],
                  ),
                ]
              : <Widget>[
                  membersCard,
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel('Fees This Month'),
                  const SizedBox(height: AppSpacing.sm),
                  feeRow,
                  expiringBanner,
                  const SizedBox(height: AppSpacing.md),
                  pendingCard,
                  const SizedBox(height: AppSpacing.md),
                  revenueCard,
                  const SizedBox(height: AppSpacing.md),
                  pieCard,
                ];
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1100 : 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
                children: children,
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : const PremiumAppBar(title: 'JOJI GYM', centerTitle: true),
      body: SafeArea(child: body),
    );
  }
}

class _MembersCard extends StatelessWidget {
  final DashboardStatsModel stats;
  final VoidCallback onTotal;
  final VoidCallback onMale;
  final VoidCallback onFemale;

  const _MembersCard(
      {required this.stats,
      required this.onTotal,
      required this.onMale,
      required this.onFemale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _flatCard(),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTotal,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Row(
                children: [
                  _iconBadge(PhosphorIconsFill.usersThree, size: 52),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACTIVE MEMBERS',
                            style: AppTextStyles.label.copyWith(
                                letterSpacing: 1,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('${stats.totalActiveMembers}',
                            style: AppTextStyles.statNumber.copyWith(
                                fontSize: 30, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const Icon(PhosphorIconsBold.caretRight,
                      color: AppColors.textDisabled, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child: _GenderPill(
                      label: 'Male',
                      color: AppColors.maleColor,
                      count: stats.maleCount,
                      isMale: true,
                      onTap: onMale)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _GenderPill(
                      label: 'Female',
                      color: AppColors.femaleColor,
                      count: stats.femaleCount,
                      isMale: false,
                      onTap: onFemale)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderPill extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  final bool isMale;
  final VoidCallback onTap;

  const _GenderPill(
      {required this.label,
      required this.color,
      required this.count,
      required this.isMale,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2, vertical: AppSpacing.sm + 2),
          child: Row(
            children: [
              GenderIcon(
                  gender: isMale ? Gender.male : Gender.female, size: 26),
              const SizedBox(width: AppSpacing.sm),
              Text('$count',
                  style: AppTextStyles.body.copyWith(
                      fontSize: 18, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(label,
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 14),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeeTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _FeeTile(
      {required this.label,
      required this.count,
      required this.color,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              _iconBadge(icon, color: color, size: 38),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$count',
                        style: AppTextStyles.title.copyWith(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    Text(label,
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiringBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ExpiringBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningBg,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
          child: Row(
            children: [
              const Icon(PhosphorIconsFill.clockCountdown,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$count ${count == 1 ? 'member' : 'members'} due within 7 days',
                  style: AppTextStyles.body.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning),
                ),
              ),
              const Icon(PhosphorIconsRegular.caretRight,
                  color: AppColors.warning, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final List<MemberModel> members;

  const _PendingCard({required this.members});

  String _dueText(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff =
        DateTime(due.year, due.month, due.day).difference(today).inDays;
    if (diff < 0) return 'Pending ${-diff} ${diff == -1 ? 'day' : 'days'}';
    if (diff == 0) return 'Due today';
    return 'Due in $diff ${diff == 1 ? 'day' : 'days'}';
  }

  @override
  Widget build(BuildContext context) {
    final shown = members.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _flatCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Payments Pending',
                      style: AppTextStyles.title.copyWith(
                          fontSize: 17, fontWeight: FontWeight.w700))),
              TextButton(
                onPressed: () => context.go('/payments'),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32)),
                child: Text('View all',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(PhosphorIconsFill.checkCircle,
                      color: AppColors.success, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text('All fees are collected. Nothing pending.',
                          style: AppTextStyles.bodyMuted)),
                ],
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < shown.length; i++) ...[
                  if (i > 0) Container(height: 1, color: AppColors.divider),
                  InkWell(
                    onTap: () => context.push('/members/${shown[i].id}'),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          GenderIcon(gender: shown[i].gender, size: 38),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(shown[i].name,
                                    style: AppTextStyles.body
                                        .copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                  _dueText(shown[i].nextDueDate),
                                  style: AppTextStyles.bodyMuted.copyWith(
                                    fontSize: 13.5,
                                    color: shown[i].isOverdue
                                        ? AppColors.danger
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Send reminder',
                            onPressed: () => WhatsAppService().sendReminder(
                              phone: shown[i].whatsappNumber,
                              memberName: shown[i].name,
                              amountDue: shown[i].feeAmount,
                            ),
                            icon: const Icon(PhosphorIconsBold.whatsappLogo,
                                color: AppColors.success, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final DashboardStatsModel stats;
  final bool visible;
  final VoidCallback onToggle;

  const _RevenueCard(
      {required this.stats, required this.visible, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final hasData = stats.revenueTrend.any((p) => p.amount > 0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _flatCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue This Month', style: AppTextStyles.bodyMuted),
                    const SizedBox(height: 2),
                    Text(
                      visible
                          ? CurrencyFormatter.format(stats.currentMonthRevenue)
                          : 'PKR ••••••',
                      style: AppTextStyles.title
                          .copyWith(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                    visible
                        ? PhosphorIconsBold.eyeSlash
                        : PhosphorIconsBold.eye,
                    color: AppColors.textSecondary,
                    size: 22),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 170,
            child: !hasData
                ? Center(
                    child: Text('No revenue recorded yet',
                        style: AppTextStyles.bodyMuted))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => AppColors.surfaceElevated,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final point = stats.revenueTrend[group.x];
                            return BarTooltipItem(
                              '${point.monthLabel}\n${CurrencyFormatter.format(rod.toY)}',
                              AppTextStyles.body.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 ||
                                  index >= stats.revenueTrend.length)
                                return const SizedBox.shrink();
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.sm),
                                child: Text(
                                  stats.revenueTrend[index].monthLabel,
                                  style: AppTextStyles.body.copyWith(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups:
                          List.generate(stats.revenueTrend.length, (index) {
                        final point = stats.revenueTrend[index];
                        final isLast = index == stats.revenueTrend.length - 1;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: point.amount,
                              color: AppColors.primary
                                  .withValues(alpha: isLast ? 1.0 : 0.35),
                              width: 22,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GenderPieCard extends StatelessWidget {
  final int male;
  final int female;

  const _GenderPieCard({required this.male, required this.female});

  @override
  Widget build(BuildContext context) {
    final total = male + female;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _flatCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Member Split',
              style: AppTextStyles.title.copyWith(fontSize: 17)),
          const SizedBox(height: AppSpacing.md),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                  child: Text('No active members yet',
                      style: AppTextStyles.bodyMuted)),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                          size: const Size(110, 110),
                          painter: _PiePainter(male: male, female: female)),
                      Text('$total',
                          style: AppTextStyles.title.copyWith(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendRow(
                          color: AppColors.maleColor,
                          label: 'Male',
                          value: male,
                          total: total),
                      const SizedBox(height: AppSpacing.sm),
                      _LegendRow(
                          color: AppColors.femaleColor,
                          label: 'Female',
                          value: female,
                          total: total),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final int male;
  final int female;
  _PiePainter({required this.male, required this.female});

  @override
  void paint(Canvas canvas, Size size) {
    final total = (male + female).toDouble();
    if (total == 0) return;
    final strokeWidth = size.width * 0.18;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final malePaint = Paint()
      ..color = AppColors.maleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final femalePaint = Paint()
      ..color = AppColors.femaleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final maleSweep = 6.2832 * (male / total);
    canvas.drawArc(rect, -1.5708, maleSweep, false, malePaint);
    canvas.drawArc(
        rect, -1.5708 + maleSweep, 6.2832 - maleSweep, false, femalePaint);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.male != male || oldDelegate.female != female;
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final int total;
  const _LegendRow(
      {required this.color,
      required this.label,
      required this.value,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (value / total * 100).round();
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: AppTextStyles.bodyMuted.copyWith(fontSize: 13.5))),
        Text('$value ($pct%)',
            style: AppTextStyles.body
                .copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
      ],
    );
  }
}
