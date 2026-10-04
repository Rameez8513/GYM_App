import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/member_model.dart';

class PaymentGridCard extends StatelessWidget {
  final MemberModel member;
  final bool isPaidTab;
  final VoidCallback onTap;

  const PaymentGridCard(
      {super.key,
      required this.member,
      required this.isPaidTab,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdue = member.isOverdue;
    final isMale = member.gender == Gender.male;

    final List<Color> topColors = isPaidTab
        ? const [Color(0xFF34D985), Color(0xFF1B8A4F)]
        : overdue
            ? const [Color(0xFFFF6B5E), Color(0xFF9A2E25)]
            : const [Color(0xFFFFB454), Color(0xFF9A6A1E)];

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.15,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: topColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight)),
                        child: Center(
                          child: Icon(isMale ? Icons.man : Icons.woman,
                              size: 40,
                              color: Colors.white.withValues(alpha: 0.95)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          isPaidTab ? 'PAID' : (overdue ? 'OVERDUE' : 'DUE'),
                          style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                              fontSize: 8.5,
                              letterSpacing: 0.4,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      member.name,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(member.feeAmount),
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: topColors.first),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isPaidTab
                          ? 'Next ${AppDateUtils.formatDate(member.nextDueDate)}'
                          : AppDateUtils.formatDate(member.nextDueDate),
                      style: AppTextStyles.label.copyWith(
                          fontSize: 9.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
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
