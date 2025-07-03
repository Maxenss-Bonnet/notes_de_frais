import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/ai_service.dart';
import 'package:notes_de_frais/services/email_service.dart';
import 'package:notes_de_frais/services/google_sheets_service.dart';
import 'package:notes_de_frais/services/settings_service.dart';
import 'package:notes_de_frais/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class ExpenseController {
  final AiService _aiService = AiService();
  final EmailService _emailService = EmailService();
  final SettingsService _settingsService = SettingsService();
  final StorageService _storageService = StorageService();
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService();

  Future<List<ExpenseModel>> processImageBatch(List<String> originalFilePaths) async {
    List<ExpenseModel> processedExpenses = [];

    for (String path in List.from(originalFilePaths)) {
      final List<String> imagesToAnalyze = [];
      if (path.toLowerCase().endsWith('.pdf')) {
        final pdfImages = await _convertPdfToImages(path);
        imagesToAnalyze.addAll(pdfImages);
      } else {
        imagesToAnalyze.add(path);
      }

      if (imagesToAnalyze.isEmpty) {
        processedExpenses.add(ExpenseModel(imagePath: path));
        continue;
      }

      final extractedData = await _aiService.extractExpenseDataFromFiles(imagesToAnalyze);

      processedExpenses.add(
          ExpenseModel(
            imagePath: path,
            processedImagePaths: imagesToAnalyze,
            date: extractedData['date'],
            amount: extractedData['amount'],
            vat: extractedData['vat'],
            company: extractedData['company'],
            category: extractedData['category'],
            normalizedMerchantName: extractedData['normalizedMerchantName'],
          )
      );
    }
    return processedExpenses;
  }

  Future<void> saveExpenseBatchLocally(List<ExpenseModel> expenses) async {
    for (var expense in expenses) {
      await _storageService.saveExpense(expense);
    }
    print('${expenses.length} notes de frais sauvegardées localement.');
  }

  void performBackgroundTasksForBatch(List<ExpenseModel> expenses) async {
    final sender = dotenv.env['SENDER_EMAIL'];
    final password = dotenv.env['SENDER_APP_PASSWORD'];
    final recipient = await _settingsService.getRecipientEmail();
    final spreadsheetId = dotenv.env['GOOGLE_SHEET_ID'];

    if (sender == null || password == null || spreadsheetId == null) {
      print('Variables d\'environnement manquantes pour les tâches de fond.');
      return;
    }

    try {
      await _emailService.sendExpenseBatchEmail(
          expenses: expenses, recipient: recipient, sender: sender, password: password);

      for (var expense in expenses) {
        await _googleSheetsService.appendExpense(expense, spreadsheetId);
      }
      print('Tâches de fond pour le lot terminées.');
    } catch (e) {
      print('Erreur lors de l\'exécution des tâches de fond pour le lot : $e');
    }
  }

  Future<List<String>> _convertPdfToImages(String pdfPath) async {
    final List<String> imagePaths = [];
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(pdfPath);
      final tempDir = await getTemporaryDirectory();
      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width * 3, height: page.height * 3, format: PdfPageImageFormat.png, backgroundColor: '#FFFFFF',
        );
        await page.close();
        if (pageImage != null) {
          final imageFile = File('${tempDir.path}/pdf_page_${i}_${DateTime.now().millisecondsSinceEpoch}.png');
          await imageFile.writeAsBytes(pageImage.bytes);
          imagePaths.add(imageFile.path);
        }
      }
    } catch (e) {
      print("Erreur lors de la conversion du PDF: $e");
    } finally {
      await document?.close();
    }
    return imagePaths;
  }

  Future<void> saveExpenseLocally(ExpenseModel expense) async {
    await _storageService.saveExpense(expense);
  }

  void performBackgroundTasks(ExpenseModel expense) async {
    final sender = dotenv.env['SENDER_EMAIL'];
    final password = dotenv.env['SENDER_APP_PASSWORD'];
    final recipient = await _settingsService.getRecipientEmail();
    final spreadsheetId = dotenv.env['GOOGLE_SHEET_ID'];

    if (sender == null || password == null || spreadsheetId == null) {
      print('Variables d\'environnement manquantes pour les tâches de fond.');
      return;
    }

    try {
      await _emailService.sendExpenseEmail(
          expense: expense, recipient: recipient, sender: sender, password: password);
      await _googleSheetsService.appendExpense(expense, spreadsheetId);
      print('Tâches de fond pour une note terminées.');
    } catch (e) {
      print('Erreur lors de l\'exécution des tâches de fond : $e');
    }
  }
}