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
          * Examine l'ensemble des images. S'il y en a plusieurs, elles représentent les pages séquentielles d'un seul et même document.
          * Les informations importantes, comme le total à payer, peuvent se trouver sur la dernière page/image.

      2.  **Extraction des Données Spécifiques :**
          * **`company`**: Trouve le nom du magasin ou du fournisseur. Il est généralement en en-tête, en gros caractères (ex: "IKEA", "Amazon", "QUINCAILLERIE PORTALET").
          * **`date`**: Trouve la date principale de la facture ou du ticket. Formate-la impérativement en **AAAA-MM-JJ**.
          * **`amount`**: Identifie le montant **TOTAL** payé par le client (TTC). Cherche les mots-clés les plus pertinents comme "Total TTC", "NET A PAYER", "TOTAL", "Total articles". Ignore les totaux partiels ou le total Hors Taxes (HT). Pour le ticket IKEA, le total se trouve sur la deuxième page.
          * **`vat`**: Identifie le montant total de la TVA. Cherche des lignes spécifiques comme "Total TVA", "Dont TVA". Pour la facture Amazon, il y a une section "Récapitulatif de la TVA" sur la deuxième page. Si plusieurs montants de TVA sont listés (par taux), **fais la somme** pour ne retourner qu'une seule valeur numérique.

      3.  **Formatage de la Sortie :**
          * Ta réponse doit être **UNIQUEMENT** un bloc de code JSON valide.
          * N'ajoute **AUCUN** texte, explication, ou markdown `json` avant ou après le JSON.
          * Si une information est introuvable, sa valeur dans le JSON doit être `null`.

      Analyse maintenant les images jointes et fournis le JSON.
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