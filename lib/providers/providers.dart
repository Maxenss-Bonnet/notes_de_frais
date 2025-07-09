import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/models/task_model.dart';
import 'package:notes_de_frais/services/background_task_service.dart';
import 'package:notes_de_frais/services/statistics_service.dart';
import 'package:notes_de_frais/services/storage_service.dart';

// Provider pour le service de stockage
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Provider pour le service de statistiques
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  // Dépend du storageService pour accéder aux données
  ref.watch(storageServiceProvider);
  return StatisticsService();
});

// Provider qui écoute les changements dans la boîte Hive des dépenses
final expensesStreamProvider = StreamProvider.autoDispose<List<ExpenseModel>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  // Écoute les événements de la boîte et retourne la liste mise à jour
  return storageService.getExpenseBox().watch().map((event) {
    return storageService.getExpenseBox().values.where((e) => !e.isInTrash).toList();
  });
});

// Provider pour les statistiques, qui se met à jour automatiquement
final statisticsProvider = Provider((ref) {
  // Regarde le stream des dépenses. Quand les dépenses changent, ce provider se recalcule.
  ref.watch(expensesStreamProvider);
  // Retourne une nouvelle instance du service de statistiques, qui lira les données fraîches.
  return StatisticsService();
});

// --- Nouveaux Providers pour la gestion des tâches de fond ---

// Provider pour le service de tâches de fond
final backgroundTaskServiceProvider = Provider<BackgroundTaskService>((ref) {
  return BackgroundTaskService(ref);
});

// Provider pour l'état de la file d'attente des tâches
final taskStatusProvider = StateProvider<TaskStatus>((ref) => TaskStatus());