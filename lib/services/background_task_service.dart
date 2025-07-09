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
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        print("Changement de connexion détecté, traitement de la file d'attente...");
        processQueue();
      }
    });

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi)) {
      print("Connexion active au démarrage, traitement de la file d'attente...");
      processQueue();
    }
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }

  Future<void> _executeSingleTaskAndCleanup(TaskModel task, int totalTasks, int completedTasks) async {
    final int totalSteps = 3;
    final String taskMessage = "Envoi de la note ${completedTasks + 1}/$totalTasks";
    final expense = task.payload as ExpenseModel;

    final sender = dotenv.env['SENDER_EMAIL'];
    final password = dotenv.env['SENDER_APP_PASSWORD'];
    final recipient = await _settingsService.getRecipientEmail();
    final spreadsheetId = dotenv.env['GOOGLE_SHEET_ID'];

    if (sender == null || password == null || spreadsheetId == null) {
      throw Exception('Variables d\'environnement manquantes.');
    }

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
        executionStatus: TaskExecutionStatus.processing, message: taskMessage, totalTasks: totalTasks, completedTasks: completedTasks,
        stepMessage: "Étape 1/$totalSteps: Envoi de l'e-mail...", currentStep: 0, totalSteps: totalSteps);
    await _emailService.sendExpenseEmail(expense: expense, recipient: recipient, sender: sender, password: password);

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
        executionStatus: TaskExecutionStatus.processing, message: taskMessage, totalTasks: totalTasks, completedTasks: completedTasks,
        stepMessage: "Étape 2/$totalSteps: Ajout à Google Sheets...", currentStep: 1, totalSteps: totalSteps);
    await _sheetsService.appendExpense(expense, spreadsheetId);

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
        executionStatus: TaskExecutionStatus.processing, message: taskMessage, totalTasks: totalTasks, completedTasks: completedTasks,
        stepMessage: "Étape 3/$totalSteps: Nettoyage des fichiers...", currentStep: 2, totalSteps: totalSteps);
    await _fileStorageService.deleteFiles(expense.processedImagePaths);
    print("Fichiers associés à la tâche nettoyés.");

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
        executionStatus: TaskExecutionStatus.processing, message: taskMessage, totalTasks: totalTasks, completedTasks: completedTasks,
        stepMessage: "Terminé !", currentStep: 3, totalSteps: totalSteps);
  }

  Future<void> _executeBatchTaskAndCleanup(TaskModel task, int totalTasks, int completedTasks) async {
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

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
        executionStatus: TaskExecutionStatus.processing, message: taskMessage, totalTasks: totalTasks, completedTasks: completedTasks,
        stepMessage: "Étape 1/$totalSteps: Envoi de l'e-mail combiné...", currentStep: 0, totalSteps: totalSteps);
    await _emailService.sendExpenseBatchEmail(expenses: expenses, recipient: recipient, sender: sender, password: password);

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
        executionStatus: TaskExecutionStatus.processing, message: taskMessage, totalTasks: totalTasks, completedTasks: completedTasks,
        stepMessage: "Étape 2/$totalSteps: Ajout à Google Sheets...", currentStep: 1, totalSteps: totalSteps);
    await _sheetsService.appendExpenseBatch(expenses, spreadsheetId);

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
        executionStatus: TaskExecutionStatus.processing, message: taskMessage, totalTasks: totalTasks, completedTasks: completedTasks,
        stepMessage: "Étape 3/$totalSteps: Nettoyage des fichiers...", currentStep: 2, totalSteps: totalSteps);
    List<String> pathsToDelete = expenses.expand((e) => e.processedImagePaths).toList();
    await _fileStorageService.deleteFiles(pathsToDelete);
    print("Fichiers associés au lot nettoyés.");

    _ref.read(taskStatusProvider.notifier).state = TaskStatus(
        executionStatus: TaskExecutionStatus.processing, message: taskMessage, totalTasks: totalTasks, completedTasks: completedTasks,
        stepMessage: "Terminé !", currentStep: 3, totalSteps: totalSteps);
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
      try {
        if (task.type == TaskType.sendSingleExpense) {
          await _executeSingleTaskAndCleanup(task, initialTaskCount, completedCount);
        } else if (task.type == TaskType.sendExpenseBatch) {
          await _executeBatchTaskAndCleanup(task, initialTaskCount, completedCount);
        }

        await _queueService.completeTask(task.key);
        completedCount++;

      } catch (e) {
        print("Erreur lors de l'exécution de la tâche: $e. Nouvel essai plus tard.");
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
      if(_ref.read(taskStatusProvider.notifier).state.executionStatus != TaskExecutionStatus.processing){
        _ref.read(taskStatusProvider.notifier).state = TaskStatus(executionStatus: TaskExecutionStatus.idle);
      }
    });
  }
}