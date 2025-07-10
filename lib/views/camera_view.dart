import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:notes_de_frais/services/camera_service.dart';
import 'package:notes_de_frais/views/history_view.dart';
import 'package:notes_de_frais/views/processing_view.dart';
import 'package:notes_de_frais/views/statistics_view.dart';
import 'package:notes_de_frais/views/settings_view.dart';
import 'package:badges/badges.dart' as badges;
import 'package:notes_de_frais/widgets/animated_icon_button.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final List<String> _capturedImagePaths = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    await _cameraService.initializeCamera();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (!_cameraService.isCameraInitialized) {
        _initialize();
      }
    }
  }

  void _navigateToProcessingView() {
    if (_capturedImagePaths.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProcessingView(imagePaths: _capturedImagePaths),
      ),
    ).then((_) {
      if(mounted) {
        setState(() {
          _capturedImagePaths.clear();
        });
      }
    });
  }

  Future<void> _takePicture() async {
    final imageFile = await _cameraService.takePicture();
    if (imageFile != null) {
      setState(() {
        _capturedImagePaths.add(imageFile.path);
      });
    }
  }

  void _removeLastPicture() {
    if (_capturedImagePaths.isNotEmpty) {
      setState(() {
        _capturedImagePaths.removeLast();
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
      );
      if (result != null) {
        setState(() {
          _capturedImagePaths.addAll(result.paths.whereType<String>());
        });
      }
    } catch (e) {
      print('Erreur sélection de fichier: $e');
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AnimatedIconButton(icon: Icons.bar_chart, tooltip: 'Statistiques', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StatisticsView()))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AnimatedIconButton(icon: Icons.history, tooltip: 'Historique', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HistoryView()))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AnimatedIconButton(icon: Icons.settings, tooltip: 'Paramètres', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsView()))),
          ),
        ],
      ),
      body: _buildCameraPreview(),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraService.isCameraInitialized && _cameraService.cameraController != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(child: CameraPreview(_cameraService.cameraController!)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              color: Colors.black.withOpacity(0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: _pickFiles, icon: const Icon(Icons.photo_library, color: Colors.white, size: 36)),
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                    ),
                  ),
                  badges.Badge(
                    showBadge: _capturedImagePaths.isNotEmpty,
                    position: badges.BadgePosition.topEnd(top: -12, end: -12),
                    badgeContent: Text('${_capturedImagePaths.length}', style: const TextStyle(color: Colors.white)),
                    child: IconButton(
                      onPressed: _capturedImagePaths.isNotEmpty ? _navigateToProcessingView : null,
                      icon: Icon(Icons.send, color: _capturedImagePaths.isNotEmpty ? Colors.white : Colors.grey, size: 36),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_capturedImagePaths.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 20,
              child: FloatingActionButton.small(
                onPressed: _removeLastPicture,
                backgroundColor: Colors.red,
                child: const Icon(Icons.undo),
              ),
            ),
        ],
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}