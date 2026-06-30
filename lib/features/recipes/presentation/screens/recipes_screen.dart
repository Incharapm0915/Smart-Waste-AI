import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/providers/recipes_provider.dart';
import '../../data/models/recipe_model.dart';
import '../widgets/recipe_card.dart';
import '../widgets/recipe_detail_sheet.dart';
import '../../../../core/providers/notification_provider.dart';

final _recipeFilterProvider = StateProvider<String>((ref) => 'All');

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recipesProvider.notifier).generateRecipes();
      final pending = ref.read(pendingNotificationRecipeProvider);
      if (pending != null) {
        ref.read(pendingNotificationRecipeProvider.notifier).state = null;
        _openDetail(context, pending);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider);
    final filter = ref.watch(_recipeFilterProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeroBanner()
                      .animate()
                      .fadeIn(delay: 80.ms)
                      .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                  const SizedBox(height: 20),
                  _buildFilterRow(ref, filter),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            recipesAsync.when(
              data: (recipes) {
                final filtered = filter == 'All'
                    ? recipes
                    : recipes.where((r) {
                        if (filter == 'Quick') return r.cookTimeMinutes <= 15;
                        if (filter == 'Easy') return r.difficulty == 'Easy';
                        if (filter == 'Urgent') return r.expiryUrgency >= 2;
                        return true;
                      }).toList();

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(child: _buildEmptyState());
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RecipeCard(
                          recipe: filtered[i],
                          onTap: () => _openDetail(context, filtered[i]),
                        )
                            .animate()
                            .fadeIn(delay: (i * 80).ms)
                            .slideY(
                                begin: 0.06, curve: Curves.easeOutCubic),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildSkeletonCard(),
                    ),
                    childCount: 3,
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.dangerLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.danger,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Failed to load recipes',
                            style: AppTypography.headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          'Check your connection and try again',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => ref
                              .read(recipesProvider.notifier)
                              .generateRecipes(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [AppColors.primaryShadow],
                            ),
                            child: Text(
                              'Retry',
                              style: AppTypography.labelMedium
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: AppColors.border,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text('AI Recipes', style: AppTypography.headlineMedium),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () =>
                ref.read(recipesProvider.notifier).generateRecipes(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [AppColors.primaryShadow],
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'Regenerate',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [AppColors.primaryShadow],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              top: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
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
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              'Powered by Groq AI',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Recipes based on\nwhat's expiring",
                        style: AppTypography.headlineLarge
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Smart suggestions to reduce food waste',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                const Text('🍳', style: TextStyle(fontSize: 58)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(WidgetRef ref, String current) {
    final filters = [
      ('All', Icons.grid_view_rounded),
      ('Urgent', Icons.schedule_rounded),
      ('Quick', Icons.bolt_rounded),
      ('Easy', Icons.sentiment_satisfied_rounded),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((f) {
            final isActive = f.$1 == current;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () =>
                    ref.read(_recipeFilterProvider.notifier).state = f.$1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isActive ? AppColors.primaryGradient : null,
                    color: isActive ? null : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isActive ? Colors.transparent : AppColors.border,
                    ),
                    boxShadow: isActive ? [AppColors.primaryShadow] : [],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        f.$2,
                        size: 12,
                        color:
                            isActive ? Colors.white : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        f.$1,
                        style: AppTypography.labelSmall.copyWith(
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          const Text('🥗', style: TextStyle(fontSize: 64))
              .animate()
              .scale(curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text('No recipes match', style: AppTypography.headlineSmall)
              .animate()
              .fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text(
            'Try removing filters or tap Regenerate\nfor fresh suggestions',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 160.ms),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1200),
          color: Colors.white.withValues(alpha: 0.55),
        );
  }

  void _openDetail(BuildContext context, RecipeModel recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeDetailSheet(recipe: recipe),
    );
  }
}
