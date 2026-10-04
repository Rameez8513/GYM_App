import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../models/member_model.dart';

class MemberGridCard extends StatelessWidget {
  final MemberModel member;
  final VoidCallback onTap;

  const MemberGridCard({super.key, required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isInactive = member.status == MemberStatus.inactive;
    final isMale = member.gender == Gender.male;

    final List<Color> topColors = isInactive
        ? const [Color(0xFF494C5B), Color(0xFF2A2C37)]
        : isMale
            ? const [Color(0xFF5B8DEF), Color(0xFF2E4F8C)]
            : const [Color(0xFFEF5DA8), Color(0xFF8C2E63)];

    final statusColor =
        member.currentMonthPaid ? AppColors.success : AppColors.danger;

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
            border: Border.all(
              color: isInactive
                  ? AppColors.danger.withValues(alpha: 0.35)
                  : AppColors.border,
              width: isInactive ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: topColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                        ),
                        child: Center(
                          child: Icon(
                            isMale ? Icons.man : Icons.woman,
                            size: 44,
                            color: Colors.white
                                .withValues(alpha: isInactive ? 0.5 : 0.95),
                          ),
                        ),
                      ),
                    ),
                    if (isInactive)
                      Positioned(
                        top: 7,
                        left: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      AppColors.danger.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Text(
                            'INACTIVE',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.label.copyWith(
                                color: Colors.white,
                                fontSize: 9.5,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                  color: statusColor.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Text(
                            member.currentMonthPaid ? 'PAID' : 'UNPAID',
                            style: AppTextStyles.label.copyWith(
                                color: Colors.white,
                                fontSize: 9,
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 10,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        member.name,
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.planName,
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.calendar,
                            size: 11,
                            color: member.isOverdue
                                ? AppColors.danger
                                : AppColors.textDisabled,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              AppDateUtils.formatDate(member.nextDueDate),
                              style: AppTextStyles.label.copyWith(
                                fontSize: 10.5,
                                color: member.isOverdue
                                    ? AppColors.danger
                                    : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
