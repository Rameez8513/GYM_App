import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class OptionSelectorField extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<String> options;
  final String? value;
  final void Function(String) onChanged;
  final bool allowCustom;

  const OptionSelectorField({
    super.key,
    required this.label,
    required this.icon,
    required this.options,
    required this.value,
    required this.onChanged,
    this.allowCustom = true,
  });

  @override
  State<OptionSelectorField> createState() => _OptionSelectorFieldState();
}

class _OptionSelectorFieldState extends State<OptionSelectorField> {
  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final customController = TextEditingController();
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
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
                Text('Select ${widget.label}',
                    style: AppTextStyles.title.copyWith(fontSize: 20)),
                const SizedBox(height: AppSpacing.lg),
                ...widget.options.map((option) {
                  final isSelected = option == widget.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(option),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.surfaceAlt,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(option,
                                    style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w600))),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (widget.allowCustom) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: customController,
                    style: AppTextStyles.body,
                    decoration:
                        const InputDecoration(hintText: 'Or type your own'),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty)
                        Navigator.of(context).pop(value.trim());
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (customController.text.trim().isNotEmpty)
                          Navigator.of(context)
                              .pop(customController.text.trim());
                      },
                      child: const Text('Use This'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (result != null) widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md + 2),
            decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Icon(widget.icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.value?.isNotEmpty == true
                        ? widget.value!
                        : 'Tap to select',
                    style: widget.value?.isNotEmpty == true
                        ? AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)
                        : AppTextStyles.bodyMuted.copyWith(fontSize: 13.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
