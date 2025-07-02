import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notes_de_frais/views/validation_view.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isProcessingFile = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final firstCamera = cameras.first;
        _cameraController = CameraController(
          firstCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        _initializeControllerFuture = _cameraController!.initialize().then((_) {
          if (!mounted) return;
          setState(() => _isCameraInitialized = true);
        }).catchError((Object e) {
          if (e is CameraException) {
            print('Erreur caméra: ${e.code}\n${e.description}');
          }
        });
      }
    } else {
      print('Permission caméra refusée');
    }
  }

  Future<void> _navigateToValidationScreen(String imagePath) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ValidationView(imagePath: imagePath),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();
      _navigateToValidationScreen(image.path);
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _pickFile() async {
    setState(() => _isProcessingFile = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isProcessingFile = false);
        return;
      }

      String? filePath = result.files.single.path;

      if (filePath!.toLowerCase().endsWith('.pdf')) {
        final imagePath = await _convertPdfToImage(filePath);
        if (imagePath != null) {
          await _navigateToValidationScreen(imagePath);
        }
      } else {
        await _navigateToValidationScreen(filePath);
      }
    } catch (e) {
      print('Erreur lors de la sélection de fichier: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessingFile = false);
      }
    }
  }

  Future<String?> _convertPdfToImage(String pdfPath) async {
    try {
      final document = await PdfDocument.openFile(pdfPath);
      final page = await document.getPage(1);
      final pageImage = await page.render(width: page.width, height: page.height);
      await page.close();
      await document.close();

      if (pageImage == null) return null;

      final tempDir = await getTemporaryDirectory();
      final imageFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png');
      await imageFile.writeAsBytes(pageImage.bytes);

      return imageFile.path;
    } catch (e) {
      print("Erreur lors de la conversion du PDF: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildFullscreenPreview(),
    );
  }

  Widget _buildFullscreenPreview() {
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final mediaSize = MediaQuery.of(context).size;
    final scale = 1 / (_cameraController!.value.aspectRatio * mediaSize.aspectRatio);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          clipper: _MediaSizeClipper(mediaSize),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: CameraPreview(_cameraController!),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _isProcessingFile
                    ? const CircularProgressIndicator(color: Colors.white)
                    : IconButton(
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