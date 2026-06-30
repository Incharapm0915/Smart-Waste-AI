import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../features/inventory/domain/providers/inventory_provider.dart';
import '../../../../shared/models/inventory_item_model.dart';
import '../widgets/shopping_item_tile.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class ShoppingItem {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final double estimatedCost;
  final int quantity;
  final String unit;
  final bool isChecked;
  final bool isAiSuggested;
  final String? reason;
  final Map<String, double> storePrices;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.estimatedCost,
    this.quantity = 1,
    this.unit = 'pcs',
    this.isChecked = false,
    this.isAiSuggested = false,
    this.reason,
    this.storePrices = const {},
  });

  ShoppingItem copyWith({bool? isChecked, int? quantity}) {
    return ShoppingItem(
      id: id,
      name: name,
      emoji: emoji,
      category: category,
      estimatedCost: estimatedCost,
      quantity: quantity ?? this.quantity,
      unit: unit,
      isChecked: isChecked ?? this.isChecked,
      isAiSuggested: isAiSuggested,
      reason: reason,
      storePrices: storePrices,
    );
  }

  double get totalCost => estimatedCost * quantity;

  MapEntry<String, double>? get bestDeal {
    if (storePrices.isEmpty) return null;
    return storePrices.entries.reduce((a, b) => a.value < b.value ? a : b);
  }
}

// ─── Budget History Model ────────────────────────────────────────────────────

class BudgetEntry {
  final String label;
  final double spent;
  final double budget;
  const BudgetEntry(
      {required this.label, required this.spent, required this.budget});
}

final budgetHistoryProvider = Provider<List<BudgetEntry>>((ref) => const [
      BudgetEntry(label: 'Mar 2', spent: 58.40, budget: 80.0),
      BudgetEntry(label: 'Mar 9', spent: 69.20, budget: 80.0),
      BudgetEntry(label: 'Mar 16', spent: 45.60, budget: 80.0),
      BudgetEntry(label: 'Mar 23', spent: 78.90, budget: 80.0),
      BudgetEntry(label: 'Mar 30', spent: 61.30, budget: 80.0),
      BudgetEntry(label: 'Apr 6', spent: 72.80, budget: 80.0),
      BudgetEntry(label: 'Apr 13', spent: 54.20, budget: 80.0),
      BudgetEntry(label: 'Apr 20', spent: 67.50, budget: 80.0),
    ]);

// ─── Notifier ────────────────────────────────────────────────────────────────

final shoppingItemsProvider =
    StateNotifierProvider<ShoppingNotifier, List<ShoppingItem>>(
  (ref) => ShoppingNotifier(),
);

class ShoppingNotifier extends StateNotifier<List<ShoppingItem>> {
  ShoppingNotifier()
      : super(const [
          ShoppingItem(
            id: '1',
            name: 'Whole Milk',
            emoji: '🥛',
            category: 'Dairy',
            estimatedCost: 3.99,
            isAiSuggested: true,
            reason: 'Expiring soon — stock up!',
            storePrices: {
              'Walmart': 3.50,
              'Whole Foods': 4.49,
              'Costco': 3.20
            },
          ),
          ShoppingItem(
            id: '2',
            name: 'Spinach',
            emoji: '🥬',
            category: 'Vegetables',
            estimatedCost: 2.49,
            isAiSuggested: true,
            reason: 'Low in inventory, great for recipes you like',
            storePrices: {
              'Walmart': 2.49,
              'Whole Foods': 3.99,
              'Costco': 1.89
            },
          ),
          ShoppingItem(
            id: '3',
            name: 'Chicken Breast',
            emoji: '🥩',
            category: 'Meat',
            estimatedCost: 8.99,
            isAiSuggested: true,
            reason: 'Almost out — used in 3 of your saved recipes',
            storePrices: {
              'Walmart': 7.99,
              'Whole Foods': 11.99,
              'Costco': 6.49
            },
          ),
          ShoppingItem(
            id: '4',
            name: 'Greek Yogurt',
            emoji: '🍦',
            category: 'Dairy',
            estimatedCost: 4.99,
            storePrices: {
              'Walmart': 4.49,
              'Whole Foods': 5.99,
              'Costco': 3.99
            },
          ),
          ShoppingItem(
            id: '5',
            name: 'Eggs',
            emoji: '🥚',
            category: 'Dairy',
            estimatedCost: 5.49,
            storePrices: {
              'Walmart': 4.99,
              'Whole Foods': 6.49,
              'Costco': 4.29
            },
          ),
          ShoppingItem(
            id: '6',
            name: 'Olive Oil',
            emoji: '🫙',
            category: 'Condiments',
            estimatedCost: 7.99,
            storePrices: {
              'Walmart': 7.49,
              'Whole Foods': 9.99,
              'Costco': 6.49
            },
          ),
        ]);

