import 'dart:io';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/ai_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class ExpenseController {
  final AiService _aiService = AiService();

  Future<ExpenseModel> processImages(List<String> originalFilePaths) async {
    if (originalFilePaths.isEmpty) {
      return ExpenseModel(imagePath: '');
    }

    final List<String> imagePathsToAnalyze = [];
    final String referencePath = originalFilePaths.first;

    for (String path in originalFilePaths) {
      if (path.toLowerCase().endsWith('.pdf')) {
        final convertedImagePaths = await _convertPdfToImages(path);
        imagePathsToAnalyze.addAll(convertedImagePaths);
      } else {
        imagePathsToAnalyze.add(path);
      }
    }

    if (imagePathsToAnalyze.isEmpty) {
      print("Aucune image n'a pu être extraite des fichiers fournis.");
      return ExpenseModel(imagePath: referencePath);
    }

    final extractedData = await _aiService.extractExpenseDataFromFiles(imagePathsToAnalyze);

    return ExpenseModel(
      imagePath: referencePath,
      date: extractedData['date'],
      amount: extractedData['amount'],
      vat: extractedData['vat'],
      company: extractedData['company'],
    );
  }

  /// Convertit un fichier PDF en une liste d'images, une pour chaque page.
  Future<List<String>> _convertPdfToImages(String pdfPath) async {
    final List<String> imagePaths = [];
    PdfDocument? document;
    try {
      print('Début de la conversion pour le PDF: $pdfPath');
      document = await PdfDocument.openFile(pdfPath);
      final tempDir = await getTemporaryDirectory();
      print('PDF ouvert avec succès. Nombre de pages: ${document.pagesCount}');

      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);

        // Amélioration de la qualité de rendu
        final pageImage = await page.render(
          width: page.width * 3, // Augmentation significative de la résolution
          height: page.height * 3,
          format: PdfPageImageFormat.png, // Format sans perte
          backgroundColor: '#FFFFFF', // Fond blanc pour une meilleure clarté
        );

        await page.close();

        if (pageImage != null) {
          final imageFile = File('${tempDir.path}/pdf_page_${i}_${DateTime.now().millisecondsSinceEpoch}.png');
          await imageFile.writeAsBytes(pageImage.bytes);
          imagePaths.add(imageFile.path);
          print('Page $i convertie et sauvegardée dans: ${imageFile.path}');
        } else {
          print('ERREUR: Le rendu de la page $i a échoué (résultat nul).');
        }
      }
    } catch (e) {
      print("ERREUR CATCH: Une exception est survenue lors de la conversion du PDF: $e");
    } finally {
      await document?.close();
    }

    print('Conversion terminée. ${imagePaths.length} image(s) créée(s).');
    return imagePaths;
  }

  Future<void> saveExpense(ExpenseModel expense) async {
    // TODO: Implémenter la logique pour:
    // 1. Envoyer l'email (via un EmailService)
    // 2. Sauvegarder dans un fichier Excel/en ligne (via un StorageService)
    // 3. Sauvegarder dans l'historique local (via un StorageService)
    print('Note de frais sauvegardée pour ${expense.associatedTo}');
  }
}