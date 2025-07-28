import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_de_frais/providers/providers.dart';
import 'package:notes_de_frais/services/camera_service.dart';
import 'package:notes_de_frais/views/history_view.dart';
import 'package:notes_de_frais/views/processing_view.dart';
import 'package:notes_de_frais/views/statistics_view.dart';
import 'package:notes_de_frais/views/settings_view.dart';
import 'package:badges/badges.dart' as badges;
import 'package:notes_de_frais/widgets/animated_icon_button.dart';

class CameraView extends ConsumerStatefulWidget {
  const CameraView({super.key});

  @override
  ConsumerState<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<CameraView>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final List<String> _capturedImagePaths = [];
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitializing) return;

    _isInitializing = true;
    try {
      await _cameraService.initializeCamera();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Erreur lors de l'initialisation de la caméra: $e");
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _resetCamera() async {
    if (_isInitializing) return;

    _isInitializing = true;
    try {
      await _cameraService.resetCamera();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Erreur lors de la réinitialisation de la caméra: $e");
    } finally {
      _isInitializing = false;
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
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Disposer de la caméra quand l'app passe en arrière-plan
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Réinitialiser la caméra quand l'app revient au premier plan
      if (!_cameraService.isCameraInitialized && !_isInitializing) {
        _initialize();
      }
      ref.invalidate(unsentExpensesCountProvider);
    }
  }

  void _navigateToProcessingView() {
    if (_capturedImagePaths.isEmpty) return;
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) =>
            ProcessingView(imagePaths: List.from(_capturedImagePaths)),
      ),
    )
        .then((_) {
      if (mounted) {
        setState(() {
          _capturedImagePaths.clear();
        });
      }
    });
  }

  Future<void> _takePicture() async {
    if (!_cameraService.isCameraInitialized ||
        _cameraService.cameraController == null) {
      print("Caméra non initialisée, impossible de prendre une photo");
      return;
    }

    try {
      final imageFile = await _cameraService.takePicture();
      if (imageFile != null && mounted) {
        setState(() {
          _capturedImagePaths.add(imageFile.path);
        });
      }
    } catch (e) {
      print("Erreur lors de la prise de photo: $e");
      // Optionnel : afficher un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Erreur lors de la prise de photo. Veuillez réessayer.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
      appBar: const _CameraAppBar(),
      body: _buildCameraBody(),
    );
  }

  Widget _buildCameraBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initialisation de la caméra...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_cameraService.isCameraInitialized &&
        _cameraService.cameraController != null &&
        _cameraService.cameraController!.value.isInitialized) {
      final cameraController = _cameraService.cameraController!;
      final scale = 1 /
          (cameraController.value.aspectRatio *
              MediaQuery.of(context).size.aspectRatio);
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            clipper: _MediaSizeClipper(MediaQuery.of(context).size),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: CameraPreview(cameraController),
            ),
          ),
          _BottomControls(
            onPickFiles: _pickFiles,
            onTakePicture: _takePicture,
            capturedImagePaths: _capturedImagePaths,
            onSend: _navigateToProcessingView,
          ),
          if (_capturedImagePaths.isNotEmpty)
            Positioned(
              bottom: 130,
              left: 20,
              child: FloatingActionButton.small(
                onPressed: _removeLastPicture,
                backgroundColor: Colors.red,
                heroTag: 'undo_picture',
                child: const Icon(Icons.undo),
              ),
            ),
        ],
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Caméra non disponible',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vérifiez les permissions de caméra',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetCamera,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
  }
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}

// Widget extrait pour optimiser les reconstructions
class _CameraAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _CameraAppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unsentCount = ref.watch(unsentExpensesCountProvider);
    return AppBar(
      title: const Text('Prendre un justificatif'),
      backgroundColor: Colors.black.withOpacity(0.5),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        _AppBarAction(
            icon: Icons.bar_chart,
            tooltip: 'Statistiques',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const StatisticsView()))),
        _AppBarAction(
          tooltip: 'Historique',
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HistoryView())),
          child: badges.Badge(
            showBadge: unsentCount > 0,
            badgeContent: Text('$unsentCount',
                style: const TextStyle(color: Colors.white)),
            position: badges.BadgePosition.topEnd(top: -8, end: -5),
            child: const Icon(Icons.history),
          ),
        ),
        _AppBarAction(
            icon: Icons.settings,
            tooltip: 'Paramètres',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsView()))),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Widget extrait pour optimiser les reconstructions
class _BottomControls extends StatelessWidget {
  final VoidCallback onPickFiles;
  final VoidCallback onTakePicture;
  final VoidCallback onSend;
  final List<String> capturedImagePaths;

  const _BottomControls({
    required this.onPickFiles,
    required this.onTakePicture,
    required this.onSend,
    required this.capturedImagePaths,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        color: Colors.black.withOpacity(0.4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomControlButton(
                onPressed: onPickFiles, icon: Icons.photo_library),
            _TakePictureButton(onTap: onTakePicture),
            badges.Badge(
              showBadge: capturedImagePaths.isNotEmpty,
              position: badges.BadgePosition.topEnd(top: -12, end: -12),
              badgeContent: Text('${capturedImagePaths.length}',
                  style: const TextStyle(color: Colors.white)),
              child: _BottomControlButton(
                onPressed: capturedImagePaths.isNotEmpty ? onSend : null,
                icon: Icons.send,
                color:
                    capturedImagePaths.isNotEmpty ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData? icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget? child;

  const _AppBarAction(
      {this.icon, required this.tooltip, required this.onPressed, this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AnimatedIconButton(
        icon: icon,
        tooltip: tooltip,
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

class _BottomControlButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color color;

  const _BottomControlButton(
      {required this.onPressed, required this.icon, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 36),
    );
  }
}

class _TakePictureButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TakePictureButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
      ),
    );
  }
}
