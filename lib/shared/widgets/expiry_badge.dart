import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class ExpiryBadge extends StatelessWidget {
  final int daysUntilExpiry;

  const ExpiryBadge({super.key, required this.daysUntilExpiry});

  Color get _color {
    if (daysUntilExpiry < 0) return AppColors.danger;
    if (daysUntilExpiry <= 2) return AppColors.danger;
    if (daysUntilExpiry <= 5) return AppColors.warning;
    return AppColors.safe;
  }

  LinearGradient get _gradient {
    if (daysUntilExpiry < 0) return AppColors.dangerGradient;
    if (daysUntilExpiry <= 2) return AppColors.dangerGradient;
    if (daysUntilExpiry <= 5) return AppColors.warningGradient;
    return AppColors.primaryGradient;
  }

  String get _label {
    if (daysUntilExpiry < 0) return 'Expired';
    if (daysUntilExpiry == 0) return 'Today!';
    if (daysUntilExpiry == 1) return '1 day';
    return '${daysUntilExpiry}d';
  }

  bool get _isUrgent => daysUntilExpiry <= 2;

  @override
  Widget build(BuildContext context) {
    if (_isUrgent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _color.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          _label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration:
                BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            _label,
            style: AppTypography.labelSmall.copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
