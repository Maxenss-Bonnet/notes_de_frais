import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:notes_de_frais/views/history_view.dart';
import 'package:notes_de_frais/views/statistics_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notes_de_frais/views/validation_view.dart';
import 'package:notes_de_frais/views/settings_view.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isCameraInitialized) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitializing) return;

    setState(() {
      _isCameraInitializing = true;
    });

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

        try {
          await _cameraController!.initialize();
          if (mounted) {
            setState(() {
              _isCameraInitialized = true;
            });
          }
        } catch (e) {
          print('Erreur lors de l\'initialisation de la caméra: $e');
        }
      }
    } else {
      print('Permission caméra refusée');
    }

    if (mounted) {
      setState(() {
        _isCameraInitializing = false;
      });
    }
  }

  Future<void> _navigateToValidationScreen(List<String> imagePaths) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ValidationView(imagePaths: imagePaths),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    try {
      final image = await _cameraController!.takePicture();
      _navigateToValidationScreen([image.path]);
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        if (mounted) {
          await _navigateToValidationScreen([result.files.single.path!]);
        }
      }
    } catch (e) {
      print('Erreur lors de la sélection de fichier: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Prendre un justificatif'),
        backgroundColor: Colors.black.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistiques',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StatisticsView())),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HistoryView())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsView())),
          ),
        ],
      ),
      body: _buildCameraPreview(),
    );
  }

  Widget _buildCameraPreview() {
    if (_isCameraInitialized && _cameraController != null) {
      final controller = _cameraController!;
      final mediaSize = MediaQuery.of(context).size;
      final scale = 1 / (controller.value.aspectRatio * mediaSize.aspectRatio);

      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            clipper: _MediaSizeClipper(mediaSize),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: CameraPreview(controller),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40.0),
              color: Colors.black.withOpacity(0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.photo_library, color: Colors.white, size: 36),
                  ),
                  FloatingActionButton.large(
                    onPressed: _takePicture,
                    child: const Icon(Icons.camera_alt),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
}