import 'package:camera/camera.dart';

class CameraConfig {
  // Résolution recommandée pour éviter les conflits de surfaces
  static const ResolutionPreset defaultResolution = ResolutionPreset.medium;

  // Format d'image recommandé
  static const ImageFormatGroup defaultImageFormat = ImageFormatGroup.jpeg;

  // Paramètres de qualité pour la compression
  static const int defaultImageQuality = 70;

  // Délai d'attente pour l'initialisation (en millisecondes)
  static const int initializationTimeout = 10000;

  // Nombre maximum de tentatives d'initialisation
  static const int maxInitializationAttempts = 3;
}
