import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/models/task_model.dart';
import 'package:notes_de_frais/services/background_task_service.dart';
import 'package:notes_de_frais/services/statistics_service.dart';
import 'package:notes_de_frais/services/storage_service.dart';

// --- Services ---

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  ref.watch(storageServiceProvider);
  return StatisticsService();
});


// --- Données ---

final expensesStreamProvider = StreamProvider.autoDispose<List<ExpenseModel>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getExpenseBox().watch().map((event) {
    return storageService.getExpenseBox().values.where((e) => !e.isInTrash).toList();
  });
});


// --- Statistiques (optimisé) ---

final statisticsProvider = Provider((ref) {
  ref.watch(expensesStreamProvider);
  return StatisticsService();
});

// Providers granulaires pour optimiser les rebuilds
final expensesThisWeekCountProvider = Provider<int>((ref) {
  return ref.watch(statisticsProvider).getExpensesThisWeekCount();
});

final vatSavedThisWeekProvider = Provider<double>((ref) {
  return ref.watch(statisticsProvider).getVatSavedThisWeek();
});

final totalVatSavedProvider = Provider<double>((ref) {
  return ref.watch(statisticsProvider).getTotalVatSaved();
});

final totalAmountSpentProvider = Provider<double>((ref) {
  return ref.watch(statisticsProvider).getTotalAmountSpent();
});

final expensesByCategoryProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(statisticsProvider).getExpensesByCategory();
});

final weeklySummaryProvider = Provider<Map<int, double>>((ref) {
  return ref.watch(statisticsProvider).getWeeklySummary();
});


// --- Tâches de fond ---

final backgroundTaskServiceProvider = Provider<BackgroundTaskService>((ref) {
  return BackgroundTaskService(ref);
});

final taskStatusProvider = StateProvider<TaskStatus>((ref) => TaskStatus());