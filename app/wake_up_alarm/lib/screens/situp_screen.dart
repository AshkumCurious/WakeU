import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/alarm_scheduler_service.dart';
import '../services/alarm_storage_service.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

enum _SitupPhase { unknown, down }

class SitupScreen extends StatefulWidget {
  final int alarmId;
  final int targetCount;

  const SitupScreen({
    super.key,
    required this.alarmId,
    required this.targetCount,
  });

  @override
  State<SitupScreen> createState() => _SitupScreenState();
}

class _SitupScreenState extends State<SitupScreen> {
  final _storage = AlarmStorageService();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _cameraReady = false;

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.accurate,
      // We process static images (camera takePicture), so single is fine.
      mode: PoseDetectionMode.single,
    ),
  );

  bool _isCapturing = false;
  Timer? _loopTimer;
  String? _errorMessage;

  int _reps = 0;
  _SitupPhase _phase = _SitupPhase.unknown;

  // Adaptive thresholds for a standing "bend knees -> sit on hips -> stand" motion.
  // We use hip/knee vertical position as a proxy for "down" vs "up".
  static const double _minAngleRangeForReliableCounting = 0.04;
  static const double _downThresholdFraction = 0.60; // larger y == lower (bent)
  static const double _upThresholdFraction = 0.35; // smaller y == standing
  static const Duration _minTimeBetweenReps = Duration(milliseconds: 650);
  DateTime? _lastRepTime;
  double? _minAngle;
  double? _maxAngle;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _controller?.dispose();
    _poseDetector.close();
    super.dispose();
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

      // Prefer the front camera so the pose model can see your torso.
      CameraDescription? selected;
      for (final cam in _cameras!) {
        if (cam.lensDirection == CameraLensDirection.front) {
          selected = cam;
          break;
        }
      }
      selected ??= _cameras!.first;

      _controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);

      // Give the camera preview a short moment to stabilize.
      _loopTimer?.cancel();
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _loopTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        _captureAndDetect();
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to start camera: $e');
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

  Future<void> _captureAndDetect() async {
    if (_isCapturing || !_cameraReady || _controller == null) return;
    if (_reps >= widget.targetCount) return;

    _isCapturing = true;
    try {
      final xFile = await _controller!.takePicture();
      final imageFile = File(xFile.path);
      final result = await _poseDetector.processImage(
        InputImage.fromFile(imageFile),
      );

      // Clean up temp file as early as possible.
      try {
        await imageFile.delete();
      } catch (_) {
        // Ignore cleanup errors.
      }

      final pose = result.isNotEmpty ? result.first : null;
      final hipScore = pose == null ? null : _computeHipScoreForPose(pose);

      if (hipScore == null) {
        setState(() => _errorMessage = 'Make sure your hips and knees are visible');
        return;
      }

      final repCounted = _updateSitupCounter(hipScore);
      if (!mounted) return;

      if (repCounted) {
        // Stop loop once target reached.
        if (_reps >= widget.targetCount) {
          _loopTimer?.cancel();
          await _dismissAlarm();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          return;
        }
      }

      // Clear transient error when we get a valid pose.
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      } else if (repCounted) {
        setState(() {});
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Try again with better lighting';
      });
    } finally {
      _isCapturing = false;
    }
  }

  double? _computeHipScoreForPose(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    // If any of the keypoints are missing or low-confidence, ignore the frame.
    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null) {
      return null;
    }

    const minLikelihood = 0.35;
    final ok = leftHip.likelihood >= minLikelihood &&
        rightHip.likelihood >= minLikelihood &&
        leftKnee.likelihood >= minLikelihood &&
        rightKnee.likelihood >= minLikelihood;
    if (!ok) return null;

    final hipY = (leftHip.y + rightHip.y) / 2.0;
    final kneeY = (leftKnee.y + rightKnee.y) / 2.0;

    // Score increases when you bend/sit (hips/knees go down in the frame).
    return (hipY + kneeY) / 2.0;
  }

  bool _updateSitupCounter(double hipScore) {
    final now = DateTime.now();

    final hasRepCooldown =
        _lastRepTime == null || now.difference(_lastRepTime!) > _minTimeBetweenReps;

    // Track min/max adaptively for the current session.
    _minAngle = _minAngle == null ? hipScore : min(_minAngle!, hipScore);
    _maxAngle = _maxAngle == null ? hipScore : max(_maxAngle!, hipScore);

    final minA = _minAngle!;
    final maxA = _maxAngle!;
    final range = maxA - minA;

    // Not enough movement yet, wait until we see a meaningful range.
    if (range < _minAngleRangeForReliableCounting) {
      return false;
    }

    final downThreshold = minA + range * _downThresholdFraction;
    final upThreshold = minA + range * _upThresholdFraction;

    if (hipScore >= downThreshold) {
      _phase = _SitupPhase.down;
      return false;
    }

    if (hipScore <= upThreshold &&
        _phase == _SitupPhase.down &&
        hasRepCooldown) {
      _phase = _SitupPhase.unknown;
      _lastRepTime = now;
      _reps++;
      setState(() {});
      return true;
    }

    return false;
  }

  Future<void> _stopAlarmAndExit() async {
    _loopTimer?.cancel();
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
            _buildTopOverlay(),
            _buildBottomOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    final done = _reps.clamp(0, widget.targetCount);
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
            const Text(
              'BEND KNEES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.danger,
                letterSpacing: 3,
              ),
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
                  const Icon(Icons.sports_gymnastics_rounded, size: 34, color: AppTheme.accentSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$done / ${widget.targetCount}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Bend down, sit on hips, then stand',
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
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    final canStop = _reps >= widget.targetCount;

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
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.45)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            if (!canStop)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Keep going... camera counting reps',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canStop ? _stopAlarmAndExit : null,
                icon: const Icon(Icons.alarm_off_rounded, size: 20),
                label: Text(canStop ? 'ALARM OFF' : 'Counting reps...'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor: AppTheme.danger.withOpacity(0.3),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
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
                child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 3),
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
            const Text(
              'Looking for sit-up motion',
              style: TextStyle(fontSize: 14, color: Colors.white60),
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
            const Icon(Icons.sports_gymnastics_rounded, color: AppTheme.textMuted, size: 64),
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

