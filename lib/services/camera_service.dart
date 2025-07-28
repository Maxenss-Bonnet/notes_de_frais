import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notes_de_frais/utils/camera_config.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  bool _isCameraInitialized = false;
  bool get isCameraInitialized => _isCameraInitialized;

  bool _isInitializing = false;
  int _initializationAttempts = 0;

  Future<void> initializeCamera() async {
    // Éviter les initialisations multiples
    if (_isInitializing || _isCameraInitialized) return;

    // Vérifier le nombre de tentatives
    if (_initializationAttempts >= CameraConfig.maxInitializationAttempts) {
      print("Nombre maximum de tentatives d'initialisation atteint");
      return;
    }

    _isInitializing = true;
    _initializationAttempts++;

    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }

      if (status.isGranted) {
        final cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          // Disposer de l'ancien contrôleur s'il existe
          await _cameraController?.dispose();

          _cameraController = CameraController(
            cameras.first,
            CameraConfig.defaultResolution,
            enableAudio: false,
            imageFormatGroup: CameraConfig.defaultImageFormat,
          );

          await _cameraController!.initialize().timeout(
                Duration(milliseconds: CameraConfig.initializationTimeout),
              );
          _isCameraInitialized = true;
          _initializationAttempts =
              0; // Réinitialiser le compteur en cas de succès
        }
      }
    } catch (e) {
      print("Erreur lors de l'initialisation de la caméra: $e");
      // Réinitialiser l'état en cas d'erreur
      await _cameraController?.dispose();
      _cameraController = null;
      _isCameraInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  Future<XFile?> takePicture() async {
    if (_cameraController == null || !_isCameraInitialized) return null;
    try {
      return await _cameraController!.takePicture();
    } catch (e) {
      print("Erreur lors de la prise de photo: $e");
      return null;
    }
  }

  Future<void> dispose() async {
    _isInitializing = false;
    _isCameraInitialized = false;
    _initializationAttempts = 0;
    await _cameraController?.dispose();
    _cameraController = null;
  }

  Future<void> resetCamera() async {
    await dispose();
    await initializeCamera();
  }
}
