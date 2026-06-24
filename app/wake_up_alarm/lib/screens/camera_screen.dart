// lib/screens/camera_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/alarm_storage_service.dart';
import '../services/item_selector_service.dart';
import '../services/object_detection_service.dart';
import '../services/alarm_scheduler_service.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  final int alarmId;
  final SelectedItem targetItem;

  const CameraScreen({
    super.key,
    required this.alarmId,
    required this.targetItem,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final _storage = AlarmStorageService();
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final _detector = ObjectDetectionService();
  bool _isCapturing = false;
  bool _isDetecting = false;
  bool _cameraReady = false;
  int _attempts = 0;
  int _minAttemptsBeforeSkip = AppConstants.defaultMinAttemptsBeforeSkip;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detector.init();
    _loadAlarmSettings();
    _initCamera();
  }

  Future<void> _loadAlarmSettings() async {
    final alarm = await _storage.getAlarmById(widget.alarmId);
    if (!mounted || alarm == null) return;
    setState(() => _minAttemptsBeforeSkip = alarm.minAttemptsBeforeSkip);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _detector.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _dismissAlarm() async {
    final alarm = await _storage.getAlarmById(widget.alarmId);
    if (alarm != null) {
      await AlarmSchedulerService.handleAlarmDismissed(alarm);
    } else {
      await AlarmSchedulerService.cancelAlarm(widget.alarmId);
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _errorMessage = 'Camera permission required');
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _errorMessage = 'No camera available');
        return;
      }

      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to start camera: $e');
    }
  }

  Future<void> _captureAndDetect() async {
    if (_isCapturing || _isDetecting || !_cameraReady) return;

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      final xFile = await _controller!.takePicture();
      final imageFile = File(xFile.path);

      setState(() {
        _isCapturing = false;
        _isDetecting = true;
      });

      final result = await _detector.detectFromFile(
        imageFile,
        widget.targetItem.matchLabels,
      );

      _attempts++;

      if (result.matched) {
        await _dismissAlarm();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => ResultScreen(
                success: true,
                targetItem: widget.targetItem,
                detectedLabel: result.detectedLabel,
                confidence: result.confidence,
              ),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(
                opacity: anim,
                child: child,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isDetecting = false;
          _errorMessage = result.allDetected.isEmpty
              ? 'Could not detect any object. Try again!'
              : 'Detected: ${result.allDetected.take(3).join(", ")}. Not a match!';
        });
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _isDetecting = false;
        _errorMessage = 'Detection failed. Please try again.';
      });
    }
  }

  Future<void> _skipAlarm() async {
    await _dismissAlarm();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (_cameraReady && _controller != null)
              Positioned.fill(child: CameraPreview(_controller!))
            else if (_errorMessage != null && !_cameraReady)
              _buildErrorState()
            else
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),

            if (_cameraReady) _buildViewfinder(),

            _buildTopOverlay(),
            _buildBottomOverlay(),

            if (_isDetecting) _buildDetectingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ViewfinderPainter(),
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    final remaining = _minAttemptsBeforeSkip - _attempts;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 16,
          20,
          16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.85), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'FIND THIS OBJECT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.danger,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                if (_attempts > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppTheme.danger.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Attempt $_attempts',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Text(
                    widget.targetItem.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.targetItem.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Fill the frame with the object',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_attempts < _minAttemptsBeforeSkip) ...[
              const SizedBox(height: 10),
              Text(
                '$remaining ${remaining == 1 ? 'try' : 'tries'} before skip',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
            if (_attempts >= _minAttemptsBeforeSkip) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _skipAlarm,
                icon: const Icon(Icons.alarm_off_outlined, size: 18),
                label: const Text('Stop alarm anyway'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  backgroundColor: Colors.white12,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          30,
          24,
          30,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.92), Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.45)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            GestureDetector(
              onTap: _captureAndDetect,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isCapturing
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white,
                  border: Border.all(
                    color: AppTheme.accent.withOpacity(0.6),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.25),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: _isCapturing
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.black,
                        size: 34,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Center the object in the frame and tap',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accent, width: 2),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accent,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scanning...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looking for ${widget.targetItem.name}',
              style: const TextStyle(fontSize: 14, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: AppTheme.textMuted, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Camera unavailable',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = size.width * 0.78;
    final frameHeight = frameWidth * 0.85;
    final left = (size.width - frameWidth) / 2;
    final top = size.height * 0.28;

    final overlay = Paint()..color = Colors.black.withOpacity(0.45);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), overlay);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        top + frameHeight,
        size.width,
        size.height - top - frameHeight,
      ),
      overlay,
    );
    canvas.drawRect(Rect.fromLTWH(0, top, left, frameHeight), overlay);
    canvas.drawRect(
      Rect.fromLTWH(
        left + frameWidth,
        top,
        size.width - left - frameWidth,
        frameHeight,
      ),
      overlay,
    );

    final border = Paint()
      ..color = AppTheme.accent.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, frameWidth, frameHeight),
        const Radius.circular(16),
      ),
      border,
    );

    final corner = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 22.0;

    void drawCorner(Offset start, Offset hEnd, Offset vEnd) {
      canvas.drawLine(start, hEnd, corner);
      canvas.drawLine(start, vEnd, corner);
    }

    drawCorner(
      Offset(left, top),
      Offset(left + len, top),
      Offset(left, top + len),
    );
    drawCorner(
      Offset(left + frameWidth, top),
      Offset(left + frameWidth - len, top),
      Offset(left + frameWidth, top + len),
    );
    drawCorner(
      Offset(left, top + frameHeight),
      Offset(left + len, top + frameHeight),
      Offset(left, top + frameHeight - len),
    );
    drawCorner(
      Offset(left + frameWidth, top + frameHeight),
      Offset(left + frameWidth - len, top + frameHeight),
      Offset(left + frameWidth, top + frameHeight - len),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
