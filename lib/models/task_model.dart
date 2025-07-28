import 'package:hive/hive.dart';

part 'task_model.g.dart';

enum TaskExecutionStatus {
  idle,
  processing,
  success,
  error,
}

@HiveType(typeId: 2)
enum SendStatus {
  @HiveField(0)
  pending, // Tâche créée, aucune étape exécutée
  @HiveField(1)
  emailSent, // E-mail envoyé avec succès
  @HiveField(2)
  sheetUpdated, // Google Sheets mis à jour avec succès
  @HiveField(3)
  filesDeleted, // Fichiers nettoyés avec succès
  @HiveField(4)
  completed, // Toutes les étapes terminées
}

class TaskStatus {
  final TaskExecutionStatus executionStatus;
  final String? message;
  final int totalTasks;
  final int completedTasks;
  final String? stepMessage;
  final int currentStep;
  final int totalSteps;

  TaskStatus({
    this.executionStatus = TaskExecutionStatus.idle,
    this.message,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.stepMessage,
    this.currentStep = 0,
    this.totalSteps = 0,
  });

  double get progress {
    if (totalTasks == 0) return 0.0;

    final double subProgress =
        totalSteps > 0 ? (currentStep / totalSteps) : 0.0;

    return (completedTasks + subProgress) / totalTasks;
  }
}

@HiveType(typeId: 3)
enum TaskType {
  @HiveField(0)
  sendSingleExpense,
  @HiveField(1)
  sendExpenseBatch,
}

@HiveType(typeId: 1)
class TaskModel extends HiveObject {
  @HiveField(0)
  final TaskType type;

  @HiveField(1)
  final dynamic payload;

    @HiveField(2)
  SendStatus sendStatus;

  TaskModel({
    required this.type, 
    required this.payload,
    SendStatus? sendStatus,
  }) : sendStatus = sendStatus ?? SendStatus.pending;

  // Méthode pour mettre à jour le statut et sauvegarder dans Hive
  Future<void> updateSendStatus(SendStatus newStatus) async {
    sendStatus = newStatus;
    await save(); // Sauvegarde immédiate dans Hive
  }

  // Méthode pour vérifier si une étape spécifique est déjà complétée
  bool isStepCompleted(SendStatus step) {
    return sendStatus.index >= step.index;
  }

  // Méthode pour obtenir l'étape suivante à exécuter
  SendStatus? getNextStep() {
    switch (sendStatus) {
      case SendStatus.pending:
        return SendStatus.emailSent;
      case SendStatus.emailSent:
        return SendStatus.sheetUpdated;
      case SendStatus.sheetUpdated:
        return SendStatus.filesDeleted;
      case SendStatus.filesDeleted:
        return SendStatus.completed;
      case SendStatus.completed:
        return null; // Toutes les étapes sont terminées
    }
  }
}
