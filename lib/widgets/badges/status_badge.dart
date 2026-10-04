import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum BadgeStatus { paid, unpaid, overdue, active, inactive, expiringSoon }

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        config.label,
        style: AppTextStyles.label
            .copyWith(color: config.foreground, fontSize: 11),
      ),
    );
  }

  _BadgeConfig _configFor(BadgeStatus status) {
    switch (status) {
      case BadgeStatus.paid:
        return _BadgeConfig('Paid', AppColors.successBg, AppColors.success);
      case BadgeStatus.unpaid:
        return _BadgeConfig('Unpaid', AppColors.dangerBg, AppColors.danger);
      case BadgeStatus.overdue:
        return _BadgeConfig('Overdue', AppColors.dangerBg, AppColors.danger);
      case BadgeStatus.active:
        return _BadgeConfig('Active', AppColors.successBg, AppColors.success);
      case BadgeStatus.inactive:
        return _BadgeConfig(
            'Inactive', AppColors.surfaceAlt, AppColors.textSecondary);
      case BadgeStatus.expiringSoon:
        return _BadgeConfig(
            'Expiring Soon', AppColors.warningBg, AppColors.warning);
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color background;
  final Color foreground;

  _BadgeConfig(this.label, this.background, this.foreground);
}
