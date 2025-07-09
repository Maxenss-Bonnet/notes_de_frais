import 'dart:io';
import 'dart:math';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageService {
  Future<String> compressImage(String filePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}_${p.basename(filePath)}';
      final targetPath = p.join(tempDir.path, uniqueFileName);

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
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