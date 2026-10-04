import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/plan_model.dart';

class PlanSelectorField extends StatelessWidget {
  final List<PlanModel> plans;
  final String? selectedPlanId;
  final void Function(PlanModel) onChanged;

  const PlanSelectorField(
      {super.key,
      required this.plans,
      required this.selectedPlanId,
      required this.onChanged});

  PlanModel? get _selectedPlan {
    if (selectedPlanId == null) return null;
    try {
      return plans.firstWhere((p) => p.id == selectedPlanId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openSelector(BuildContext context) async {
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No plans available. Create a plan first from the Plans tab.')),
      );
      return;
    }
    final result = await showModalBottomSheet<PlanModel>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4))),
              ),
              Text('Select Membership Plan',
                  style: AppTextStyles.title.copyWith(fontSize: 20)),
              const SizedBox(height: AppSpacing.lg),
              ...plans.map((plan) {
                final isSelected = plan.id == selectedPlanId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Material(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      onTap: () => Navigator.of(context).pop(plan),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(plan.name,
                                      style: AppTextStyles.body.copyWith(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${CurrencyFormatter.format(plan.price)} · ${plan.durationInDays} days',
                                      style: AppTextStyles.bodyMuted),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(PhosphorIconsFill.checkCircle,
                                  color: AppColors.primary, size: 26)
                            else
                              Icon(PhosphorIconsRegular.circle,
                                  color: AppColors.textDisabled, size: 26),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final plan = _selectedPlan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Membership Plan', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () => _openSelector(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md + 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                  color: plan != null
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.tag,
                    size: 20,
                    color: plan != null
                        ? AppColors.primary
                        : AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    plan != null
                        ? '${plan.name} — ${CurrencyFormatter.format(plan.price)}'
                        : 'Tap to select a plan',
                    style: plan != null
                        ? AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)
                        : AppTextStyles.bodyMuted,
                  ),
                ),
                const Icon(PhosphorIconsRegular.caretDown,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
