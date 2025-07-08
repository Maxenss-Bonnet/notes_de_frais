import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/email_service.dart';
import 'package:notes_de_frais/services/google_sheets_service.dart';
import 'package:notes_de_frais/services/settings_service.dart';
import 'package:workmanager/workmanager.dart';

const String taskSendExpense = "sendExpense";
const String taskSendExpenseBatch = "sendExpenseBatch";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await dotenv.load(fileName: ".env");
      await Hive.initFlutter();
      Hive.registerAdapter(ExpenseModelAdapter());
      await Hive.openBox<ExpenseModel>('expenses');

      final emailService = EmailService();
      final googleSheetsService = GoogleSheetsService();
      final settingsService = SettingsService();
      final expenseBox = Hive.box<ExpenseModel>('expenses');

      final sender = dotenv.env['SENDER_EMAIL'];
      final password = dotenv.env['SENDER_APP_PASSWORD'];
      final recipient = await settingsService.getRecipientEmail();
      final spreadsheetId = dotenv.env['GOOGLE_SHEET_ID'];

      if (sender == null || password == null || recipient.isEmpty || spreadsheetId == null) {
        print('Variables d\'environnement manquantes pour les tâches de fond.');
        return Future.value(false);
      }

      switch (task) {
        case taskSendExpense:
          final expenseKey = inputData!['expenseKey'] as int;
          final expense = expenseBox.get(expenseKey);
          if (expense != null) {
            await emailService.sendExpenseEmail(expense: expense, recipient: recipient, sender: sender, password: password);
            await googleSheetsService.appendExpense(expense, spreadsheetId);
            print('Tâches de fond pour une note terminées.');
          }
          break;
        case taskSendExpenseBatch:
          final expenseKeys = (inputData!['expenseKeys'] as List).cast<int>();
          final expenses = expenseKeys.map((key) => expenseBox.get(key)).whereType<ExpenseModel>().toList();
          if (expenses.isNotEmpty) {
            await emailService.sendExpenseBatchEmail(expenses: expenses, recipient: recipient, sender: sender, password: password);
            for (var expense in expenses) {
              await googleSheetsService.appendExpense(expense, spreadsheetId);
            }
            print('Tâches de fond pour le lot terminées.');
          }
          break;
      }
      return Future.value(true);
    } catch (e) {
      print('Erreur lors de l\'exécution des tâches de fond : $e');
      return Future.value(false);
    }
  });
}