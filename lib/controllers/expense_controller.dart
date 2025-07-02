import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/ai_service.dart';
import 'package:notes_de_frais/services/email_service.dart';
import 'package:notes_de_frais/services/settings_service.dart';
import 'package:notes_de_frais/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class ExpenseController {
  final AiService _aiService = AiService();
  final EmailService _emailService = EmailService();
  final SettingsService _settingsService = SettingsService();
  final StorageService _storageService = StorageService();

  Future<ExpenseModel> processImages(List<String> originalFilePaths) async {
    // ... (le reste de la fonction ne change pas)
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
      return ExpenseModel(imagePath: referencePath, processedImagePaths: originalFilePaths);
    }

    final extractedData = await _aiService.extractExpenseDataFromFiles(imagePathsToAnalyze);

    return ExpenseModel(
      imagePath: referencePath,
      processedImagePaths: imagePathsToAnalyze,
      date: extractedData['date'],
      amount: extractedData['amount'],
      vat: extractedData['vat'],
      company: extractedData['company'],
    );
  }

  Future<List<String>> _convertPdfToImages(String pdfPath) async {
    // ... (le reste de la fonction ne change pas)
    final List<String> imagePaths = [];
    PdfDocument? document;
    try {
      print('Début de la conversion pour le PDF: $pdfPath');
      document = await PdfDocument.openFile(pdfPath);
      final tempDir = await getTemporaryDirectory();
      print('PDF ouvert avec succès. Nombre de pages: ${document.pagesCount}');

      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);

        final pageImage = await page.render(
          width: page.width * 3,
          height: page.height * 3,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
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
    final sender = dotenv.env['SENDER_EMAIL'];
    final password = dotenv.env['SENDER_APP_PASSWORD'];
    final recipient = await _settingsService.getRecipientEmail();

    if (sender == null || password == null) {
      throw 'Les variables d\'environnement SENDER_EMAIL ou SENDER_APP_PASSWORD ne sont pas définies. Vérifiez votre fichier .env.';
    }

    try {
      await _emailService.sendExpenseEmail(
        expense: expense,
        recipient: recipient,
        sender: sender,
        password: password,
      );
      print('E-mail envoyé avec succès à $recipient.');

      // Sauvegarde dans l'historique local APRES l'envoi réussi
      await _storageService.saveExpense(expense);
      print('Note de frais sauvegardée dans l\'historique local.');

    } catch (e) {
      print('Erreur lors de l\'envoi direct de l\'e-mail: $e');
      throw 'Impossible d\'envoyer l\'e-mail. Vérifiez vos identifiants dans le fichier .env et votre connexion internet.';
    }
  }
}