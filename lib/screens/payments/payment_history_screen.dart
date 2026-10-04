import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/common/app_error_view.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../widgets/common/premium_app_bar.dart';
import '../../widgets/empty_states/empty_state_view.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return _weekday(d.weekday);
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _weekday(int w) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return names[w - 1];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

    Widget body;
    if (provider.error != null) {
      body = AppErrorView(message: provider.error!, onRetry: provider.retry);
    } else if (provider.isLoading) {
      body = const AppLoadingIndicator();
    } else if (provider.allPayments.isEmpty) {
      body = const EmptyStateView(
        icon: PhosphorIconsRegular.receipt,
        title: 'No activity recorded',
        subtitle:
            'Payments and status changes will appear here, grouped by day',
        accent: AppColors.primary,
      );
    } else {
      final grouped = <String, List<PaymentModel>>{};
      for (final p in provider.allPayments) {
        grouped.putIfAbsent(_dayLabel(p.paidDate), () => []).add(p);
      }
      final sections = grouped.entries.toList();
      final paidEvents = provider.allPayments.where((p) => p.isPaid).toList();
      final unpaidEvents =
          provider.allPayments.where((p) => !p.isPaid).toList();
      final totalReceived =
          paidEvents.fold<double>(0, (sum, p) => sum + p.amount);

      body = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.surface, AppColors.surfaceAlt]),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm)),
                      child: const Icon(PhosphorIconsFill.receipt,
                          color: AppColors.success, size: 21),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Total ${CurrencyFormatter.format(totalReceived)}',
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.w700)),
                          Text(
                              '${paidEvents.length} paid · ${unpaidEvents.length} marked unpaid',
                              style: AppTextStyles.bodyMuted
                                  .copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          for (final section in sections) ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _DateHeaderDelegate(
                label: section.key,
                count: section.value.length,
                total: section.value
                    .where((p) => p.isPaid)
                    .fold<double>(0, (sum, p) => sum + p.amount),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              sliver: SliverList.separated(
                itemCount: section.value.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) =>
                    _PaymentHistoryTile(payment: section.value[index]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PremiumAppBar(title: 'Payment History'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: isWideScreen(context) ? 680 : double.infinity),
            child: body,
          ),
        ),
      ),
    );
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;
  final int count;
  final double total;

  _DateHeaderDelegate(
      {required this.label, required this.count, required this.total});

  @override
  double get minExtent => 40;

  @override
  double get maxExtent => 40;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w800, fontSize: 14.5)),
          const SizedBox(width: 8),
          Text('· $count',
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 13)),
          const Spacer(),
          Text(CurrencyFormatter.format(total),
              style: AppTextStyles.body.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) {
    return oldDelegate.label != label ||
        oldDelegate.count != count ||
        oldDelegate.total != total;
  }
}

class _PaymentHistoryTile extends StatelessWidget {
  final PaymentModel payment;

  const _PaymentHistoryTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.isPaid;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: isPaid ? AppColors.successBg : AppColors.dangerBg,
                shape: BoxShape.circle),
            child: Icon(
                isPaid
                    ? PhosphorIconsFill.checkCircle
                    : PhosphorIconsFill.xCircle,
                size: 20,
                color: isPaid ? AppColors.success : AppColors.danger),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.memberName,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                if (isPaid)
                  Row(
                    children: [
                      Icon(
                          payment.method == PaymentMethod.cash
                              ? PhosphorIconsBold.money
                              : PhosphorIconsBold.deviceMobile,
                          size: 12,
                          color: AppColors.textDisabled),
                      const SizedBox(width: 4),
                      Text(
                          payment.method == PaymentMethod.cash
                              ? 'Cash'
                              : 'Online',
                          style: AppTextStyles.label.copyWith(fontSize: 12)),
                    ],
                  )
                else
                  Text('Marked Unpaid',
                      style: AppTextStyles.label
                          .copyWith(fontSize: 12, color: AppColors.danger)),
              ],
            ),
          ),
          Text(
            isPaid ? CurrencyFormatter.format(payment.amount) : '—',
            style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w800,
                color: isPaid ? AppColors.success : AppColors.textDisabled,
                fontSize: 16),
          ),
        ],
      ),
    );
  }
}
