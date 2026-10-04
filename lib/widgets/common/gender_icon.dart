import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/member_model.dart';

class GenderIcon extends StatelessWidget {
  final Gender gender;
  final double size;

  const GenderIcon({super.key, required this.gender, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final isMale = gender == Gender.male;
    final color = isMale ? AppColors.maleColor : AppColors.femaleColor;
    final bg = isMale ? AppColors.maleBg : AppColors.femaleBg;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.4),
      ),
      child: Icon(
        isMale ? Icons.man : Icons.woman,
        size: size * 0.6,
        color: color,
      ),
    );
  }
}
