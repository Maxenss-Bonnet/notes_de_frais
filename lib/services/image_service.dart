import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  Future<String> compressImage(String filePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: 70, // Qualité de 0 à 100
      );

      return result?.path ?? filePath;
    } catch (e) {
      print("Erreur lors de la compression de l'image: $e");
      return filePath; // Retourne le chemin original en cas d'erreur
    }
  }
}