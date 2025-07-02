import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';

class AiService {
  final GenerativeModel _model;

  AiService()
      : _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: dotenv.env['GEMINI_API_KEY']!,
  );

  Future<Map<String, dynamic>> extractExpenseDataFromFile(List<String> filePaths) async {
    final prompt = _buildPrompt();
    final List<DataPart> fileParts = [];

    for (final path in filePaths) {
      final mimeType = lookupMimeType(path);
      if (mimeType != null) {
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

  TextPart _buildPrompt() {
    return TextPart(
        '''
      En tant qu'expert en analyse de reçus et factures, analyse le(s) document(s) ci-joint(s).
      Extrais les informations ci-dessous et retourne-les au format JSON.
      - date: La date de la transaction au format AAAA-MM-JJ.
      - amount: Le montant total TTC payé, sous forme de nombre (double).
      - vat: Le montant total de la TVA, sous forme de nombre (double). Si plusieurs TVA, fais la somme.
      - company: Le nom du vendeur ou du magasin.

      Règles importantes :
      1. Ne retourne QUE le bloc de code JSON, sans aucun autre texte ou explication.
      2. Si une information n'est pas trouvée, sa valeur doit être `null`.
      3. Le montant total (`amount`) est généralement le plus grand montant sur le reçu, souvent associé à des mots comme "TOTAL", "Total TTC", ou "Net à payer".
      4. Le nom de l'entreprise (`company`) est souvent en haut du ticket.
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