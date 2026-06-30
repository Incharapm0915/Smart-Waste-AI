import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/models/inventory_item_model.dart';
import '../../../../shared/widgets/expiry_badge.dart';

class ExpiryAlertCard extends StatelessWidget {
  final InventoryItemModel item;

  const ExpiryAlertCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final days = AppDateUtils.daysUntilExpiry(item.expiryDate);
    final color = AppDateUtils.expiryColor(item.expiryDate);
    final bgColor = AppDateUtils.expiryBgColor(item.expiryDate);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [AppColors.cardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withValues(alpha: 0.4)],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: color.withValues(alpha: 0.15)),
                      ),
                      child: Center(
                        child: Text(item.emoji,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTypography.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
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
                            ],
                          ),
                        ],
                      ),
                    ),
                    ExpiryBadge(daysUntilExpiry: days),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
