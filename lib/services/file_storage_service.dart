import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileStorageService {
  Future<String> get _permanentDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    final permanentPath = p.join(directory.path, 'receipts');
    final permanentDirectory = Directory(permanentPath);
    if (!await permanentDirectory.exists()) {
      await permanentDirectory.create(recursive: true);
    }
    return permanentPath;
  }

  Future<String> savePermanently(String temporaryPath) async {
    try {
      final permanentDir = await _permanentDirectory;
      final fileName = p.basename(temporaryPath);
      final permanentFilePath = p.join(permanentDir, fileName);

      final file = File(temporaryPath);
      await file.copy(permanentFilePath);

      return permanentFilePath;
    } catch (e) {
      print("Erreur lors de la sauvegarde permanente du fichier: $e");
      rethrow;
    }
  }

  Future<void> deleteFiles(List<String> permanentPaths) async {
    for (final path in permanentPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print("Erreur lors de la suppression du fichier $path: $e");
      }
    }
  }
}