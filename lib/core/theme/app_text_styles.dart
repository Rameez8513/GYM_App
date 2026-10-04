import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.inter(color: AppColors.textPrimary);

  static TextStyle get displayLarge => _base.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.15,
      );

  static TextStyle get headline => _base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.2,
      );

  static TextStyle get title => _base.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get body => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyBold => body.copyWith(fontWeight: FontWeight.w700);

  static TextStyle get bodyMuted =>
      body.copyWith(color: AppColors.textSecondary);

  static TextStyle get label => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => _base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static TextStyle get statNumber => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  static TextStyle get badge => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      );
}
