import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:notes_de_frais/views/history_view.dart';
import 'package:notes_de_frais/views/processing_view.dart';
import 'package:notes_de_frais/views/statistics_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notes_de_frais/views/settings_view.dart';
import 'package:badges/badges.dart' as badges;

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = false;
  final List<String> _capturedImagePaths = [];

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
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      if (!_isCameraInitialized) _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitializing) return;
    setState(() => _isCameraInitializing = true);

    var status = await Permission.camera.status;
    if (!status.isGranted) status = await Permission.camera.request();

    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);
        try {
          await _cameraController!.initialize();
          if (mounted) setState(() => _isCameraInitialized = true);
        } catch (e) {
          print('Erreur initialisation caméra: $e');
        }
      }
    }
    if (mounted) setState(() => _isCameraInitializing = false);
  }

  void _navigateToProcessingView() {
    if (_capturedImagePaths.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProcessingView(imagePaths: _capturedImagePaths),
      ),
    ).then((_) {
      _capturedImagePaths.clear();
      setState(() {});
    });
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    try {
      final image = await _cameraController!.takePicture();
      setState(() => _capturedImagePaths.add(image.path));
    } catch (e) {
      print('Erreur prise de photo: $e');
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
        setState(() => _capturedImagePaths.addAll(result.paths.whereType<String>()));
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
          IconButton(icon: const Icon(Icons.bar_chart), tooltip: 'Statistiques', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StatisticsView()))),
          IconButton(icon: const Icon(Icons.history), tooltip: 'Historique', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HistoryView()))),
          IconButton(icon: const Icon(Icons.settings), tooltip: 'Paramètres', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsView()))),
        ],
      ),
      body: _buildCameraPreview(),
    );
  }

  Widget _buildCameraPreview() {
    if (_isCameraInitialized && _cameraController != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(child: CameraPreview(_cameraController!)),
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