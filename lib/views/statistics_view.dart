import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/providers/providers.dart';
import 'package:notes_de_frais/services/statistics_service.dart';
import 'package:notes_de_frais/views/category_detail_view.dart';

class StatisticsView extends ConsumerWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statisticsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildKpiSection(ref, currencyFormat),
              const SizedBox(height: 24),
              const _SectionTitle('Dépenses par catégorie'),
              const SizedBox(height: 16),
              _buildCategoryChart(context, ref, currencyFormat),
              const SizedBox(height: 24),
              const _SectionTitle('Activité de la semaine'),
              const SizedBox(height: 16),
              _buildBarChart(ref, currencyFormat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSection(WidgetRef ref, NumberFormat currencyFormat) {
    final expensesThisWeek = ref.watch(expensesThisWeekCountProvider);
    final vatThisWeek = ref.watch(vatSavedThisWeekProvider);
    final totalVat = ref.watch(totalVatSavedProvider);
    final totalAmount = ref.watch(totalAmountSpentProvider);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _KpiCard(
                    title: 'Notes cette semaine',
                    value: expensesThisWeek.toString(),
                    icon: Icons.note_add_outlined,
                    color: Colors.orange)),
            const SizedBox(width: 16),
            Expanded(
                child: _KpiCard(
                    title: 'TVA (cette semaine)',
                    value: currencyFormat.format(vatThisWeek),
                    icon: Icons.calendar_today,
                    color: Colors.purple)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _KpiCard(
                    title: 'Total TVA économisée',
                    value: currencyFormat.format(totalVat),
                    icon: Icons.shield_outlined,
                    color: Colors.green)),
            const SizedBox(width: 16),
            Expanded(
                child: _KpiCard(
                    title: 'Dépenses totales',
                    value: currencyFormat.format(totalAmount),
                    icon: Icons.receipt_long_outlined,
                    color: Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChart(
      BuildContext context, WidgetRef ref, NumberFormat currencyFormat) {
    final data = ref.watch(expensesByCategoryProvider);
    if (data.isEmpty) {
      return const SizedBox(
          height: 150, child: Center(child: Text('Aucune dépense à afficher')));
    }

    return SizedBox(
      height: 200,
      child: RepaintBoundary(
        child: PieChart(
          PieChartData(
            sections: data.entries.map((entry) {
              final index = data.keys.toList().indexOf(entry.key);
              return PieChartSectionData(
                color: Colors.primaries[index % Colors.primaries.length]
                    .withOpacity(0.8),
                value: entry.value,
                title: '${entry.key}\n${currencyFormat.format(entry.value)}',
                radius: 80,
                titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 2)]),
                titlePositionPercentageOffset: 0.55,
              );
            }).toList(),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                if (event is FlTapUpEvent &&
                    pieTouchResponse?.touchedSection != null) {
                  final touchedSection = pieTouchResponse!.touchedSection;
                  if (touchedSection != null) {
                    final touchedIndex = touchedSection.touchedSectionIndex;
                    final category = data.keys.elementAt(touchedIndex);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            CategoryDetailView(category: category),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(WidgetRef ref, NumberFormat currencyFormat) {
    final data = ref.watch(weeklySummaryProvider);
    if (data.values.every((v) => v == 0)) {
      return const SizedBox(
          height: 150,
          child: Center(child: Text('Aucune dépense cette semaine')));
    }

    final maxValue =
        data.values.isEmpty ? 0 : data.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: RepaintBoundary(
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue == 0 ? 10 : maxValue * 1.2,
            barGroups: data.entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    color: Colors.blue,
                    width: 22,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        if (value % (maxValue / 4).ceil() == 0 ||
                            value == maxValue) {
                          return Text(currencyFormat.format(value),
                              style: const TextStyle(fontSize: 10));
                        }
                        return const Text('');
                      })),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const style = TextStyle(fontSize: 10);
                    String text;
                    switch (value.toInt()) {
                      case 1:
                        text = 'Lun';
                        break;
                      case 2:
                        text = 'Mar';
                        break;
                      case 3:
                        text = 'Mer';
                        break;
                      case 4:
                        text = 'Jeu';
                        break;
                      case 5:
                        text = 'Ven';
                        break;
                      case 6:
                        text = 'Sam';
                        break;
                      case 7:
                        text = 'Dim';
                        break;
                      default:
                        text = '';
                    }
                    return Text(text, style: style);
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: Colors.grey,
                  strokeWidth: 0.2,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey, width: 0.2),
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: Text(
        'Section',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
