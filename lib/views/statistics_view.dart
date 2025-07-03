import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/services/statistics_service.dart';
import 'package:collection/collection.dart'; // Ajout de l'import manquant

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
            _buildSectionTitle('Dépenses par société'),
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
          children: [
            Expanded(child: _buildKpiCard('Notes cette semaine', _statsService.getExpensesThisWeekCount().toString(), Icons.note_add_outlined, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildKpiCard('Total TVA économisée', _currencyFormat.format(_statsService.getTotalVatSaved()), Icons.shield_outlined, Colors.green)),
          ],
        ),
        const SizedBox(height: 16),
        _buildKpiCard('Dépenses totales', _currencyFormat.format(_statsService.getTotalAmountSpent()), Icons.receipt_long_outlined, Colors.blue, isFullWidth: true),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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

  Widget _buildPieChart() {
    final data = _statsService.getExpensesByCompany();
    if (data.isEmpty) return const SizedBox(height: 150, child: Center(child: Text('Aucune donnée')));

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: data.entries.map((entry) {
            return PieChartSectionData(
              color: Colors.primaries[data.keys.toList().indexOf(entry.key) % Colors.primaries.length],
              value: entry.value,
              title: '${_currencyFormat.format(entry.value)}\n(${entry.key})',
              radius: 80,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (data.values.max * 1.2).toDouble(),
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
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
        ),
      ),
    );
  }
}