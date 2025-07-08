import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/ai_service.dart';
import 'package:notes_de_frais/services/background_service.dart';
import 'package:notes_de_frais/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:workmanager/workmanager.dart';

class ExpenseController {
  final AiService _aiService = AiService();
  final StorageService _storageService = StorageService();

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

  Future<int> saveExpenseLocally(ExpenseModel expense) async {
    return await _storageService.saveExpense(expense);
  }

  Future<List<int>> saveExpenseBatchLocally(List<ExpenseModel> expenses) async {
    List<int> keys = [];
    for (var expense in expenses) {
      keys.add(await _storageService.saveExpense(expense));
    }
    print('${expenses.length} notes de frais sauvegardées localement.');
    return keys;
  }

  void performBackgroundTasks(int expenseKey) {
    Workmanager().registerOneOffTask(
      "expenseTask-${expenseKey}",
      taskSendExpense,
      inputData: <String, dynamic>{'expenseKey': expenseKey},
      constraints: Constraints(networkType: NetworkType.connected),
    );
    print('Tâche de fond pour une note programmée.');
  }

  void performBackgroundTasksForBatch(List<int> expenseKeys) {
    Workmanager().registerOneOffTask(
      "expenseBatchTask-${DateTime.now().millisecondsSinceEpoch}",
      taskSendExpenseBatch,
      inputData: <String, dynamic>{'expenseKeys': expenseKeys},
      constraints: Constraints(networkType: NetworkType.connected),
    );
    print('Tâche de fond pour un lot programmée.');
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
}