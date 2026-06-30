import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/providers/camera_provider.dart';

class DetectedItemCard extends StatelessWidget {
  final DetectedItem item;
  final VoidCallback onToggle;
  final ValueChanged<DateTime> onExpiryChanged;

  const DetectedItemCard({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onExpiryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final expiryColor = AppDateUtils.expiryColor(item.expiryDate);
    final expiryBg = AppDateUtils.expiryBgColor(item.expiryDate);
    final confidence = (item.confidence * 100).toInt();

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isSelected ? AppColors.surface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isSelected
                ? AppColors.primary.withValues(alpha: 0.28)
                : AppColors.border,
            width: item.isSelected ? 1.5 : 1.0,
          ),
          boxShadow: item.isSelected ? [AppColors.cardShadow] : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: item.isSelected ? AppColors.primaryGradient : null,
                color: item.isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.isSelected
                      ? Colors.transparent
                      : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: item.isSelected ? [AppColors.primaryShadow] : [],
              ),
              child: item.isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: expiryBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: expiryColor.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTypography.labelLarge),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.category,
                            style: AppTypography.caption),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: confidence >= 85
                              ? AppColors.primarySurface
                              : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$confidence%',
                          style: AppTypography.caption.copyWith(
                            color: confidence >= 85
                                ? AppColors.primary
                                : AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _pickExpiry(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: expiryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: expiryColor.withValues(alpha: 0.20)),
                    ),
                    child: Text(
                      AppDateUtils.formatShort(item.expiryDate),
                      style: AppTypography.labelSmall.copyWith(
                        color: expiryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.edit_outlined,
                          size: 10, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        'edit',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExpiry(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: item.expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onExpiryChanged(picked);
  }
}
