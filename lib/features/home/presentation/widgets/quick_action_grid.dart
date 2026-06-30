import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/pressable_card.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  static const _actions = [
    _QuickAction(
      label: 'Scan Food',
      icon: Icons.camera_alt_rounded,
      route: '/camera',
      gradient: AppColors.primaryGradient,
      isAccent: true,
    ),
    _QuickAction(
      label: 'Inventory',
      icon: Icons.inventory_2_rounded,
      route: '/inventory',
      iconColor: Color(0xFF2563EB),
      bgColor: Color(0xFFEFF6FF),
    ),
    _QuickAction(
      label: 'Recipes',
      icon: Icons.restaurant_menu_rounded,
      route: '/recipes',
      iconColor: Color(0xFFF59E0B),
      bgColor: Color(0xFFFFFBEB),
    ),
    _QuickAction(
      label: 'Shopping',
      icon: Icons.shopping_cart_rounded,
      route: '/shopping',
      iconColor: Color(0xFF7C3AED),
      bgColor: Color(0xFFF5F0FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, i) {
        final action = _actions[i];
        return PressableCard(
          pressedScale: 0.93,
          onTap: () => context.go(action.route),
          child: Container(
            decoration: BoxDecoration(
              gradient: action.isAccent ? action.gradient : null,
              color: action.isAccent ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: action.isAccent
                  ? null
                  : Border.all(color: AppColors.border),
              boxShadow: action.isAccent
                  ? [AppColors.primaryGlowShadow]
                  : [AppColors.softShadow],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: action.isAccent
                        ? Colors.white.withValues(alpha: 0.22)
                        : action.bgColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    action.icon,
                    size: 22,
                    color: action.isAccent ? Colors.white : action.iconColor,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  action.label,
                  style: AppTypography.caption.copyWith(
                    color: action.isAccent
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  final LinearGradient? gradient;
  final Color? iconColor;
  final Color? bgColor;
  final bool isAccent;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
    this.gradient,
    this.iconColor,
    this.bgColor,
    this.isAccent = false,
  });
}
