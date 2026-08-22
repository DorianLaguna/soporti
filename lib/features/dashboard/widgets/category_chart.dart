import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// Gráfico de barras horizontales que muestra la distribución de tickets
/// por categoría en el periodo actual.
class CategoryChart extends StatelessWidget {
  /// Datos de distribución: key = categoría, value = cantidad de tickets.
  final Map<String, int> data;

  const CategoryChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    // Orden fijo de categorías para consistencia visual.
    final categories = [
      AppStrings.categoryHardware,
      AppStrings.categorySoftware,
      AppStrings.categoryNetwork,
      AppStrings.categoryAccess,
      AppStrings.categoryOther,
    ];

    // Filtrar solo las categorías con datos y mantener el orden.
    final entries = categories
        .map((cat) => MapEntry(cat, data[cat] ?? 0))
        .toList();

    final maxValue = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.categoryDistribution,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: entries.length * 48.0,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue == 0 ? 1 : maxValue * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              entries[index].key,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              entries[index].value.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: entries.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: AppColors.uvmGreen,
                          width: 20,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                duration: const Duration(milliseconds: 300),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.categoryDistribution,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                AppStrings.noDataAvailable,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
