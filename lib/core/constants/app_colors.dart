import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand
  static const Color primary = Color(0xFF2ECC71);
  static const Color primaryDark = Color(0xFF27AE60);
  static const Color primaryLight = Color(0xFFAEF5D4);
  static const Color primarySurface = Color(0xFFF0FBF4);

  // Secondary - Rich Dark Navy
  static const Color secondary = Color(0xFF0D1F2D);
  static const Color secondaryLight = Color(0xFF162B45);

  // AI Purple Accent
  static const Color aiPurple = Color(0xFF7C3AED);
  static const Color aiPurpleLight = Color(0xFFF5F0FF);
  static const Color aiPurpleSurface = Color(0xFFFAF7FF);

  // Info Blue
  static const Color infoBlue = Color(0xFF2563EB);
  static const Color infoBlueSurface = Color(0xFFEFF6FF);

  // Expiry Alerts
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color safe = Color(0xFF2ECC71);
  static const Color safeLight = Color(0xFFF0FBF4);

  // Neutral
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFF0D1F2D);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Auth hero background
  static const Color authHeroDark = Color(0xFF091520);
  static const Color authHeroMid = Color(0xFF0D2137);
  static const Color authHeroBottom = Color(0xFF122940);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2ECC71), Color(0xFF1ABC9C)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1F2D), Color(0xFF1A3352)],
  );

  static const LinearGradient deepHeroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF091520), Color(0xFF0D2137), Color(0xFF122940)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFFB347)],
  );

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFB)],
  );

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2ECC71),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
  ];

  // Shadows
  static BoxShadow get softShadow => BoxShadow(
        color: const Color(0xFF0D1F2D).withValues(alpha: 0.05),
        blurRadius: 16,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      );

  static BoxShadow get mediumShadow => BoxShadow(
        color: const Color(0xFF0D1F2D).withValues(alpha: 0.09),
        blurRadius: 28,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      );

  static BoxShadow get strongShadow => BoxShadow(
        color: const Color(0xFF0D1F2D).withValues(alpha: 0.15),
        blurRadius: 48,
        offset: const Offset(0, 16),
        spreadRadius: 0,
      );

  static BoxShadow get primaryShadow => BoxShadow(
        color: primary.withValues(alpha: 0.32),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      );

  static BoxShadow get primaryGlowShadow => BoxShadow(
        color: primary.withValues(alpha: 0.48),
        blurRadius: 32,
        offset: const Offset(0, 8),
        spreadRadius: -4,
      );

  static BoxShadow get navShadow => BoxShadow(
        color: const Color(0xFF0D1F2D).withValues(alpha: 0.10),
        blurRadius: 40,
        offset: const Offset(0, -8),
        spreadRadius: 0,
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: const Color(0xFF0D1F2D).withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      );
}
