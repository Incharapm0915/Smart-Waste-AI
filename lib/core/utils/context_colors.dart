import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

extension ColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get adaptiveBackground =>
      isDark ? const Color(0xFF0F0F17) : AppColors.background;

  Color get adaptiveSurface =>
      isDark ? const Color(0xFF1A1A27) : AppColors.surface;

  Color get adaptiveSurfaceVariant =>
      isDark ? const Color(0xFF232334) : AppColors.surfaceVariant;

  Color get adaptiveBorder =>
      isDark ? const Color(0xFF2D2D42) : AppColors.border;

  Color get adaptiveTextPrimary =>
      isDark ? const Color(0xFFF1F5F9) : AppColors.textPrimary;

  Color get adaptiveTextSecondary =>
      isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

  Color get adaptiveTextTertiary =>
      isDark ? const Color(0xFF64748B) : AppColors.textTertiary;

  Color get adaptiveNavBar =>
      isDark ? const Color(0xFF1A1A27) : Colors.white;

  Color get adaptiveNavBarBorder =>
      isDark ? const Color(0xFF2D2D42) : AppColors.border;

  Color get adaptiveCardBg =>
      isDark ? const Color(0xFF1A1A27) : AppColors.surface;

  Color get adaptiveSheetBg =>
      isDark ? const Color(0xFF14141F) : AppColors.background;
}
