import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/models/task_model.dart';
import 'package:notes_de_frais/providers/providers.dart';
import 'package:notes_de_frais/services/email_service.dart';
import 'package:notes_de_frais/services/file_storage_service.dart';
import 'package:notes_de_frais/services/google_sheets_service.dart';
import 'package:notes_de_frais/services/settings_service.dart';
import 'package:notes_de_frais/services/task_queue_service.dart';

/// Service de traitement des tâches en arrière-plan avec gestion d'état par étape
///
/// PROBLÈME RÉSOLU :
/// Avant cette implémentation, si l'application était fermée pendant l'envoi d'une note de frais
/// (par exemple après l'envoi de l'email mais avant la mise à jour de Google Sheets),
/// la tâche était rejouée entièrement au redémarrage, causant un envoi d'email en double.
///
/// SOLUTION :
/// Chaque tâche (TaskModel) dispose maintenant d'un champ `sendStatus` (enum SendStatus) qui track
/// l'état de progression de chaque étape :
///
/// 1. pending → Tâche créée, aucune étape exécutée
/// 2. emailSent → E-mail envoyé avec succès
/// 3. sheetUpdated → Google Sheets mis à jour avec succès
/// 4. filesDeleted → Fichiers nettoyés avec succès
/// 5. completed → Toutes les étapes terminées
///
/// FONCTIONNEMENT :
/// - Après chaque étape réussie, le statut est immédiatement sauvegardé dans Hive
/// - En cas d'interruption, la tâche reprend exactement là où elle s'était arrêtée
/// - Plus de doublons d'envoi d'emails ou d'autres opérations
/// - Compatible avec les tâches existantes (migration automatique vers pending)
///
/// ÉTAPES D'ENVOI :
/// Pour sendSingleExpense et sendExpenseBatch :
/// 1. Envoi de l'e-mail (individual ou batch)
/// 2. Ajout à Google Sheets
/// 3. Nettoyage des fichiers temporaires
/// 4. Marquage comme complètement terminé
class BackgroundTaskService {
  final Ref _ref;
  BackgroundTaskService(this._ref);

  final TaskQueueService _queueService = TaskQueueService();
  final EmailService _emailService = EmailService();
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  final SettingsService _settingsService = SettingsService();
  final FileStorageService _fileStorageService = FileStorageService();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isProcessing = false;

