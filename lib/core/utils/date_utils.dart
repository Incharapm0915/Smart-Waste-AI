import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppDateUtils {
  static int daysUntilExpiry(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  static String expiryLabel(DateTime expiryDate) {
    final days = daysUntilExpiry(expiryDate);
    if (days < 0) return 'Expired ${-days}d ago';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    if (days <= 30) return 'Expires in ${(days / 7).floor()} weeks';
    return 'Expires in ${(days / 30).floor()} months';
  }

  static Color expiryColor(DateTime expiryDate) {
    final days = daysUntilExpiry(expiryDate);
    if (days <= 2) return AppColors.danger;
    if (days <= 5) return AppColors.warning;
    return AppColors.safe;
  }

  static Color expiryBgColor(DateTime expiryDate) {
    final days = daysUntilExpiry(expiryDate);
    if (days <= 2) return AppColors.dangerLight;
    if (days <= 5) return AppColors.warningLight;
    return AppColors.safeLight;
  }

  static ExpiryStatus expiryStatus(DateTime expiryDate) {
    final days = daysUntilExpiry(expiryDate);
    if (days < 0) return ExpiryStatus.expired;
    if (days <= 2) return ExpiryStatus.critical;
    if (days <= 5) return ExpiryStatus.warning;
    return ExpiryStatus.safe;
  }

  static String formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String formatShort(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatShort(date);
  }
}

enum ExpiryStatus { safe, warning, critical, expired }
