import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/plan_model.dart';

const List<List<Color>> _planPalettes = [
  [Color(0xFF5B6CFF), Color(0xFF2E3A9E)],
  [Color(0xFFFF6B5E), Color(0xFF9A2E25)],
  [Color(0xFFFFB454), Color(0xFF9A6A1E)],
  [Color(0xFF34D985), Color(0xFF1B8A4F)],
  [Color(0xFFBD5BFF), Color(0xFF6A2E9A)],
];

class PlanCard extends StatelessWidget {
  final PlanModel plan;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PlanCard(
      {super.key,
      required this.plan,
      required this.index,
      required this.onTap,
      required this.onDelete});

  String get _durationLabel {
    switch (plan.durationInDays) {
      case 30:
        return 'Monthly';
      case 90:
        return '3 Months';
      case 180:
        return '6 Months';
      case 365:
        return 'Yearly';
      default:
        return '${plan.durationInDays} days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _planPalettes[index % _planPalettes.length];

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
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
                                  colors: palette,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight))),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(PhosphorIconsBold.trash,
                              color: Colors.white, size: 15),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(PhosphorIconsBold.clockCountdown,
                                    color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(_durationLabel,
                                    style: AppTextStyles.label.copyWith(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(plan.name,
                              style: AppTextStyles.title.copyWith(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 9,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('PRICE',
                          style: AppTextStyles.label
                              .copyWith(fontSize: 10, letterSpacing: 0.6)),
                      const SizedBox(height: 2),
                      Text(CurrencyFormatter.format(plan.price),
                          style: AppTextStyles.statNumber
                              .copyWith(fontSize: 22, color: palette.first),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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
