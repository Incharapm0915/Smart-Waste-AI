import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/context_colors.dart';
import '../../features/chat/presentation/screens/chat_sheet.dart';
import '../../features/chat/presentation/screens/chef_chat_sheet.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          Positioned(
            right: 18,
            bottom: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ChefFab(onTap: () => showChefChatSheet(context)),
                const SizedBox(height: 12),
                _ChatFab(onTap: () => showChatSheet(context)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

// ─── Floating AI Chat Button ──────────────────────────────────────────────────

class _ChatFab extends StatefulWidget {
  final VoidCallback onTap;
  const _ChatFab({required this.onTap});

  @override
  State<_ChatFab> createState() => _ChatFabState();
}

class _ChatFabState extends State<_ChatFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, child) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 66 + (_pulseCtrl.value * 10),
              height: 66 + (_pulseCtrl.value * 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: 0.15 - (_pulseCtrl.value * 0.10),
                ),
              ),
            ),
            child!,
          ],
        ),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [AppColors.primaryGlowShadow],
          ),
          child: const Center(
            child: Text('🤖', style: TextStyle(fontSize: 24)),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 400.ms)
        .scale(
          begin: const Offset(0.4, 0.4),
          end: const Offset(1.0, 1.0),
          delay: 700.ms,
          duration: 500.ms,
          curve: Curves.elasticOut,
        );
  }
}

// ─── Floating Chef Button ─────────────────────────────────────────────────────

class _ChefFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ChefFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B35), Color(0xFFFF9500)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Text('👨‍🍳', style: TextStyle(fontSize: 22)),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .scale(
          begin: const Offset(0.4, 0.4),
          end: const Offset(1.0, 1.0),
          delay: 600.ms,
          duration: 500.ms,
          curve: Curves.elasticOut,
        );
  }
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  static const _destinations = [
    _NavDest('/home', Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavDest('/inventory', Icons.inventory_2_outlined,
        Icons.inventory_2_rounded, 'Inventory'),
    _NavDest('/camera', Icons.camera_alt_outlined,
        Icons.camera_alt_rounded, 'Scan'),
    _NavDest('/recipes', Icons.restaurant_menu_outlined,
        Icons.restaurant_menu_rounded, 'Recipes'),
    _NavDest('/analytics', Icons.bar_chart_outlined,
        Icons.bar_chart_rounded, 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex =
        _destinations.indexWhere((d) => d.path == location);
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(boxShadow: [AppColors.navShadow]),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A1A27).withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.94),
              border: Border(
                top: BorderSide(
                  color: context.adaptiveBorder.withValues(alpha: 0.6),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _destinations.asMap().entries.map((entry) {
                    final i = entry.key;
                    final dest = entry.value;
                    final isActive = currentIndex == i;

                    if (i == 2) {
                      return _buildCameraButton(context, dest.path, isActive);
                    }
                    return _buildNavItem(context, dest, isActive: isActive);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    _NavDest dest, {
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go(dest.path);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive ? [AppColors.primaryShadow] : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Icon(
                isActive ? dest.activeIcon : dest.icon,
                key: ValueKey(isActive),
                size: 22,
                color: isActive
                    ? Colors.white
                    : context.adaptiveTextTertiary,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: AppTypography.caption.copyWith(
                color: isActive
                    ? Colors.white
                    : context.adaptiveTextTertiary,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                fontSize: 10,
              ),
              child: Text(dest.label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraButton(
      BuildContext context, String path, bool isActive) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.go(path);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [AppColors.primaryGlowShadow],
          border: isActive
              ? Border.all(color: Colors.white, width: 2.5)
              : null,
        ),
        child: const Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _NavDest {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDest(this.path, this.icon, this.activeIcon, this.label);
}
