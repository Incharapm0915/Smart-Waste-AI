import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import 'shopping_screen.dart';

class ShoppingAnalyticsScreen extends ConsumerWidget {
  const ShoppingAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(budgetHistoryProvider);
    final items = ref.watch(shoppingItemsProvider);

    const weeklyBudget = 80.0;
    final thisWeek = history.isNotEmpty ? history.last : null;
    final totalSaved = history.fold(
        0.0, (sum, e) => sum + (e.budget - e.spent).clamp(0.0, e.budget));

    // Category breakdown from current list
    final categoryTotals = <String, double>{};
    for (final item in items.where((i) => !i.isChecked)) {
      categoryTotals.update(
        item.category,
        (v) => v + item.totalCost,
        ifAbsent: () => item.totalCost,
      );
    }

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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildSummaryRow(thisWeek, weeklyBudget, totalSaved)
                        .animate()
                        .fadeIn(delay: 80.ms)
                        .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Weekly Spend', Icons.bar_chart_rounded),
                    const SizedBox(height: 14),
                    _buildWeeklyChart(history, weeklyBudget)
                        .animate()
                        .fadeIn(delay: 160.ms),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                        'Budget History', Icons.history_rounded),
                    const SizedBox(height: 14),
                    _buildHistoryList(history)
                        .animate()
                        .fadeIn(delay: 220.ms),
                    const SizedBox(height: 24),
                    if (categoryTotals.isNotEmpty) ...[
                      _buildSectionTitle(
                          'Category Breakdown', Icons.pie_chart_rounded),
                      const SizedBox(height: 14),
                      _buildCategoryBreakdown(categoryTotals)
                          .animate()
                          .fadeIn(delay: 290.ms),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionTitle(
                        'Store Price Comparison', Icons.storefront_rounded),
                    const SizedBox(height: 14),
                    _buildStorePriceTable(items)
                        .animate()
                        .fadeIn(delay: 360.ms),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      leading: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pop(context);
        },
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              size: 18, color: AppColors.textPrimary),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics_rounded,
                size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text('Shopping Analytics', style: AppTypography.headlineMedium),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      BudgetEntry? thisWeek, double budget, double totalSaved) {
    final spent = thisWeek?.spent ?? 0.0;
    final remaining = (budget - spent).clamp(0.0, budget);
    final overBudget = spent > budget;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'This Week',
            value: '\$${spent.toStringAsFixed(2)}',
            sub: overBudget
                ? '\$${(spent - budget).toStringAsFixed(2)} over'
                : '\$${remaining.toStringAsFixed(2)} left',
            color: overBudget ? AppColors.danger : AppColors.primary,
            icon: Icons.calendar_today_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Total Saved',
            value: '\$${totalSaved.toStringAsFixed(2)}',
            sub: 'vs \$${budget.toStringAsFixed(0)}/wk budget',
            color: AppColors.infoBlue,
            icon: Icons.savings_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Budget',
            value: '\$${budget.toStringAsFixed(0)}',
            sub: 'per week',
            color: AppColors.aiPurple,
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTypography.headlineSmall),
      ],
    );
  }

  Widget _buildWeeklyChart(List<BudgetEntry> history, double budget) {
    if (history.isEmpty) return const SizedBox.shrink();

    final maxY = (history.map((e) => e.spent).reduce((a, b) => a > b ? a : b) *
            1.25)
        .ceilToDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Spent'),
              SizedBox(width: 14),
              _LegendDot(color: AppColors.border, label: 'Budget line'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toInt()}',
                        style: AppTypography.caption.copyWith(fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= history.length) {
                          return const SizedBox.shrink();
                        }
                        final label = history[i].label;
                        final short = label.split(' ').last;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            short,
                            style: AppTypography.caption
                                .copyWith(fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: budget,
                      color: AppColors.warning.withValues(alpha: 0.6),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                    ),
                  ],
                ),
                barGroups: history.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final overBudget = e.spent > budget;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: e.spent,
                        gradient: overBudget
                            ? const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xFFEF4444),
                                  Color(0xFFFF6B6B)
                                ],
                              )
                            : const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xFF2ECC71),
                                  Color(0xFF38EF7D)
                                ],
                              ),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<BudgetEntry> history) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        children: history.reversed.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final saved = (e.budget - e.spent).clamp(0.0, e.budget);
          final overBudget = e.spent > e.budget;
          final progress = (e.spent / e.budget).clamp(0.0, 1.0);
          final color =
              overBudget ? AppColors.danger : AppColors.primary;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            overBudget
                                ? Icons.trending_up_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 18,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Week of ${e.label}',
                                  style: AppTypography.labelLarge),
                              Text(
                                overBudget
                                    ? '\$${(e.spent - e.budget).toStringAsFixed(2)} over budget'
                                    : '\$${saved.toStringAsFixed(2)} saved',
                                style: AppTypography.bodySmall
                                    .copyWith(color: color),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${e.spent.toStringAsFixed(2)}',
                              style: AppTypography.labelLarge.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'of \$${e.budget.toStringAsFixed(0)}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            AppColors.border.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < history.length - 1)
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.border.withValues(alpha: 0.6)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> totals) {
    if (totals.isEmpty) return const SizedBox.shrink();

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = totals.values.fold(0.0, (a, b) => a + b);
    const colors = AppColors.chartColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          final pct = total > 0 ? cat.value / total : 0.0;
          final color = colors[i % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(cat.key,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textPrimary)),
                    ),
                    Text(
                      '\$${cat.value.toStringAsFixed(2)}',
                      style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor:
                        AppColors.border.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStorePriceTable(List<ShoppingItem> items) {
    final withPrices =
        items.where((i) => i.storePrices.length > 1).toList();
    if (withPrices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text('No store price data yet',
              style: AppTypography.bodyMedium),
        ),
      );
    }

    const stores = ['Walmart', 'Whole Foods', 'Costco'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                  bottom: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.6))),
            ),
            child: Row(
              children: [
                const Expanded(
                    flex: 3,
                    child: Text('Item',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary))),
                ...stores.map((s) => Expanded(
                      flex: 2,
                      child: Text(
                        s,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    )),
              ],
            ),
          ),
          ...withPrices.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final best = item.bestDeal?.key;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Text(item.emoji,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                item.name,
                                style: AppTypography.labelSmall.copyWith(
                                    fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...stores.map((store) {
                        final price = item.storePrices[store];
                        final isBest = store == best;
                        return Expanded(
                          flex: 2,
                          child: Center(
                            child: price == null
                                ? Text('—',
                                    style: AppTypography.caption
                                        .copyWith(
                                            color: AppColors.textTertiary))
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: isBest
                                        ? BoxDecoration(
                                            color: AppColors.primarySurface,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: AppColors.primaryLight),
                                          )
                                        : null,
                                    child: Text(
                                      '\$${price.toStringAsFixed(2)}',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 11,
                                        color: isBest
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        fontWeight: isBest
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (i < withPrices.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [AppColors.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: AppTypography.headlineMedium
                  .copyWith(color: color, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 2),
          Text(sub,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary, fontSize: 9)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: AppTypography.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
