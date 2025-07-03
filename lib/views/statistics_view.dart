import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/services/statistics_service.dart';
import 'package:collection/collection.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  final StatisticsService _statsService = StatisticsService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildKpiSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Top 5 des dépenses par marchand'),
            const SizedBox(height: 16),
            _buildMerchantChart(),
            const SizedBox(height: 24),
            _buildSectionTitle('Dépenses par société (interne)'),
            const SizedBox(height: 16),
            _buildPieChart(),
            const SizedBox(height: 24),
            _buildSectionTitle('Activité de la semaine'),
            const SizedBox(height: 16),
            _buildBarChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiSection() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildKpiCard('Notes cette semaine', _statsService.getExpensesThisWeekCount().toString(), Icons.note_add_outlined, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildKpiCard('TVA (cette semaine)', _currencyFormat.format(_statsService.getVatSavedThisWeek()), Icons.calendar_today, Colors.purple)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildKpiCard('Total TVA économisée', _currencyFormat.format(_statsService.getTotalVatSaved()), Icons.shield_outlined, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildKpiCard('Dépenses totales', _currencyFormat.format(_statsService.getTotalAmountSpent()), Icons.receipt_long_outlined, Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
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
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMerchantChart() {
    final data = _statsService.getExpensesByMerchant();
    if (data.isEmpty) return const SizedBox(height: 100, child: Center(child: Text('Aucune donnée de marchand')));

    final maxValue = data.values.isEmpty ? 0 : data.values.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_currencyFormat.format(entry.value), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: maxValue > 0 ? entry.value / maxValue : 0,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.cyan,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final data = _statsService.getExpensesByCompany();
    if (data.isEmpty) return const SizedBox(height: 150, child: Center(child: Text('Aucune donnée')));

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: data.entries.map((entry) {
            final index = data.keys.toList().indexOf(entry.key);
            return PieChartSectionData(
              color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.7),
              value: entry.value,
              title: '${entry.key}\n${_currencyFormat.format(entry.value)}',
              radius: 80,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              titlePositionPercentageOffset: 0.55,
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final data = _statsService.getWeeklySummary();
    if (data.values.every((v) => v == 0)) return const SizedBox(height: 150, child: Center(child: Text('Aucune dépense cette semaine')));

    final maxValue = data.values.isEmpty ? 0 : data.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
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
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) {
              if (value == 0) return const Text('');
              if (value % (maxValue / 4).ceil() == 0 || value == maxValue) {
                return Text(_currencyFormat.format(value), style: const TextStyle(fontSize: 10));
              }
              return const Text('');
            })),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(fontSize: 10);
                  String text;
                  switch (value.toInt()) {
                    case 1: text = 'Lun'; break;
                    case 2: text = 'Mar'; break;
                    case 3: text = 'Mer'; break;
                    case 4: text = 'Jeu'; break;
                    case 5: text = 'Ven'; break;
                    case 6: text = 'Sam'; break;
                    case 7: text = 'Dim'; break;
                    default: text = '';
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
    );
  }
}