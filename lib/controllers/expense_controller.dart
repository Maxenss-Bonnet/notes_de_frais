import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/ocr_service.dart';

class ExpenseController {
  final OcrService _ocrService = OcrService();

  Future<ExpenseModel> processImage(String imagePath) async {
    final extractedText = await _ocrService.getTextFromImage(imagePath);

    // TODO: Implémenter la logique d'extraction des informations
    // à partir de `extractedText` pour remplir le modèle.
    // Par exemple, utiliser des expressions régulières.

    return ExpenseModel(
      imagePath: imagePath,
      // Les valeurs ci-dessous sont des exemples et devront
      // être extraites du texte.
      date: DateTime.now(),
      amount: 123.45,
      vat: 20.0,
      company: 'Exemple Entreprise',
    );
  }

  Future<void> saveExpense(ExpenseModel expense) async {
    // TODO: Implémenter la logique pour:
    // 1. Envoyer l'email (via un EmailService)
    // 2. Sauvegarder dans un fichier Excel/en ligne (via un StorageService)
    // 3. Sauvegarder dans l'historique local (via un StorageService)
    print('Note de frais sauvegardée pour ${expense.associatedTo}');
  }
}