  void toggle(String id) {
    state = state.map((item) {
      if (item.id == id) return item.copyWith(isChecked: !item.isChecked);
      return item;
    }).toList();
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void add(ShoppingItem item) {
    state = [...state, item];
  }

  void clearChecked() {
    state = state.where((item) => !item.isChecked).toList();
  }

  void updateQuantity(String id, int qty) {
    if (qty < 1) return;
    state = state.map((item) {
      if (item.id == id) return item.copyWith(quantity: qty);
      return item;
    }).toList();
  }

  int autoGenerateFromExpiring(List<InventoryItemModel> expiringItems) {
    final existingNames = state.map((i) => i.name.toLowerCase()).toSet();
    final newItems = expiringItems
        .where((inv) => !existingNames.contains(inv.name.toLowerCase()))
        .map((inv) {
      final days = AppDateUtils.daysUntilExpiry(inv.expiryDate);
      return ShoppingItem(
        id: 'exp_${inv.id}',
        name: inv.name,
        emoji: inv.emoji,
        category: inv.category,
        estimatedCost: 0.0,
        isAiSuggested: true,
        reason: days == 0
            ? 'Expires today — buy a fresh one!'
            : days == 1
                ? 'Expires tomorrow — restock soon'
                : 'Expires in $days days — plan ahead',
      );
    }).toList();
    if (newItems.isNotEmpty) state = [...state, ...newItems];
    return newItems.length;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _searchController = TextEditingController();
  bool _showAiOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _shareList(List<ShoppingItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('🛒 My Shopping List\n');

    final pending = items.where((i) => !i.isChecked).toList();
    final checked = items.where((i) => i.isChecked).toList();

    final ai = pending.where((i) => i.isAiSuggested).toList();
    final manual = pending.where((i) => !i.isAiSuggested).toList();

    if (ai.isNotEmpty) {
      buffer.writeln('🤖 AI Suggestions:');
      for (final item in ai) {
        final cost = item.estimatedCost > 0
            ? ' · \$${item.totalCost.toStringAsFixed(2)}'
            : '';
        buffer.writeln('⬜ ${item.quantity}x ${item.emoji} ${item.name}$cost');
      }
      buffer.writeln();
    }

    if (manual.isNotEmpty) {
      buffer.writeln('📝 My Items:');
      for (final item in manual) {
        final cost = item.estimatedCost > 0
            ? ' · \$${item.totalCost.toStringAsFixed(2)}'
            : '';
        buffer.writeln('⬜ ${item.quantity}x ${item.emoji} ${item.name}$cost');
      }
      buffer.writeln();
    }

    if (checked.isNotEmpty) {
      buffer.writeln('✅ Already have (${checked.length}):');
      for (final item in checked) {
        buffer.writeln('✅ ${item.emoji} ${item.name}');
      }
      buffer.writeln();
    }

    final total = pending.fold(0.0, (sum, i) => sum + i.totalCost);
    if (total > 0) buffer.writeln('💰 Estimated Total: \$${total.toStringAsFixed(2)}\n');
    buffer.write('Shared from Smart Waste AI 🌱');

    Share.share(buffer.toString(), subject: 'My Shopping List');
  }

  void _copyList(List<ShoppingItem> items) {
    final buffer = StringBuffer();
    for (final item in items.where((i) => !i.isChecked)) {
      buffer.writeln('${item.quantity}x ${item.emoji} ${item.name}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Shopping list copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showShareSheet(BuildContext context, List<ShoppingItem> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [AppColors.strongShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Text('Share Shopping List',
                  style: AppTypography.headlineMedium),
            ),
            const Divider(height: 1, color: AppColors.border),
            _ShareOption(
              icon: Icons.share_rounded,
              iconColor: AppColors.primary,
              label: 'Share via WhatsApp, Messages…',
              subtitle: 'Opens system share sheet',
              onTap: () {
                Navigator.pop(context);
                _shareList(items);
              },
            ),
            _ShareOption(
              icon: Icons.copy_rounded,
              iconColor: AppColors.aiPurple,
              label: 'Copy to Clipboard',
              subtitle: 'Paste anywhere',
              onTap: () {
                Navigator.pop(context);
                _copyList(items);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shoppingItemsProvider);
    final search = _searchController.text.toLowerCase();
    final filtered = search.isEmpty
        ? items
        : items.where((i) => i.name.toLowerCase().contains(search)).toList();
    final displayed =
        _showAiOnly ? filtered.where((i) => i.isAiSuggested).toList() : filtered;

    final aiItems = displayed.where((i) => i.isAiSuggested).toList();
    final manualItems = displayed.where((i) => !i.isAiSuggested).toList();
    final checkedCount = items.where((i) => i.isChecked).length;
    final totalCost =
        items.where((i) => !i.isChecked).fold(0.0, (sum, i) => sum + i.totalCost);

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
            _buildAppBar(context, checkedCount, items),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildBudgetCard(totalCost, items.length, checkedCount)
                        .animate()
                        .fadeIn(delay: 80.ms)
                        .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                    const SizedBox(height: 16),
                    _buildAutoGenerateBanner(context)
                        .animate()
                        .fadeIn(delay: 140.ms),
                    const SizedBox(height: 18),
                    _buildSearchAndFilter(),
                    const SizedBox(height: 20),
                    if (aiItems.isNotEmpty) ...[
                      _buildSectionHeader('AI Recommendations', aiItems.length,
                          AppColors.aiPurple),
                      const SizedBox(height: 12),
                      ...aiItems.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ShoppingItemTile(
                              item: e.value,
                              onToggle: () => ref
                                  .read(shoppingItemsProvider.notifier)
                                  .toggle(e.value.id),
                              onRemove: () => ref
                                  .read(shoppingItemsProvider.notifier)
                                  .remove(e.value.id),
                              onQuantityChanged: (qty) => ref
                                  .read(shoppingItemsProvider.notifier)
                                  .updateQuantity(e.value.id, qty),
                            )
                                .animate()
                                .fadeIn(delay: (e.key * 55).ms)
                                .slideX(begin: 0.03, curve: Curves.easeOutCubic),
                          )),
                      const SizedBox(height: 20),
                    ],
                    if (manualItems.isNotEmpty) ...[
                      _buildSectionHeader(
                          'My List', manualItems.length, AppColors.primary),
                      const SizedBox(height: 12),
                      ...manualItems.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ShoppingItemTile(
                              item: e.value,
                              onToggle: () => ref
                                  .read(shoppingItemsProvider.notifier)
                                  .toggle(e.value.id),
                              onRemove: () => ref
                                  .read(shoppingItemsProvider.notifier)
                                  .remove(e.value.id),
                              onQuantityChanged: (qty) => ref
                                  .read(shoppingItemsProvider.notifier)
                                  .updateQuantity(e.value.id, qty),
                            )
                                .animate()
                                .fadeIn(delay: (e.key * 55).ms)
                                .slideX(begin: 0.03, curve: Curves.easeOutCubic),
                          )),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFab(context),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, int checkedCount, List<ShoppingItem> items) {
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
            child: const Icon(Icons.shopping_cart_rounded,
                size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text('Shopping List', style: AppTypography.headlineMedium),
        ],
      ),
      actions: [
        // Analytics button
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/shopping-analytics');
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                size: 18, color: AppColors.primary),
          ),
        ),
        // Share button
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _showShareSheet(context, items);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: const Icon(Icons.ios_share_rounded,
                size: 18, color: AppColors.primary),
          ),
        ),
        // Clear checked button
        if (checkedCount > 0)
          GestureDetector(
            onTap: () =>
                ref.read(shoppingItemsProvider.notifier).clearChecked(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Clear ($checkedCount)',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildBudgetCard(
      double totalCost, int totalItems, int checkedCount) {
    final progress = totalItems > 0 ? checkedCount / totalItems : 0.0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AppColors.primaryShadow],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Total',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.70),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${totalCost.toStringAsFixed(2)}',
                          style: AppTypography.displayMedium
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$checkedCount of $totalItems items checked',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.shopping_cart_rounded,
                            color: Colors.white, size: 26),
                        const SizedBox(height: 4),
                        Text(
                          'Smart\nCart',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.70),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (totalItems > 0) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.20),
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 5,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoGenerateBanner(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    return inventoryAsync.when(
      data: (items) {
        final expiring = items.where((i) {
          final d = AppDateUtils.daysUntilExpiry(i.expiryDate);
          return d >= 0 && d <= 5;
        }).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.aiPurple.withValues(alpha: 0.10),
                AppColors.aiPurpleLight.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.aiPurple.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.aiGradient,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.aiPurple.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Shopping Suggestions',
                      style: AppTypography.headlineSmall
                          .copyWith(color: AppColors.aiPurple),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expiring.isEmpty
                          ? 'All items fresh — no urgent restocks'
                          : '${expiring.length} item${expiring.length > 1 ? 's' : ''} expiring soon',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.aiPurple.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (expiring.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    final added = ref
                        .read(shoppingItemsProvider.notifier)
                        .autoGenerateFromExpiring(expiring);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          added > 0
                              ? 'Added $added item${added > 1 ? 's' : ''} from expiring inventory'
                              : 'All expiring items already in list',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.aiPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: AppColors.aiGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.aiPurple.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Generate',
                      style: AppTypography.labelSmall
                          .copyWith(color: Colors.white),
                    ),
                  ),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.aiPurple.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      size: 17, color: AppColors.aiPurple),
                ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.6)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [AppColors.softShadow],
            ),
            child: TextField(
              controller: _searchController,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textPrimary),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.textTertiary, size: 18),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => setState(() => _showAiOnly = !_showAiOnly),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: _showAiOnly ? AppColors.aiGradient : null,
              color: _showAiOnly ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _showAiOnly ? Colors.transparent : AppColors.border,
              ),
              boxShadow: _showAiOnly
                  ? [
                      BoxShadow(
                        color: AppColors.aiPurple.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: _showAiOnly ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  'AI',
                  style: AppTypography.labelSmall.copyWith(
                    color: _showAiOnly ? Colors.white : AppColors.textSecondary,
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

  Widget _buildSectionHeader(String title, int count, Color color) {
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
        Text(title, style: AppTypography.headlineSmall),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.20)),
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

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddItemSheet(context),
      backgroundColor: AppColors.primary,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        'Add Item',
        style: AppTypography.labelLarge.copyWith(color: Colors.white),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [AppColors.strongShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Add Item', style: AppTypography.headlineMedium),
              const SizedBox(height: 18),
              _inputField(
                controller: nameCtrl,
                hint: 'What do you need?',
                icon: Icons.add_shopping_cart_rounded,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              _inputField(
                controller: costCtrl,
                hint: 'Estimated cost (optional)',
                icon: Icons.attach_money_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final cost =
                      double.tryParse(costCtrl.text.trim()) ?? 0.0;
                  ref.read(shoppingItemsProvider.notifier).add(
                        ShoppingItem(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          name: nameCtrl.text.trim(),
                          emoji: '🛒',
                          category: 'Other',
                          estimatedCost: cost,
                        ),
                      );
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [AppColors.primaryShadow],
                  ),
                  child: Center(
                    child: Text(
                      'Add to List',
                      style: AppTypography.labelLarge
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool autofocus = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        style:
            AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon:
              Icon(icon, color: AppColors.textTertiary, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Share option row ─────────────────────────────────────────────────────────

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(label,
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: AppTypography.caption),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 13, color: AppColors.textTertiary),
    );
  }
}