  Future<void> initialize() async {
    print("Service de tâches de fond initialisé.");

    // Nettoyer les tâches corrompues au démarrage
    await _queueService.cleanupCorruptedTasks();

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        print(
            "Changement de connexion détecté, traitement de la file d'attente...");
        processQueue();
      }
    });

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      print(
          "Connexion active au démarrage, traitement de la file d'attente...");
      processQueue();
    }
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }

  Future<void> _executeSingleTaskAndCleanup(
      TaskModel task, int totalTasks, int completedTasks) async {
    final int totalSteps = 3;
    final String taskMessage =
        "Envoi de la note ${completedTasks + 1}/$totalTasks";
    final expense = task.payload as ExpenseModel;

    final sender = dotenv.env['SENDER_EMAIL'];
    final password = dotenv.env['SENDER_APP_PASSWORD'];
    final recipient = await _settingsService.getRecipientEmail();
    final spreadsheetId = dotenv.env['GOOGLE_SHEET_ID'];

    if (sender == null || password == null || spreadsheetId == null) {
      throw Exception('Variables d\'environnement manquantes.');
    }

    print("Statut actuel de la tâche: ${task.sendStatus}");

    // Étape 1: Envoi de l'e-mail (si pas déjà fait)
    if (!task.isStepCompleted(SendStatus.emailSent)) {
      _ref.read(taskStatusProvider.notifier).state = TaskStatus(
          executionStatus: TaskExecutionStatus.processing,
          message: taskMessage,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          stepMessage: "Étape 1/$totalSteps: Envoi de l'e-mail...",
          currentStep: 0,
          totalSteps: totalSteps);

      await _emailService.sendExpenseEmail(
          expense: expense,
          recipient: recipient,
          sender: sender,
          password: password);

      // Sauvegarder le statut immédiatement après le succès
      await task.updateSendStatus(SendStatus.emailSent);
      print("E-mail envoyé avec succès et statut sauvegardé");
    } else {
      print("E-mail déjà envoyé, passage à l'étape suivante");
    }

    // Étape 2: Ajout à Google Sheets (si pas déjà fait)
    if (!task.isStepCompleted(SendStatus.sheetUpdated)) {
      _ref.read(taskStatusProvider.notifier).state = TaskStatus(
          executionStatus: TaskExecutionStatus.processing,
          message: taskMessage,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          stepMessage: "Étape 2/$totalSteps: Ajout à Google Sheets...",
          currentStep: 1,
          totalSteps: totalSteps);

      await _sheetsService.appendExpense(expense, spreadsheetId);

      // Sauvegarder le statut immédiatement après le succès
      await task.updateSendStatus(SendStatus.sheetUpdated);
      print("Google Sheets mis à jour avec succès et statut sauvegardé");
    } else {
      print("Google Sheets déjà mis à jour, passage à l'étape suivante");
    }

    // Étape 3: Nettoyage des fichiers (si pas déjà fait)
    if (!task.isStepCompleted(SendStatus.filesDeleted)) {
      _ref.read(taskStatusProvider.notifier).state = TaskStatus(
          executionStatus: TaskExecutionStatus.processing,
          message: taskMessage,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          stepMessage: "Étape 3/$totalSteps: Nettoyage des fichiers...",
          currentStep: 2,
          totalSteps: totalSteps);

      await _fileStorageService.deleteFiles(expense.processedImagePaths);

      // Sauvegarder le statut immédiatement après le succès
      await task.updateSendStatus(SendStatus.filesDeleted);
      print("Fichiers nettoyés avec succès et statut sauvegardé");
    } else {
      print("Fichiers déjà nettoyés, passage à l'étape suivante");
    }

    // Marquer la tâche comme complètement terminée
    await task.updateSendStatus(SendStatus.completed);
    print("Tâche entièrement complétée");

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
        executionStatus: TaskExecutionStatus.processing,
        message: taskMessage,
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        stepMessage: "Terminé !",
        currentStep: 3,
        totalSteps: totalSteps);
  }

  Future<void> _executeBatchTaskAndCleanup(
      TaskModel task, int totalTasks, int completedTasks) async {
    final expenses = (task.payload as List).cast<ExpenseModel>();
    final int totalSteps = 3;
    final String taskMessage = "Envoi du lot de ${expenses.length} notes";

    final sender = dotenv.env['SENDER_EMAIL'];
    final password = dotenv.env['SENDER_APP_PASSWORD'];
    final recipient = await _settingsService.getRecipientEmail();
    final spreadsheetId = dotenv.env['GOOGLE_SHEET_ID'];

    if (sender == null || password == null || spreadsheetId == null) {
      throw Exception('Variables d\'environnement manquantes.');
    }

    print("Statut actuel de la tâche batch: ${task.sendStatus}");

    // Étape 1: Envoi de l'e-mail combiné (si pas déjà fait)
    if (!task.isStepCompleted(SendStatus.emailSent)) {
      _ref.read(taskStatusProvider.notifier).state = TaskStatus(
          executionStatus: TaskExecutionStatus.processing,
          message: taskMessage,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          stepMessage: "Étape 1/$totalSteps: Envoi de l'e-mail combiné...",
          currentStep: 0,
          totalSteps: totalSteps);

      await _emailService.sendExpenseBatchEmail(
          expenses: expenses,
          recipient: recipient,
          sender: sender,
          password: password);

      // Sauvegarder le statut immédiatement après le succès
      await task.updateSendStatus(SendStatus.emailSent);
      print("E-mail batch envoyé avec succès et statut sauvegardé");
    } else {
      print("E-mail batch déjà envoyé, passage à l'étape suivante");
    }

    // Étape 2: Ajout à Google Sheets (si pas déjà fait)
    if (!task.isStepCompleted(SendStatus.sheetUpdated)) {
      _ref.read(taskStatusProvider.notifier).state = TaskStatus(
          executionStatus: TaskExecutionStatus.processing,
          message: taskMessage,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          stepMessage: "Étape 2/$totalSteps: Ajout à Google Sheets...",
          currentStep: 1,
          totalSteps: totalSteps);

      await _sheetsService.appendExpenseBatch(expenses, spreadsheetId);

      // Sauvegarder le statut immédiatement après le succès
      await task.updateSendStatus(SendStatus.sheetUpdated);
      print("Google Sheets batch mis à jour avec succès et statut sauvegardé");
    } else {
      print("Google Sheets batch déjà mis à jour, passage à l'étape suivante");
    }

    // Étape 3: Nettoyage des fichiers (si pas déjà fait)
    if (!task.isStepCompleted(SendStatus.filesDeleted)) {
      _ref.read(taskStatusProvider.notifier).state = TaskStatus(
          executionStatus: TaskExecutionStatus.processing,
          message: taskMessage,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          stepMessage: "Étape 3/$totalSteps: Nettoyage des fichiers...",
          currentStep: 2,
          totalSteps: totalSteps);

      List<String> pathsToDelete =
          expenses.expand((e) => e.processedImagePaths).toList();
      await _fileStorageService.deleteFiles(pathsToDelete);

      // Sauvegarder le statut immédiatement après le succès
      await task.updateSendStatus(SendStatus.filesDeleted);
      print("Fichiers batch nettoyés avec succès et statut sauvegardé");
    } else {
      print("Fichiers batch déjà nettoyés, passage à l'étape suivante");
    }

    // Marquer la tâche comme complètement terminée
    await task.updateSendStatus(SendStatus.completed);
    print("Tâche batch entièrement complétée");

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
        executionStatus: TaskExecutionStatus.processing,
        message: taskMessage,
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        stepMessage: "Terminé !",
        currentStep: 3,
        totalSteps: totalSteps);
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    final initialTaskCount = _queueService.getTaskBox().length;
    if (initialTaskCount == 0) {
      _isProcessing = false;
      return;
    }

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
      executionStatus: TaskExecutionStatus.processing,
      totalTasks: initialTaskCount,
      completedTasks: 0,
      message: 'Initialisation de l\'envoi...',
    );

    int completedCount = 0;

    while (_queueService.getNextTask() != null) {
      final task = _queueService.getNextTask()!;

      // Si la tâche est déjà complètement terminée, on la supprime directement
      if (task.sendStatus == SendStatus.completed) {
        print("Tâche déjà complètement terminée, suppression de la file");
        await _queueService.completeTask(task.key);
        completedCount++;
        continue;
      }

      try {
        if (task.type == TaskType.sendSingleExpense) {
          await _executeSingleTaskAndCleanup(
              task, initialTaskCount, completedCount);
        } else if (task.type == TaskType.sendExpenseBatch) {
          await _executeBatchTaskAndCleanup(
              task, initialTaskCount, completedCount);
        }

        // Suppression de la tâche seulement si elle est complètement terminée
        if (task.sendStatus == SendStatus.completed) {
          await _queueService.completeTask(task.key);
          completedCount++;
        }
      } catch (e) {
        print(
            "Erreur lors de l'exécution de la tâche: $e. La tâche garde son statut actuel pour reprise ultérieure.");
        _ref.read(taskStatusProvider.notifier).state = TaskStatus(
            executionStatus: TaskExecutionStatus.error,
            message: "Erreur: ${e.toString()}",
            totalTasks: initialTaskCount,
            completedTasks: completedCount);
        _isProcessing = false;
        return;
      }
    }

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
        executionStatus: TaskExecutionStatus.success,
        message: "Envoi terminé avec succès !",
        totalTasks: initialTaskCount,
        completedTasks: completedCount);

    _isProcessing = false;

    Future.delayed(const Duration(seconds: 2), () {
      if (_ref.read(taskStatusProvider.notifier).state.executionStatus !=
          TaskExecutionStatus.processing) {
        _ref.read(taskStatusProvider.notifier).state =
            TaskStatus(executionStatus: TaskExecutionStatus.idle);
      }
    });
  }
}
