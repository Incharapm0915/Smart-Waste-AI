import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/context_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/household_provider.dart';
import '../../../../shared/models/inventory_item_model.dart';
import '../../../../features/inventory/domain/providers/inventory_provider.dart';
import '../../../../features/auth/domain/providers/auth_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../widgets/stats_card.dart';
import '../widgets/expiry_alert_card.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/sustainability_ring.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final inventoryAsync = ref.watch(inventoryProvider);
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, ref, user, greeting),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildSustainabilityCard(ref)
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                  const SizedBox(height: 16),
                  _buildStatsRow(inventoryAsync)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 350.ms),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Quick Actions', null),
                  const SizedBox(height: 14),
                  const QuickActionGrid()
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 350.ms),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Expiry Alerts', 'View all',
                      onTap: () => context.go('/inventory')),
                  const SizedBox(height: 14),
                  _buildExpiryAlerts(inventoryAsync, context)
                      .animate()
                      .fadeIn(delay: 380.ms, duration: 350.ms),
                  const SizedBox(height: 28),
                  _buildRecentActivity()
                      .animate()
                      .fadeIn(delay: 460.ms, duration: 350.ms),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, WidgetRef ref, User? user, String greeting) {
    return SliverAppBar(
      expandedHeight: 136,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(greeting,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            )),
                        const SizedBox(width: 6),
                        _buildDateChip(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.displayName?.split(' ').first ?? 'there',
                      style: AppTypography.displaySmall,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.06, curve: Curves.easeOutCubic),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildNotificationButton(context, ref),
                  const SizedBox(width: 10),
                  _buildAvatar(context, ref, user),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Text(
        '${now.day} ${months[now.month - 1]}',
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showNotificationsSheet(context, ref),
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [AppColors.softShadow],
            ),
            child: const Icon(Icons.notifications_outlined,
                size: 20, color: AppColors.textPrimary),
          ),
          Positioned(
            right: 11,
            top: 11,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: AppColors.dangerGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, WidgetRef ref, User? user) {
    return GestureDetector(
      onTap: () => _showProfileSheet(context, ref, user),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [AppColors.primaryShadow],
        ),
        child: Center(
          child: Text(
            (user?.displayName?.isNotEmpty == true)
                ? user!.displayName![0].toUpperCase()
                : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSustainabilityCard(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [AppColors.strongShadow],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -28,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 55,
            bottom: -32,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.eco_rounded,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            'Sustainability Score',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 847),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => Text(
                        val.toInt().toString(),
                        style: AppTypography.displayLarge.copyWith(
                          color: Colors.white,
                          fontSize: 54,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    Text(
                      'points',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.40),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            '+12% this week',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SustainabilityRing(score: 0.72),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AsyncValue<List<InventoryItemModel>> inventoryAsync) {
    return inventoryAsync.when(
      data: (items) {
        final total = items.length;
        final expiringSoon = items.where((i) {
          final d = AppDateUtils.daysUntilExpiry(i.expiryDate);
          return d >= 0 && d <= 5;
        }).length;
        final expired = items.where((i) {
          return AppDateUtils.daysUntilExpiry(i.expiryDate) < 0;
        }).length;
        return Row(
          children: [
            Expanded(
              child: StatsCard(
                label: 'Total Items',
                value: total.toString(),
                icon: Icons.inventory_2_outlined,
                color: AppColors.primary,
                bgColor: AppColors.primarySurface,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatsCard(
                label: 'Expiring',
                value: expiringSoon.toString(),
                icon: Icons.schedule_outlined,
                color: AppColors.warning,
                bgColor: AppColors.warningLight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatsCard(
                label: 'Expired',
                value: expired.toString(),
                icon: Icons.warning_amber_rounded,
                color: AppColors.danger,
                bgColor: AppColors.dangerLight,
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: List.generate(
          3,
          (_) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _buildShimmer(height: 96),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildShimmer({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: Colors.white.withValues(alpha: 0.65),
        );
  }

  Widget _buildSectionHeader(String title, String? action,
      {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(title, style: AppTypography.headlineSmall),
          ],
        ),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Text(
                action,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpiryAlerts(
    AsyncValue<List<InventoryItemModel>> inventoryAsync,
    BuildContext context,
  ) {
    return inventoryAsync.when(
      data: (items) {
        final alerts = items.where((i) {
          final d = AppDateUtils.daysUntilExpiry(i.expiryDate);
          return d >= 0 && d <= 5;
        }).toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        if (alerts.isEmpty) return _buildEmptyAlerts();
        return Column(
          children: alerts.take(3).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpiryAlertCard(item: item),
            );
          }).toList(),
        );
      },
      loading: () => Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildShimmer(height: 76),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyAlerts() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primarySurface,
            AppColors.primaryLight.withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'All items are fresh!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {
        'icon': Icons.add_circle_outline_rounded,
        'text': 'Added 3 items from scan',
        'time': '2h ago',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.restaurant_menu_outlined,
        'text': 'Generated pasta recipe',
        'time': '5h ago',
        'color': AppColors.warning,
      },
      {
        'icon': Icons.shopping_cart_outlined,
        'text': 'Shopping list updated',
        'time': '1d ago',
        'color': AppColors.aiPurple,
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recent Activity', null),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [AppColors.cardShadow],
          ),
          child: Column(
            children: activities.asMap().entries.map((entry) {
              final i = entry.key;
              final act = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (act['color'] as Color)
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            act['icon'] as IconData,
                            size: 19,
                            color: act['color'] as Color,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            act['text'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(act['time'] as String,
                              style: AppTypography.caption),
                        ),
                      ],
                    ),
                  ),
                  if (i < activities.length - 1)
                    Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                      color: AppColors.border.withValues(alpha: 0.6),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.read(inventoryProvider);
    final recipeNotif = ref.read(latestRecipeNotificationProvider);
    final expiring = inventoryAsync.value?.where((i) {
          final d = AppDateUtils.daysUntilExpiry(i.expiryDate);
          return d >= 0 && d <= 5;
        }).toList() ??
        [];
    final totalCount = expiring.length + (recipeNotif != null ? 1 : 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (notifCtx) => Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(notifCtx).size.height * 0.7),
        decoration: BoxDecoration(
          color: notifCtx.adaptiveSheetBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [AppColors.strongShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Text('Notifications', style: AppTypography.headlineMedium),
                  const Spacer(),
                  if (totalCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: expiring.isNotEmpty
                            ? AppColors.dangerGradient
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        expiring.isNotEmpty
                            ? '${expiring.length} urgent'
                            : '$totalCount new',
                        style: AppTypography.labelSmall
                            .copyWith(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
            Flexible(
              child: totalCount == 0
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.primarySurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 32,
                                color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text("You're all caught up!",
                              style: AppTypography.headlineSmall),
                          const SizedBox(height: 6),
                          Text('No notifications right now.',
                              style: AppTypography.bodyMedium),
                        ],
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      children: [
                        // Recipe notification card
                        if (recipeNotif != null) ...[
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              ref.read(pendingNotificationRecipeProvider.notifier).state = recipeNotif;
                              context.go('/recipes');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primarySurface,
                                    AppColors.primaryLight.withValues(alpha: 0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryLight),
                                boxShadow: [AppColors.softShadow],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Center(
                                      child: Text(
                                        recipeNotif.emoji ?? '🍽️',
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('Recipe of the Day',
                                                style: AppTypography.labelMedium
                                                    .copyWith(color: AppColors.primary)),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text('NEW',
                                                  style: AppTypography.caption.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${recipeNotif.name} · ${recipeNotif.cookTimeMinutes} min',
                                          style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 13, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                          if (expiring.isNotEmpty) const SizedBox(height: 10),
                        ],
                        // Expiry alert cards
                        ...expiring.map((item) {
                          final days = AppDateUtils.daysUntilExpiry(item.expiryDate);
                          final color = AppDateUtils.expiryColor(item.expiryDate);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.18)),
                                boxShadow: [AppColors.softShadow],
                              ),
                              child: Row(
                                children: [
                                  Text(item.emoji,
                                      style: const TextStyle(fontSize: 26)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name,
                                            style: AppTypography.labelLarge),
                                        Text(
                                          days == 0
                                              ? 'Expires today!'
                                              : days == 1
                                                  ? 'Expires tomorrow'
                                                  : 'Expires in $days days',
                                          style: AppTypography.bodySmall
                                              .copyWith(color: color),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 13, color: AppColors.textTertiary),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(
      BuildContext context, WidgetRef ref, User? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Consumer(
        builder: (_, cRef, __) {
          final household = cRef.watch(householdProvider);
          final isDark = cRef.watch(themeModeProvider) == ThemeMode.dark;
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sheetCtx.adaptiveSheetBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [AppColors.strongShadow],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetCtx.adaptiveBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [AppColors.primaryGlowShadow],
                        ),
                        child: Center(
                          child: Text(
                            (user?.displayName?.isNotEmpty == true)
                                ? user!.displayName![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(user?.displayName ?? 'User',
                          style: AppTypography.headlineMedium.copyWith(
                              color: sheetCtx.adaptiveTextPrimary)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '',
                          style: AppTypography.bodyMedium.copyWith(
                              color: sheetCtx.adaptiveTextSecondary)),

                      // ── Household chip ─────────────────────────────
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showHouseholdSheet(context, ref);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(household.active.emoji,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                household.active.name,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 14, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Divider(
                          color: sheetCtx.adaptiveBorder.withValues(alpha: 0.8)),
                      const SizedBox(height: 6),
                      _buildProfileAction(
                        context: sheetCtx,
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pop(context);
                          _showEditProfileSheet(context, user);
                        },
                      ),
                      _buildProfileAction(
                        context: sheetCtx,
                        icon: Icons.notifications_outlined,
                        label: 'Notification Settings',
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.pop(context);
                          _showNotificationSettingsSheet(context, ref);
                        },
                      ),
                      // ── Dark mode toggle ───────────────────────────
                      ListTile(
                        onTap: () => cRef
                            .read(themeModeProvider.notifier)
                            .toggle(),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.dark_mode_outlined,
                              size: 19, color: Color(0xFF7C3AED)),
                        ),
                        title: Text('Dark Mode',
                            style: AppTypography.bodyMedium
                                .copyWith(color: sheetCtx.adaptiveTextPrimary)),
                        trailing: Switch(
                          value: isDark,
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primaryLight,
                          onChanged: (_) => cRef
                              .read(themeModeProvider.notifier)
                              .toggle(),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      _buildProfileAction(
                        context: sheetCtx,
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        color: AppColors.infoBlue,
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpSheet(context);
                        },
                      ),
                      const SizedBox(height: 6),
                      Divider(
                          color: sheetCtx.adaptiveBorder.withValues(alpha: 0.8)),
                      const SizedBox(height: 6),
                      _buildProfileAction(
                        context: sheetCtx,
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        color: AppColors.danger,
                        onTap: () async {
                          Navigator.pop(context);
                          await ref
                              .read(authProvider.notifier)
                              .signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHouseholdSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Consumer(
        builder: (_, cRef, __) {
          final state = cRef.watch(householdProvider);
          return Container(
            margin: const EdgeInsets.all(12),
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75),
            decoration: BoxDecoration(
              color: sheetCtx.adaptiveSheetBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [AppColors.strongShadow],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetCtx.adaptiveBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.home_rounded,
                            size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Text('Household Profiles',
                          style: AppTypography.headlineMedium.copyWith(
                              color: sheetCtx.adaptiveTextPrimary)),
                    ],
                  ),
                ),
                Divider(color: sheetCtx.adaptiveBorder),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    children: [
                      ...state.households.map((h) {
                        final isActive = h.id == state.activeId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              cRef
                                  .read(householdProvider.notifier)
                                  .switchTo(h.id);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? AppColors.primaryGradient
                                    : null,
                                color: isActive
                                    ? null
                                    : sheetCtx.adaptiveSurface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.transparent
                                      : sheetCtx.adaptiveBorder,
                                ),
                                boxShadow: isActive
                                    ? [AppColors.primaryShadow]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Text(h.emoji,
                                      style:
                                          const TextStyle(fontSize: 26)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      h.name,
                                      style:
                                          AppTypography.labelLarge.copyWith(
                                        color: isActive
                                            ? Colors.white
                                            : sheetCtx.adaptiveTextPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isActive)
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 20)
                                  else if (state.households.length > 1)
                                    GestureDetector(
                                      onTap: () => cRef
                                          .read(householdProvider.notifier)
                                          .removeHousehold(h.id),
                                      child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: sheetCtx.adaptiveTextTertiary),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () =>
                            _showAddHouseholdSheet(sheetCtx, ref),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.22)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('Add Household',
                                  style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddHouseholdSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    String selectedEmoji = '🏠';
    final emojis = ['🏠', '🏡', '🏢', '🏘️', '🌿', '⭐', '🔥', '💎'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sheetCtx.adaptiveSheetBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [AppColors.strongShadow],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetCtx.adaptiveBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Household',
                          style: AppTypography.headlineMedium.copyWith(
                              color: sheetCtx.adaptiveTextPrimary)),
                      const SizedBox(height: 20),
                      // Emoji picker
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: emojis.map((e) {
                            final sel = e == selectedEmoji;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedEmoji = e),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 8),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary
                                          .withValues(alpha: 0.15)
                                      : sheetCtx.adaptiveSurfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.primary
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                    child: Text(e,
                                        style:
                                            const TextStyle(fontSize: 20))),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameCtrl,
                        autofocus: true,
                        style: TextStyle(color: sheetCtx.adaptiveTextPrimary),
                        decoration: InputDecoration(
                          labelText: 'Household Name',
                          hintText: 'e.g. Beach House',
                          prefixIcon:
                              const Icon(Icons.home_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            await ref
                                .read(householdProvider.notifier)
                                .addHousehold(name, selectedEmoji);
                            if (sheetCtx.mounted) {
                              Navigator.pop(sheetCtx);
                            }
                          },
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [AppColors.primaryShadow],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Create Household',
                              style: AppTypography.labelMedium
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, User? user) {
    final controller = TextEditingController(text: user?.displayName ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ctx.adaptiveSheetBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [AppColors.strongShadow],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 44, height: 4,
                    decoration: BoxDecoration(
                      color: ctx.adaptiveBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit Profile',
                          style: AppTypography.headlineMedium.copyWith(
                              color: ctx.adaptiveTextPrimary)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'Enter your name',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () async {
                            final name = controller.text.trim();
                            if (name.isEmpty) return;
                            await user?.updateDisplayName(name);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [AppColors.primaryShadow],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Save Changes',
                              style: AppTypography.labelMedium.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (ctx, cRef, _) {
          final enabled = cRef.watch(dailyNotificationsEnabledProvider);
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ctx.adaptiveSheetBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [AppColors.strongShadow],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 44, height: 4,
                    decoration: BoxDecoration(
                      color: ctx.adaptiveBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            size: 20, color: AppColors.warning),
                      ),
                      const SizedBox(width: 14),
                      Text('Notification Settings', style: AppTypography.headlineMedium),
                    ],
                  ),
                ),
                Divider(color: AppColors.border.withValues(alpha: 0.6)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.restaurant_menu_rounded,
                                  size: 22, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Daily Recipe', style: AppTypography.labelLarge),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Get a new recipe suggestion every day',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: enabled,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) async {
                                await cRef.read(dailyNotificationsEnabledProvider.notifier).setValue(val);
                                if (val) {
                                  await NotificationService.scheduleDailyNotification();
                                } else {
                                  await NotificationService.cancelDailyNotification();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      if (enabled) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            cRef.read(latestRecipeNotificationProvider.notifier).state =
                                NotificationService.todayRecipe;
                            Navigator.pop(ctx);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (kIsWeb) {
                                _showWebNotificationBanner(context, ref);
                              } else {
                                NotificationService.showDemoNotification();
                              }
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primaryLight),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Send Test Notification',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showWebNotificationBanner(BuildContext context, WidgetRef ref) {
    final recipe = NotificationService.todayRecipe;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: GestureDetector(
          onTap: () {
            messenger.hideCurrentSnackBar();
            ref.read(pendingNotificationRecipeProvider.notifier).state = recipe;
            context.go('/recipes');
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: [AppColors.strongShadow],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      recipe.emoji ?? '🍽️',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🍽️ Recipe of the Day',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${recipe.name} · Tap to view',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    final faqs = [
      ('How do I add items to my inventory?', 'Use the Camera tab to scan your fridge or receipt, or manually add items from the Inventory tab.'),
      ('How does AI recipe generation work?', 'Our AI analyses your expiring items and suggests recipes to help reduce food waste.'),
      ('Can I edit items after adding them?', 'Yes — tap any item in your Inventory to edit its name, quantity, or expiry date.'),
      ('How do notifications work?', 'Enable Daily Recipe in Notification Settings to receive a recipe suggestion each day.'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.88,
        minChildSize: 0.4,
        builder: (ctx, scrollController) => Container(
          margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
          decoration: BoxDecoration(
            color: ctx.adaptiveSheetBg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [AppColors.strongShadow],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 44, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.infoBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.help_outline_rounded,
                          size: 20, color: AppColors.infoBlue),
                    ),
                    const SizedBox(width: 14),
                    Text('Help & Support', style: AppTypography.headlineMedium),
                  ],
                ),
              ),
              Divider(color: AppColors.border.withValues(alpha: 0.6)),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: faqs.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i == faqs.length) {
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [AppColors.primaryShadow],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mail_outline_rounded,
                                color: Colors.white, size: 22),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Still need help?',
                                    style: AppTypography.labelLarge.copyWith(
                                        color: Colors.white)),
                                Text('support@smartwasteai.app',
                                    style: AppTypography.bodySmall.copyWith(
                                        color: Colors.white.withValues(alpha: 0.8))),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    final faq = faqs[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [AppColors.softShadow],
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 4),
                        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                        title: Text(faq.$1,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                            )),
                        iconColor: AppColors.primary,
                        collapsedIconColor: AppColors.textTertiary,
                        shape: const Border.fromBorderSide(BorderSide.none),
                        collapsedShape: const Border.fromBorderSide(BorderSide.none),
                        children: [
                          Text(faq.$2,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              )),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 19, color: color),
      ),
      title: Text(label,
          style: AppTypography.bodyMedium
              .copyWith(color: context.adaptiveTextPrimary)),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 13, color: context.adaptiveTextTertiary),
      contentPadding: EdgeInsets.zero,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}
