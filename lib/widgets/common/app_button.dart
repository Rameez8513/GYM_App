import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, danger, outline }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(variant);

    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(colors.foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colors.foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label,
                  style:
                      AppTextStyles.button.copyWith(color: colors.foreground)),
            ],
          );

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.background,
          disabledBackgroundColor: colors.background.withValues(alpha: 0.6),
          elevation: 0,
          side:
              colors.border != null ? BorderSide(color: colors.border!) : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
        child: child,
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  _ButtonColors _colorsFor(AppButtonVariant variant) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonColors(
            background: AppColors.primary, foreground: Colors.white);
      case AppButtonVariant.secondary:
        return _ButtonColors(
            background: AppColors.surfaceAlt,
            foreground: AppColors.textPrimary);
      case AppButtonVariant.danger:
        return _ButtonColors(
            background: AppColors.danger, foreground: Colors.white);
      case AppButtonVariant.outline:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.textPrimary,
          border: AppColors.border,
        );
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color? border;

  _ButtonColors(
      {required this.background, required this.foreground, this.border});
}
