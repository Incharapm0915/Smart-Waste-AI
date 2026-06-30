import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/models/inventory_item_model.dart';
import '../../domain/providers/inventory_provider.dart';
import '../widgets/inventory_item_tile.dart';
import '../widgets/category_filter_bar.dart';

final _selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final _searchQueryProvider = StateProvider<String>((ref) => '');
final _sortModeProvider = StateProvider<SortMode>((ref) => SortMode.expiry);

enum SortMode { expiry, name, category }

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final searchQuery = ref.watch(_searchQueryProvider);
    final sortMode = ref.watch(_sortModeProvider);

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
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    _buildSearchBar(ref),
                    const SizedBox(height: 14),
                    _buildSortRow(ref, sortMode),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            inventoryAsync.when(
              data: (items) {
                final categories = ['All', ...{...items.map((i) => i.category)}];
                var filtered = items.where((item) {
                  final matchesCategory = selectedCategory == 'All' ||
                      item.category == selectedCategory;
                  final matchesSearch = searchQuery.isEmpty ||
                      item.name
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase());
                  return matchesCategory && matchesSearch;
                }).toList();

                filtered.sort((a, b) {
                  switch (sortMode) {
                    case SortMode.expiry:
                      return a.expiryDate.compareTo(b.expiryDate);
                    case SortMode.name:
                      return a.name.compareTo(b.name);
                    case SortMode.category:
                      return a.category.compareTo(b.category);
                  }
                });

                return SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CategoryFilterBar(
                          categories: categories,
                          selected: selectedCategory,
                          onSelect: (cat) => ref
                              .read(_selectedCategoryProvider.notifier)
                              .state = cat,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (filtered.isEmpty)
                        _buildEmptyState(context)
                      else
                        _buildInventoryList(filtered, ref, context),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFab(context),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
              Icons.inventory_2_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text('My Inventory', style: AppTypography.headlineMedium),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => context.push('/barcode-scanner'),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.textPrimary, size: 15),
                const SizedBox(width: 4),
                Text(
                  'Barcode',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/camera'),
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [AppColors.primaryShadow],
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'AI Scan',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppColors.softShadow],
      ),
      child: TextField(
        onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search your inventory...',
          hintStyle: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
          suffixIcon: const Icon(
            Icons.tune_rounded,
            color: AppColors.textTertiary,
            size: 18,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSortRow(WidgetRef ref, SortMode current) {
    final modes = [
      (SortMode.expiry, 'Expiry', Icons.schedule_outlined),
      (SortMode.name, 'A–Z', Icons.sort_by_alpha_rounded),
      (SortMode.category, 'Category', Icons.category_outlined),
    ];
    return Row(
      children: [
        Text(
          'Sort:',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        ...modes.map((mode) {
          final isActive = current == mode.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  ref.read(_sortModeProvider.notifier).state = mode.$1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.border,
                  ),
                  boxShadow: isActive ? [AppColors.primaryShadow] : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      mode.$3,
                      size: 12,
                      color: isActive ? Colors.white : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mode.$2,
                      style: AppTypography.caption.copyWith(
                        color: isActive ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInventoryList(
    List<InventoryItemModel> items,
    WidgetRef ref,
    BuildContext context,
  ) {
    final expired = items
        .where((i) => AppDateUtils.daysUntilExpiry(i.expiryDate) < 0)
        .toList();
    final critical = items.where((i) {
      final d = AppDateUtils.daysUntilExpiry(i.expiryDate);
      return d >= 0 && d <= 2;
    }).toList();
    final warning = items.where((i) {
      final d = AppDateUtils.daysUntilExpiry(i.expiryDate);
      return d > 2 && d <= 5;
    }).toList();
    final safe = items
        .where((i) => AppDateUtils.daysUntilExpiry(i.expiryDate) > 5)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expired.isNotEmpty) ...[
            _buildGroupHeader('Expired', expired.length, AppColors.danger),
            const SizedBox(height: 10),
            ...expired.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InventoryItemTile(item: e.value, ref: ref)
                      .animate()
                      .fadeIn(delay: (e.key * 55).ms)
                      .slideX(begin: 0.04, curve: Curves.easeOutCubic),
                )),
            const SizedBox(height: 18),
          ],
          if (critical.isNotEmpty) ...[
            _buildGroupHeader(
                'Expiring Soon', critical.length, AppColors.warning),
            const SizedBox(height: 10),
            ...critical.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InventoryItemTile(item: e.value, ref: ref)
                      .animate()
                      .fadeIn(delay: (e.key * 55).ms)
                      .slideX(begin: 0.04, curve: Curves.easeOutCubic),
                )),
            const SizedBox(height: 18),
          ],
          if (warning.isNotEmpty) ...[
            _buildGroupHeader(
                'Use This Week', warning.length, AppColors.warning),
            const SizedBox(height: 10),
            ...warning.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InventoryItemTile(item: e.value, ref: ref)
                      .animate()
                      .fadeIn(delay: (e.key * 55).ms)
                      .slideX(begin: 0.04, curve: Curves.easeOutCubic),
                )),
            const SizedBox(height: 18),
          ],
          if (safe.isNotEmpty) ...[
            _buildGroupHeader('Fresh', safe.length, AppColors.safe),
            const SizedBox(height: 10),
            ...safe.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InventoryItemTile(item: e.value, ref: ref)
                      .animate()
                      .fadeIn(delay: (e.key * 55).ms)
                      .slideX(begin: 0.04, curve: Curves.easeOutCubic),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTypography.headlineSmall),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            count.toString(),
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [AppColors.primaryShadow],
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 38,
              color: Colors.white,
            ),
          )
              .animate()
              .scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text('No items found', style: AppTypography.headlineSmall)
              .animate()
              .fadeIn(delay: 150.ms),
          const SizedBox(height: 8),
          Text(
            'Scan groceries or add items manually\nto start tracking your food',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 220.ms),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => context.go('/camera'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [AppColors.primaryShadow],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Scan Now',
                    style: AppTypography.labelLarge
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.go('/camera'),
      backgroundColor: AppColors.primary,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
    );
  }
}
