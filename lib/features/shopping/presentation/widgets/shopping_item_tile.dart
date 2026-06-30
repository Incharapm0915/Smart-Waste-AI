import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../presentation/screens/shopping_screen.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          gradient: AppColors.dangerGradient,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 24),
            const SizedBox(height: 3),
            Text(
              'Remove',
              style: AppTypography.caption
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onRemove(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onToggle();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: item.isChecked
                ? AppColors.surfaceVariant
                : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isChecked
                  ? AppColors.border
                  : item.isAiSuggested
                      ? AppColors.aiPurple.withValues(alpha: 0.22)
                      : AppColors.border,
            ),
            boxShadow: item.isChecked ? [] : [AppColors.cardShadow],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: item.isChecked
                          ? AppColors.primaryGradient
                          : null,
                      color: item.isChecked ? null : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.isChecked
                            ? Colors.transparent
                            : AppColors.border,
                        width: 1.5,
                      ),
                      boxShadow:
                          item.isChecked ? [AppColors.primaryShadow] : [],
                    ),
                    child: item.isChecked
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Emoji icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.isAiSuggested
                          ? AppColors.aiPurpleSurface
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(13),
                      border: item.isAiSuggested
                          ? Border.all(
                              color:
                                  AppColors.aiPurple.withValues(alpha: 0.15))
                          : null,
                    ),
                    child: Center(
                      child: Text(item.emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + reason/category + best store
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                style: AppTypography.labelLarge.copyWith(
                                  decoration: item.isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: AppColors.textTertiary,
                                  color: item.isChecked
                                      ? AppColors.textTertiary
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.isAiSuggested) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: AppColors.aiGradient,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        if (item.reason != null)
                          Text(
                            item.reason!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.aiPurple,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            item.category,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textTertiary),
                          ),
                        // Best store deal
                        if (item.bestDeal != null && !item.isChecked) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Best: ${item.bestDeal!.key} · \$${item.bestDeal!.value.toStringAsFixed(2)}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right side: quantity stepper + price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Price
                      Text(
                        item.estimatedCost > 0
                            ? '\$${item.totalCost.toStringAsFixed(2)}'
                            : '—',
                        style: AppTypography.labelMedium.copyWith(
                          color: item.isChecked
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Quantity stepper
                      if (!item.isChecked)
                        _QuantityStepper(
                          quantity: item.quantity,
                          onChanged: onQuantityChanged,
                        ),
                    ],
                  ),
                ],
              ),
              // Store price row (expanded)
              if (item.storePrices.length > 1 && !item.isChecked) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                Row(
                  children: item.storePrices.entries.map((entry) {
                    final isBest = item.bestDeal?.key == entry.key;
                    return Expanded(
                      child: _StorePriceChip(
                        store: entry.key,
                        price: entry.value,
                        isBest: isBest,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quantity Stepper ─────────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper(
      {required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(quantity - 1);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(quantity + 1);
            },
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── Store Price Chip ─────────────────────────────────────────────────────────

class _StorePriceChip extends StatelessWidget {
  final String store;
  final double price;
  final bool isBest;

  const _StorePriceChip(
      {required this.store, required this.price, required this.isBest});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isBest
            ? AppColors.primarySurface
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBest ? AppColors.primaryLight : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                store,
                style: AppTypography.caption.copyWith(
                  color: isBest
                      ? AppColors.primary
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
              if (isBest) ...[
                const SizedBox(width: 3),
                const Icon(Icons.star_rounded,
                    size: 9, color: AppColors.primary),
              ],
            ],
          ),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: AppTypography.labelSmall.copyWith(
              color: isBest
                  ? AppColors.primary
                  : AppColors.textSecondary,
              fontWeight: isBest ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
