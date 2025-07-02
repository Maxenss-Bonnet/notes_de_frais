import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  Future<String> getTextFromImage(String imagePath) async {
    try {
      // Créer une instance de l'InputImage à partir du chemin du fichier
      final inputImage = InputImage.fromFilePath(imagePath);

      // Créer une instance du reconnaisseur de texte pour le script latin (français, anglais, etc.)
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      // Traiter l'image
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      // Extraire le texte brut
      String extractedText = recognizedText.text;

      // Fermer le reconnaisseur de texte pour libérer les ressources
      textRecognizer.close();

      return extractedText;
    } catch (e) {
      print("Erreur lors de la reconnaissance de texte: $e");
      return "";
    }
  }
}