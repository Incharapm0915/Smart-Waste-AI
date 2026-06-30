import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class WasteDonutChart extends StatefulWidget {
  const WasteDonutChart({super.key});

  @override
  State<WasteDonutChart> createState() => _WasteDonutChartState();
}

class _WasteDonutChartState extends State<WasteDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final data = [
      ('Dairy', 35.0, AppColors.chartColors[0]),
      ('Veggies', 25.0, AppColors.chartColors[1]),
      ('Meat', 20.0, AppColors.chartColors[2]),
      ('Fruits', 12.0, AppColors.chartColors[3]),
      ('Other', 8.0, AppColors.chartColors[4]),
    ];

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      setState(() => _touchedIndex = -1);
                      return;
                    }
                    setState(() {
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: data.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isTouch = i == _touchedIndex;
                  return PieChartSectionData(
                    value: item.$2,
                    color: item.$3,
                    radius: isTouch ? 75 : 65,
                    title: isTouch ? '${item.$2.toInt()}%' : '',
                    titleStyle: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    borderSide: isTouch
                        ? const BorderSide(color: Colors.white, width: 2)
                        : BorderSide.none,
                  );
                }).toList(),
                centerSpaceRadius: 45,
                sectionsSpace: 3,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: data.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.$3,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.$1, style: AppTypography.bodySmall),
                    ),
                    Text(
                      '${item.$2.toInt()}%',
                      style: AppTypography.labelSmall.copyWith(color: item.$3),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
