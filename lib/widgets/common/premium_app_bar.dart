import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  const PremiumAppBar(
      {super.key, required this.title, this.actions, this.centerTitle = false});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border:
            const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (centerTitle)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 5,
                        height: 18,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(3))),
                    Text(title,
                        style: AppTextStyles.title.copyWith(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    if (!centerTitle)
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                                width: 5,
                                height: 18,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(3))),
                            Flexible(
                                child: Text(title,
                                    style: AppTextStyles.title.copyWith(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800),
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    if (centerTitle) const Spacer(),
                    if (actions != null) ...actions!,
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
