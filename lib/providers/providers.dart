import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:notes_de_frais/models/task_model.dart';
import 'package:notes_de_frais/services/background_task_service.dart';
import 'package:notes_de_frais/services/statistics_service.dart';
import 'package:notes_de_frais/services/storage_service.dart';

// --- Services ---

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// --- Fournisseurs de Données de Base ---

// Ce provider fournit un flux direct des événements de la base de données.
// Il sert de "déclencheur" pour les autres providers.
final expenseBoxStreamProvider = StreamProvider.autoDispose<BoxEvent>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getExpenseBox().watch();
});


// --- Fournisseurs de Données Calculées ---

// Provider pour le compteur de notes non envoyées.
final unsentExpensesCountProvider = StateProvider<int>((ref) {
  // Il écoute le flux de la base de données. Chaque fois qu'un événement se produit,
  // ce provider est reconstruit.
  ref.watch(expenseBoxStreamProvider);
  // En se reconstruisant, il récupère la valeur la plus récente du service de stockage.
  return ref.watch(storageServiceProvider).getUnsentExpensesCount();
});


// --- Fournisseurs de Statistiques ---

// Ce provider écoute également le flux de la base de données.
final statisticsProvider = Provider((ref) {
  ref.watch(expenseBoxStreamProvider);
  return StatisticsService();
});

// Ces providers granulaires sont reconstruits automatiquement
// car ils dépendent de 'statisticsProvider', qui est lui-même mis à jour par le stream.
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