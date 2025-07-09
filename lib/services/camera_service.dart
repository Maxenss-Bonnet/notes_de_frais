// lib/services/camera_service.dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import manquant
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'; // Import manquant
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  bool _isCameraInitialized = false;
  bool get isCameraInitialized => _isCameraInitialized;

  bool _isProcessing = false;

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
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await _cameraController!.initialize();
        _isCameraInitialized = true;
      }
    }
  }

  void startImageStream(Function(InputImage) onImage) {
    if (_cameraController == null || !_isCameraInitialized) return;

    _cameraController!.startImageStream((CameraImage image) {
      if (_isProcessing) return;

      _isProcessing = true;
      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage != null) {
          onImage(inputImage);
        }
      } finally {
        // Délais pour éviter de surcharger le buffer
        Future.delayed(const Duration(milliseconds: 250), () {
          _isProcessing = false;
        });
      }
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      var rotationCompensation = (sensorOrientation + 360) % 360;
      switch (rotationCompensation) {
        case 0:
          rotation = InputImageRotation.rotation0deg;
          break;
        case 90:
          rotation = InputImageRotation.rotation90deg;
          break;
        case 180:
          rotation = InputImageRotation.rotation180deg;
          break;
        case 270:
          rotation = InputImageRotation.rotation270deg;
          break;
        default:
          rotation = InputImageRotation.rotation0deg;
      }
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (defaultTargetPlatform == TargetPlatform.android && format != InputImageFormat.nv21) ||
        (defaultTargetPlatform == TargetPlatform.iOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1 && defaultTargetPlatform == TargetPlatform.android) return null;
    if (image.planes.length != 1 && defaultTargetPlatform == TargetPlatform.iOS) return null;


    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
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