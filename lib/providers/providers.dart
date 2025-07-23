import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:notes_de_frais/models/task_model.dart';
import 'package:notes_de_frais/services/background_task_service.dart';
import 'package:notes_de_frais/services/settings_service.dart';
import 'package:notes_de_frais/services/statistics_service.dart';
import 'package:notes_de_frais/services/storage_service.dart';
import 'package:notes_de_frais/utils/constants.dart';

// --- Services ---

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

// --- Fournisseurs de Données de Base ---

final expenseBoxStreamProvider = StreamProvider.autoDispose<BoxEvent>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getExpenseBox().watch();
});

// --- Fournisseurs de Données de Configuration ---

final companyListProvider = FutureProvider<List<String>>((ref) async {
  final settingsService = ref.watch(settingsServiceProvider);
  final customList = await settingsService.getCompanyList();
  if (customList.isNotEmpty) {
    return customList;
  }
  return kCompanyListDefaults;
});

final mileageRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  final settingsService = ref.watch(settingsServiceProvider);
  final customRates = await settingsService.getMileageRates();
  if (customRates.isNotEmpty) {
    return customRates;
  }
  return kMileageRatesDefaults;
});

final cvOptionsProvider = FutureProvider<List<String>>((ref) async {
  final rates = await ref.watch(mileageRatesProvider.future);
  return rates.keys.toList();
});


// --- Fournisseurs de Données Calculées ---

final unsentExpensesCountProvider = StateProvider<int>((ref) {
  ref.watch(expenseBoxStreamProvider);
  return ref.watch(storageServiceProvider).getUnsentExpensesCount();
});


// --- Fournisseurs de Statistiques ---

final statisticsProvider = Provider((ref) {
  ref.watch(expenseBoxStreamProvider);
  return StatisticsService();
});

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