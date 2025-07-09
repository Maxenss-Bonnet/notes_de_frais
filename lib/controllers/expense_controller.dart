import 'dart:io';
import 'package:notes_de_frais/models/task_model.dart';
import 'package:notes_de_frais/services/background_task_service.dart';
import 'package:notes_de_frais/services/file_storage_service.dart';
import 'package:notes_de_frais/services/image_service.dart';
import 'package:notes_de_frais/services/task_queue_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/ai_service.dart';
import 'package:notes_de_frais/services/storage_service.dart';

class ExpenseController {
  final AiService _aiService = AiService();
  final StorageService _storageService = StorageService();
  final ImageService _imageService = ImageService();
  final TaskQueueService _taskQueueService = TaskQueueService();
  final FileStorageService _fileStorageService = FileStorageService();

  Future<List<ExpenseModel>> processImageBatch(List<String> originalFilePaths) async {
    List<ExpenseModel> processedExpenses = [];

    for (String path in List.from(originalFilePaths)) {
      final List<String> imagesToAnalyze = [];
      final List<String> permanentImagePaths = [];

      if (path.toLowerCase().endsWith('.pdf')) {
        final pdfImages = await _convertPdfToImages(path);
        imagesToAnalyze.addAll(pdfImages);
      } else {
        final compressedPath = await _imageService.compressImage(path);
        imagesToAnalyze.add(compressedPath);
      }

      for (final imagePath in imagesToAnalyze) {
        final permanentPath = await _fileStorageService.savePermanently(imagePath);
        permanentImagePaths.add(permanentPath);
      }

      if (permanentImagePaths.isEmpty) {
        processedExpenses.add(ExpenseModel(imagePath: path));
        continue;
      }

      final extractedData = await _aiService.extractExpenseDataFromFiles(permanentImagePaths);

      processedExpenses.add(
          ExpenseModel(
            imagePath: permanentImagePaths.first,
            processedImagePaths: permanentImagePaths,
            date: extractedData['date'],
            amount: extractedData['amount'],
            vat: extractedData['vat'],
            company: extractedData['company'],
            category: extractedData['category'],
            normalizedMerchantName: extractedData['normalizedMerchantName'],
            amountConfidence: extractedData['amountConfidence'],
            dateConfidence: extractedData['dateConfidence'],
            companyConfidence: extractedData['companyConfidence'],
            vatConfidence: extractedData['vatConfidence'],
            categoryConfidence: extractedData['categoryConfidence'],
            normalizedMerchantNameConfidence: extractedData['normalizedMerchantNameConfidence'],
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

  void performBackgroundTasksForBatch(List<ExpenseModel> expenses) {
    final task = TaskModel(type: TaskType.sendBatchExpense, payload: expenses);
    _taskQueueService.enqueueTask(task);
    print("Tâche pour le lot mise en file d'attente.");
    BackgroundTaskService().processQueue();
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

          final compressedPath = await _imageService.compressImage(imageFile.path);
          imagePaths.add(compressedPath);
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

  void performBackgroundTasks(ExpenseModel expense) {
    final task = TaskModel(type: TaskType.sendSingleExpense, payload: expense);
    _taskQueueService.enqueueTask(task);
    print("Tâche unique mise en file d'attente.");
    BackgroundTaskService().processQueue();
  }
}