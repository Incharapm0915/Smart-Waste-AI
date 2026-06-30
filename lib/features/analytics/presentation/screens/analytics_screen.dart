import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/context_colors.dart';
import '../widgets/waste_donut_chart.dart';
import '../widgets/savings_bar_chart.dart';
import '../widgets/trend_line_chart.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final _analyticsPeriodProvider = StateProvider<String>((ref) => '30d');

// ─── Data per period (static demo, replace with real Firestore data) ──────────

Map<String, dynamic> _periodData(String period) {
  switch (period) {
    case '7d':
      return {
        'foodSaved': '0.6 kg',
        'moneySaved': '\$8',
        'wasted': '0.2 kg',
        'foodTrend': '+5%',
        'moneyTrend': '+3%',
        'wasteTrend': '-12%',
        'insight': 'Great start! You saved 0.6 kg this week. Dairy still expires most often.',
        'wasteSubtitle': 'Last 7 days',
        'savingsSubtitle': 'Past week',
        'trendSubtitle': 'Last 7 days',
      };
    case '90d':
      return {
        'foodSaved': '7.2 kg',
        'moneySaved': '\$102',
        'wasted': '1.8 kg',
        'foodTrend': '+22%',
        'moneyTrend': '+19%',
        'wasteTrend': '-14%',
        'insight': 'Excellent! Over 90 days you saved \$102. Your waste rate is 31% below average.',
        'wasteSubtitle': 'Last 90 days',
        'savingsSubtitle': 'Past quarter',
        'trendSubtitle': 'Last 90 days',
      };
    default: // 30d
      return {
        'foodSaved': '2.4 kg',
        'moneySaved': '\$34',
        'wasted': '0.6 kg',
        'foodTrend': '+18%',
        'moneyTrend': '+12%',
        'wasteTrend': '-8%',
        'insight': 'You waste 32% less than average. Dairy expires most often — try buying smaller portions.',
        'wasteSubtitle': 'By food category',
        'savingsSubtitle': 'Money saved vs wasted',
        'trendSubtitle': 'Last 30 days — improving',
      };
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_analyticsPeriodProvider);
    final data = _periodData(period);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            context.isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.adaptiveBackground,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context, ref, period, data),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildPeriodSelector(context, ref, period),
                    const SizedBox(height: 20),
                    _buildSummaryCards(context, data)
                        .animate()
                        .fadeIn(delay: 80.ms)
                        .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                    const SizedBox(height: 20),
                    _buildAiInsightBanner(context, data['insight'] as String)
                        .animate()
                        .fadeIn(delay: 140.ms),
                    const SizedBox(height: 24),
                    _buildWasteSection(context, data['wasteSubtitle'] as String)
                        .animate()
                        .fadeIn(delay: 200.ms),
                    const SizedBox(height: 20),
                    _buildSavingsSection(context, data['savingsSubtitle'] as String)
                        .animate()
                        .fadeIn(delay: 270.ms),
                    const SizedBox(height: 20),
                    _buildTrendSection(context, data['trendSubtitle'] as String)
                        .animate()
                        .fadeIn(delay: 340.ms),
                    const SizedBox(height: 20),
                    _buildCategoryBreakdown(context)
                        .animate()
                        .fadeIn(delay: 400.ms),
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

  Widget _buildAppBar(BuildContext context, WidgetRef ref, String period, Map<String, dynamic> data) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.adaptiveBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: context.adaptiveBorder,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.insights_rounded, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text('Analytics',
              style: AppTypography.headlineMedium
                  .copyWith(color: context.adaptiveTextPrimary)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () => _exportData(context, period, data),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.adaptiveSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.adaptiveBorder),
                boxShadow: [AppColors.softShadow],
              ),
              child: Row(
                children: [
                  Icon(Icons.file_download_outlined,
                      size: 14, color: context.adaptiveTextSecondary),
                  const SizedBox(width: 5),
                  Text(
                    'Export',
                    style: AppTypography.labelSmall.copyWith(
                      color: context.adaptiveTextSecondary,
                      fontWeight: FontWeight.w600,
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

  void _exportData(BuildContext context, String period, Map<String, dynamic> data) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportSheet(period: period, data: data),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, WidgetRef ref, String current) {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final label = current == '7d'
        ? 'Last 7 days'
        : current == '30d'
            ? 'This month'
            : 'Last 90 days';

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTypography.headlineSmall
                    .copyWith(color: context.adaptiveTextPrimary)),
            Text(
              '${months[now.month - 1]} ${now.year}',
              style: AppTypography.caption.copyWith(color: context.adaptiveTextTertiary),
            ),
          ],
        ),
        const Spacer(),
        for (final chip in ['7d', '30d', '90d']) ...[
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(_analyticsPeriodProvider.notifier).state = chip;
            },
            child: _buildPeriodChip(context, chip, chip == current),
          ),
          if (chip != '90d') const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _buildPeriodChip(BuildContext context, String label, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.primaryGradient : null,
        color: isActive ? null : context.adaptiveSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.transparent : context.adaptiveBorder,
        ),
        boxShadow: isActive ? [AppColors.primaryShadow] : [],
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isActive ? Colors.white : context.adaptiveTextSecondary,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            data['foodSaved'] as String,
            'Food Saved',
            Icons.eco_rounded,
            AppColors.primary,
            AppColors.primarySurface,
            data['foodTrend'] as String,
            true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            context,
            data['moneySaved'] as String,
            'Money Saved',
            Icons.savings_rounded,
            AppColors.warning,
            AppColors.warningLight,
            data['moneyTrend'] as String,
            true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            context,
            data['wasted'] as String,
            'Wasted',
            Icons.delete_outline_rounded,
            AppColors.danger,
            AppColors.dangerLight,
            data['wasteTrend'] as String,
            false,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
    Color lightBg,
    String trend,
    bool isPositive,
  ) {
    final bg = context.isDark
        ? color.withValues(alpha: 0.12)
        : lightBg;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 11,
                color: isPositive ? AppColors.safe : AppColors.danger,
              ),
              const SizedBox(width: 2),
              Text(
                trend,
                style: AppTypography.caption.copyWith(
                  color: isPositive ? AppColors.safe : AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightBanner(BuildContext context, String insight) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.aiGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.aiPurple.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insight,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteSection(BuildContext context, String subtitle) {
    return _buildChartCard(
      context,
      title: 'Waste Breakdown',
      subtitle: subtitle,
      icon: Icons.pie_chart_rounded,
      iconColor: AppColors.danger,
      child: const WasteDonutChart(),
    );
  }

  Widget _buildSavingsSection(BuildContext context, String subtitle) {
    return _buildChartCard(
      context,
      title: 'Weekly Savings',
      subtitle: subtitle,
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.primary,
      child: const SavingsBarChart(),
    );
  }

  Widget _buildTrendSection(BuildContext context, String subtitle) {
    return _buildChartCard(
      context,
      title: 'Waste Trend',
      subtitle: subtitle,
      icon: Icons.show_chart_rounded,
      iconColor: AppColors.safe,
      child: const TrendLineChart(),
    );
  }

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.adaptiveCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.adaptiveBorder),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.headlineSmall
                          .copyWith(color: context.adaptiveTextPrimary)),
                  Text(
                    subtitle,
                    style: AppTypography.caption
                        .copyWith(color: context.adaptiveTextTertiary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context) {
    final categories = [
      ('Dairy', 0.35, AppColors.chartColors[0]),
      ('Vegetables', 0.25, AppColors.chartColors[1]),
      ('Meat', 0.20, AppColors.chartColors[2]),
      ('Fruits', 0.12, AppColors.chartColors[3]),
      ('Other', 0.08, AppColors.chartColors[4]),
    ];
    return _buildChartCard(
      context,
      title: 'Category Usage',
      subtitle: 'Items consumed vs wasted',
      icon: Icons.category_rounded,
      iconColor: AppColors.warning,
      child: Column(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: cat.$3,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(cat.$1,
                            style: AppTypography.labelMedium.copyWith(
                                color: context.adaptiveTextPrimary)),
                      ],
                    ),
                    Text(
                      '${(cat.$2 * 100).toInt()}%',
                      style: AppTypography.labelMedium.copyWith(
                          color: cat.$3, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: cat.$2,
                    backgroundColor: context.adaptiveSurfaceVariant,
                    valueColor: AlwaysStoppedAnimation(cat.$3),
                    minHeight: 7,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Export Sheet ─────────────────────────────────────────────────────────────

class _ExportSheet extends StatelessWidget {
  final String period;
  final Map<String, dynamic> data;

  const _ExportSheet({required this.period, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.adaptiveSheetBg,
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
                color: context.adaptiveBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.file_download_outlined,
                      size: 20, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Text('Export Analytics',
                    style: AppTypography.headlineMedium
                        .copyWith(color: context.adaptiveTextPrimary)),
              ],
            ),
          ),
          Divider(color: context.adaptiveBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                _ExportOption(
                  icon: Icons.table_chart_outlined,
                  label: 'Share as CSV',
                  subtitle: 'Spreadsheet-compatible format',
                  color: AppColors.primary,
                  onTap: () => _shareCSV(context),
                ),
                const SizedBox(height: 10),
                _ExportOption(
                  icon: Icons.summarize_outlined,
                  label: 'Share Summary',
                  subtitle: 'Quick text report',
                  color: AppColors.aiPurple,
                  onTap: () => _shareSummary(context),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCSV(BuildContext context) async {
    Navigator.pop(context);
    final csv = StringBuffer();
    csv.writeln('Smart Waste AI Analytics Report');
    csv.writeln('Period,$period');
    csv.writeln('Food Saved,${data['foodSaved']}');
    csv.writeln('Money Saved,${data['moneySaved']}');
    csv.writeln('Food Wasted,${data['wasted']}');
    csv.writeln('Food Trend,${data['foodTrend']}');
    csv.writeln('Money Trend,${data['moneyTrend']}');
    csv.writeln('Waste Trend,${data['wasteTrend']}');
    csv.writeln('');
    csv.writeln('Category,Waste %');
    csv.writeln('Dairy,35%');
    csv.writeln('Vegetables,25%');
    csv.writeln('Meat,20%');
    csv.writeln('Fruits,12%');
    csv.writeln('Other,8%');

    await Share.share(
      csv.toString(),
      subject: 'Smart Waste AI — Analytics ($period)',
    );
  }

  Future<void> _shareSummary(BuildContext context) async {
    Navigator.pop(context);
    final summary = '''
📊 Smart Waste AI — Analytics Summary ($period)

🌱 Food Saved: ${data['foodSaved']} (${data['foodTrend']})
💰 Money Saved: ${data['moneySaved']} (${data['moneyTrend']})
🗑️ Food Wasted: ${data['wasted']} (${data['wasteTrend']})

🤖 AI Insight: ${data['insight']}

Top waste categories:
• Dairy — 35%
• Vegetables — 25%
• Meat — 20%
• Fruits — 12%

Generated by Smart Waste AI''';

    await Share.share(summary, subject: 'Smart Waste AI — Analytics');
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.adaptiveSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.adaptiveBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.labelLarge.copyWith(
                          color: context.adaptiveTextPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.bodySmall.copyWith(
                          color: context.adaptiveTextSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: context.adaptiveTextTertiary),
          ],
        ),
      ),
    );
  }
}
