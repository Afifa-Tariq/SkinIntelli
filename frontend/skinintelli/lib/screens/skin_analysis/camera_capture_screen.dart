part of 'package:skinintelli/main.dart';

class _CameraCaptureResult {
  const _CameraCaptureResult({required this.path, required this.isFrontCamera});

  final String path;
  final bool isFrontCamera;
}

class _CameraCaptureScreen extends StatefulWidget {
  const _CameraCaptureScreen({this.preferFront = true});

  final bool preferFront;

  @override
  State<_CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<_CameraCaptureScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isReady = false;
  bool _isCapturing = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() => _initError = 'No camera was found on this device.');
        return;
      }

      final frontIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      final startIndex =
          widget.preferFront && frontIndex != -1 ? frontIndex : 0;

      _cameras = cameras;
      await _startController(startIndex);
    } catch (e) {
      if (mounted) {
        setState(
          () => _initError = 'Unable to access the camera. Please allow '
              'camera access in your device settings.',
        );
      }
    }
  }

  Future<void> _startController(int index) async {
    final previous = _controller;
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
    } catch (e) {
      await controller.dispose();
      if (mounted) {
        setState(
          () => _initError = 'Unable to start the camera. Please allow '
              'camera access in your device settings.',
        );
      }
      return;
    }

    await previous?.dispose();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _selectedCameraIndex = index;
      _isReady = true;
      _initError = null;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || !_isReady) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _isReady = false);
    await _startController(nextIndex);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(
        _CameraCaptureResult(
          path: file.path,
          isFrontCamera:
              _cameras[_selectedCameraIndex].lensDirection ==
                  CameraLensDirection.front,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _initError = 'Failed to capture the photo. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isReady && _controller != null)
              Center(child: CameraPreview(_controller!))
            else if (_initError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _initError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: const Text('Go back'),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (_cameras.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.cameraswitch_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _isReady ? _switchCamera : null,
                ),
              ),
            if (_isReady)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _isCapturing ? null : _capture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: AppTheme.primary, width: 4),
                      ),
                      child: _isCapturing
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppTheme.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
