import 'package:collection/collection.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/storage_service.dart';

class StatisticsService {
  final StorageService _storageService = StorageService();

  List<ExpenseModel> _getValidExpenses() {
    // Correction : Utilisation de getExpenseBox()
    return _storageService.getExpenseBox().values.where((e) => !e.isInTrash).toList();
  }

  // KPI 1: Total de la TVA économisée
  double getTotalVatSaved() {
    final expenses = _getValidExpenses();
    return expenses.map((e) => e.vat ?? 0).sum;
  }

  // KPI 2: Nombre de notes de frais cette semaine
  int getExpensesThisWeekCount() {
    final expenses = _getValidExpenses();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return expenses.where((e) => e.date != null && e.date!.isAfter(startOfWeek)).length;
  }

  // KPI 3: Montant total dépensé
  double getTotalAmountSpent() {
    final expenses = _getValidExpenses();
    return expenses.map((e) => e.amount ?? 0).sum;
  }

  // Données pour le graphique à secteurs (camembert)
  Map<String, double> getExpensesByCompany() {
    final expenses = _getValidExpenses();
    final map = <String, double>{};

    for (var expense in expenses) {
      final company = expense.associatedTo ?? 'Non défini';
      final amount = expense.amount ?? 0;
      map[company] = (map[company] ?? 0) + amount;
    }
    return map;
  }

  // Données pour le graphique en barres
  Map<int, double> getWeeklySummary() {
    final expenses = _getValidExpenses();
    final now = DateTime.now();
    final summary = <int, double>{};

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final expensesForDay = expenses.where((e) =>
      e.date != null &&
          e.date!.year == day.year &&
          e.date!.month == day.month &&
          e.date!.day == day.day
      );
      summary[day.weekday] = expensesForDay.map((e) => e.amount ?? 0).sum;
    }
    return summary;
  }
}