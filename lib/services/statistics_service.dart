// lib/services/statistics_service.dart

import 'package:collection/collection.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/storage_service.dart';

class StatisticsService {
  final StorageService _storageService = StorageService();

  List<ExpenseModel> _getValidExpenses() {
    return _storageService.getExpenseBox().values.where((e) => !e.isInTrash).toList();
  }

  DateTime _getStartOfWeek() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  double getTotalVatSaved() {
    final expenses = _getValidExpenses();
    return expenses.map((e) => e.vat ?? 0).sum;
  }

  double getVatSavedThisWeek() {
    final expenses = _getValidExpenses();
    final startOfWeek = _getStartOfWeek();
    return expenses
        .where((e) => e.date != null && e.date!.isAfter(startOfWeek))
        .map((e) => e.vat ?? 0)
        .sum;
  }

  int getExpensesThisWeekCount() {
    final expenses = _getValidExpenses();
    final startOfWeek = _getStartOfWeek();
    return expenses.where((e) => e.date != null && e.date!.isAfter(startOfWeek)).length;
  }

  double getTotalAmountSpent() {
    final expenses = _getValidExpenses();
    return expenses.map((e) => e.amount ?? 0).sum;
  }

  Map<String, double> getExpensesByCategory() {
    final expenses = _getValidExpenses();
    final map = <String, double>{};

    for (var expense in expenses) {
      final category = expense.category ?? 'Autre';
      final amount = expense.amount ?? 0;
      map[category] = (map[category] ?? 0) + amount;
    }
    return map;
  }

  Map<String, double> getExpensesByMerchantForCategory(String category, {int count = 5}) {
    final expenses = _getValidExpenses().where((e) => e.category == category);
    final map = <String, double>{};

    for (var expense in expenses) {
      final merchant = expense.normalizedMerchantName ?? 'Inconnu';
      final amount = expense.amount ?? 0;
      map[merchant] = (map[merchant] ?? 0) + amount;
    }

    var sortedEntries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var topEntries = sortedEntries.take(count);

    return Map.fromEntries(topEntries);
  }

  Map<int, double> getWeeklySummary() {
    final expenses = _getValidExpenses();
    final now = DateTime.now();
    final summary = <int, double>{
      for (int i = 1; i <= 7; i++) i: 0.0
    };

    final startOfWeek = _getStartOfWeek();
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final weeklyExpenses = expenses.where((e) =>
    e.date != null &&
        e.date!.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        e.date!.isBefore(endOfWeek)
    );

    for (var expense in weeklyExpenses) {
      summary[expense.date!.weekday] = (summary[expense.date!.weekday] ?? 0) + (expense.amount ?? 0);
    }

    return summary;
  }
}