import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  bool _isCameraInitialized = false;
  bool get isCameraInitialized => _isCameraInitialized;

  Future<void> initializeCamera() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        _isCameraInitialized = true;
      }
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

  void dispose() {
    _cameraController?.dispose();
    _isCameraInitialized = false;
  }
}