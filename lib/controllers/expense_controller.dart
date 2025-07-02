import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/ai_service.dart';

class ExpenseController {
  final AiService _aiService = AiService();

  Future<ExpenseModel> processImages(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      // Retourne un modèle vide si aucun fichier n'est fourni
      return ExpenseModel(imagePath: '');
    }

    // Appelle le nouveau service d'IA avec la liste des chemins de fichiers
    final extractedData = await _aiService.extractExpenseDataFromFile(filePaths);

    return ExpenseModel(
      imagePath: filePaths.first, // Garde la première image comme référence
      date: extractedData['date'],
      amount: extractedData['amount'],
      vat: extractedData['vat'],
      company: extractedData['company'],
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