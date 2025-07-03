import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/services/statistics_service.dart';

class CategoryDetailView extends StatelessWidget {
  final String category;

  const CategoryDetailView({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final StatisticsService statsService = StatisticsService();
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final data = statsService.getExpensesByMerchantForCategory(category);
    final maxValue = data.values.isEmpty ? 0 : data.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: Text('Détail : $category'),
      ),
      body: data.isEmpty
          ? const Center(child: Text('Aucune dépense pour cette catégorie.'))
          : ListView(
        padding: const EdgeInsets.all(16.0),
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
                    Text(currencyFormat.format(entry.value), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
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
    );
  }
}