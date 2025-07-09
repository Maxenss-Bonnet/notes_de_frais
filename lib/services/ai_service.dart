import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';

class AiService {
  final GenerativeModel _model;

  AiService()
      : _model = GenerativeModel(
    model: 'gemini-2.5-flash-lite-preview-06-17',
    apiKey: dotenv.env['GEMINI_API_KEY']!,
  );

  Future<Map<String, dynamic>> extractExpenseDataFromFiles(List<String> imagePaths) async {
    final prompt = _buildEnhancedPrompt();
    final List<DataPart> fileParts = [];

    for (final path in imagePaths) {
      final mimeType = lookupMimeType(path);
      if (mimeType != null && mimeType.startsWith('image/')) {
        fileParts.add(
          DataPart(mimeType, await File(path).readAsBytes()),
        );
      }
    }

    if (fileParts.isEmpty) return {};

    try {
      final response = await _model.generateContent([
        Content.multi([...fileParts, prompt])
      ]);

      final jsonString = _extractJsonString(response.text);

      if (jsonString != null) {
        final decodedJson = json.decode(jsonString);

        return {
          'date': decodedJson['date'] != null ? DateTime.tryParse(decodedJson['date']) : null,
          'amount': (decodedJson['amount'] as num?)?.toDouble(),
          'vat': (decodedJson['vat'] as num?)?.toDouble(),
          'company': decodedJson['company'],
          'category': decodedJson['category'],
          'normalizedMerchantName': decodedJson['normalizedMerchantName'],
          'amountConfidence': (decodedJson['amountConfidence'] as num?)?.toDouble(),
          'dateConfidence': (decodedJson['dateConfidence'] as num?)?.toDouble(),
          'companyConfidence': (decodedJson['companyConfidence'] as num?)?.toDouble(),
          'vatConfidence': (decodedJson['vatConfidence'] as num?)?.toDouble(),
          'categoryConfidence': (decodedJson['categoryConfidence'] as num?)?.toDouble(),
          'normalizedMerchantNameConfidence': (decodedJson['normalizedMerchantNameConfidence'] as num?)?.toDouble(),
        };
      }
    } catch (e) {
      print("Erreur lors de l'appel à l'API Gemini: $e");
    }
    return {};
  }

  TextPart _buildEnhancedPrompt() {
    return TextPart(
        '''
      Tu es un expert-comptable spécialisé dans l'analyse de documents. Ta mission est d'extraire les informations suivantes des images jointes.

      **Instructions étape par étape :**

      1.  **Analyse Globale :**
          * Examine l'ensemble des images. S'il y en a plusieurs, elles représentent les pages d'un seul document.

      2.  **Extraction des Données Spécifiques :**
          * **`company`**: Le nom brut du magasin ou du fournisseur (ex: "AMAZON.FR", "McDo Opéra").
          * **`date`**: La date principale de la facture/ticket. Formate-la impérativement en **AAAA-MM-JJ**.
          * **`amount`**: Le montant **TOTAL TTC** payé.
          * **`vat`**: Le montant total de la TVA. Fais la somme si plusieurs taux sont présents.
          * **`normalizedMerchantName`**: Normalise le nom du marchand. Ex: "AMAZON.FR" devient "Amazon", "McDo Opéra" devient "McDonald's".
          * **`category`**: Attribue une catégorie parmi la liste suivante :
            - Restauration
            - Transport
            - Hébergement
            - Fournitures & Services
            - Péages & Parking
            - Shopping & Loisirs
            - Autre

      3.  **Indice de Confiance :**
          * Pour **TOUS** les champs que tu extrais (`company`, `date`, `amount`, `vat`, `normalizedMerchantName`, `category`), ajoute un indice de confiance.
          * Le nom du champ de confiance doit être le nom du champ original suffixé par `Confidence` (ex: `amountConfidence`).
          * L'indice doit être un nombre entre 0.0 (très incertain) et 1.0 (très certain).

      4.  **Formatage de la Sortie :**
          * Ta réponse doit être **UNIQUEMENT** un bloc de code JSON valide.
          * N'ajoute **AUCUN** texte ou markdown avant ou après le JSON.
          * Si une information est introuvable, sa valeur doit être `null`, et son indice de confiance aussi.

      Analyse maintenant et fournis le JSON.
      '''
    );
  }

  String? _extractJsonString(String? text) {
    if (text == null) return null;
    final regex = RegExp(r'```json\s*([\s\S]*?)\s*```|({[\s\S]*})');
    final match = regex.firstMatch(text);
    return match?.group(1) ?? match?.group(2);
  }
}