import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/models/task_model.dart';
import 'package:notes_de_frais/services/email_service.dart';
import 'package:notes_de_frais/services/file_storage_service.dart';
import 'package:notes_de_frais/services/google_sheets_service.dart';
import 'package:notes_de_frais/services/settings_service.dart';
import 'package:notes_de_frais/services/task_queue_service.dart';

class BackgroundTaskService {
  // --- Singleton Pattern ---
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();

  factory BackgroundTaskService() {
    return _instance;
  }

  BackgroundTaskService._internal();
  // -------------------------

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

  Future<void> processQueue() async { // Changé de _processQueue à processQueue
    if (_isProcessing) return;
    _isProcessing = true;

    final task = _queueService.getNextTask();
    if (task != null) {
      print("Tâche trouvée, type: ${task.type}");
      try {
        await _executeTask(task);

        await _cleanupTaskFiles(task);
        await _queueService.completeTask(task.key);

        print("Tâche complétée et supprimée de la file.");

        _isProcessing = false;
        processQueue(); // Appel interne mis à jour
      } catch (e) {
        print("Erreur lors de l'exécution de la tâche: $e. Nouvel essai plus tard.");
        _isProcessing = false;
      }
    } else {
      print("File d'attente vide.");
      _isProcessing = false;
    }
  }

  Future<void> _cleanupTaskFiles(TaskModel task) async {
    List<String> pathsToDelete = [];
    switch (task.type) {
      case TaskType.sendSingleExpense:
        final expense = task.payload as ExpenseModel;
        pathsToDelete.addAll(expense.processedImagePaths);
        break;
      case TaskType.sendBatchExpense:
        final expenses = (task.payload as List).cast<ExpenseModel>();
        for (final expense in expenses) {
          pathsToDelete.addAll(expense.processedImagePaths);
        }
        break;
    }
    await _fileStorageService.deleteFiles(pathsToDelete);
    print("Fichiers associés à la tâche nettoyés.");
  }

  Future<void> _executeTask(TaskModel task) async {
    final sender = dotenv.env['SENDER_EMAIL'];
    final password = dotenv.env['SENDER_APP_PASSWORD'];
    final recipient = await _settingsService.getRecipientEmail();
    final spreadsheetId = dotenv.env['GOOGLE_SHEET_ID'];

    if (sender == null || password == null || spreadsheetId == null) {
      throw Exception('Variables d\'environnement manquantes.');
    }

    switch (task.type) {
      case TaskType.sendSingleExpense:
        final expense = task.payload as ExpenseModel;
        await _emailService.sendExpenseEmail(expense: expense, recipient: recipient, sender: sender, password: password);
        await _sheetsService.appendExpense(expense, spreadsheetId);
        break;
      case TaskType.sendBatchExpense:
        final expenses = (task.payload as List).cast<ExpenseModel>();
        await _emailService.sendExpenseBatchEmail(expenses: expenses, recipient: recipient, sender: sender, password: password);
        for (var expense in expenses) {
          await _sheetsService.appendExpense(expense, spreadsheetId);
        }
        break;
    }
  }
}