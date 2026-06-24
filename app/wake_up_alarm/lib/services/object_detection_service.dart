import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../utils/app_theme.dart';

class DetectionResult {
  final bool matched;
  final String detectedLabel;
  final double confidence;
  final List<String> allDetected;

  const DetectionResult({
    required this.matched,
    required this.detectedLabel,
    required this.confidence,
    required this.allDetected,
  });
}

class ObjectDetectionService {
  late final ImageLabeler _labeler;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _labeler = ImageLabeler(
      options: ImageLabelerOptions(
        confidenceThreshold: AppConstants.detectionConfidenceThreshold,
      ),
    );
    _isInitialized = true;
  }

  Future<DetectionResult> detectFromFile(
    File imageFile,
    List<String> targetLabels,
  ) async {
    if (!_isInitialized) await init();

    final inputImage = InputImage.fromFile(imageFile);
    final labels = await _labeler.processImage(inputImage);

    final allDetected = labels
        .map((l) => '${l.label} (${(l.confidence * 100).toStringAsFixed(0)}%)')
        .toList();

    final targets = targetLabels.map((l) => l.toLowerCase()).toList();
    for (final label in labels) {
      if (label.confidence < AppConstants.detectionConfidenceThreshold) {
        continue;
      }
      final detected = label.label.toLowerCase();
      for (final target in targets) {
        if (_labelsMatch(detected, target)) {
          return DetectionResult(
            matched: true,
            detectedLabel: label.label,
            confidence: label.confidence,
            allDetected: allDetected,
          );
        }
      }
    }

    return DetectionResult(
      matched: false,
      detectedLabel: labels.isNotEmpty ? labels.first.label : 'nothing',
      confidence: labels.isNotEmpty ? labels.first.confidence : 0,
      allDetected: allDetected,
    );
  }

  bool _labelsMatch(String detected, String target) {
    if (detected == target) return true;
    final detectedWords = detected.split(RegExp(r'[\s,_-]+'));
    final targetWords = target.split(RegExp(r'[\s,_-]+'));
    return detectedWords.any((w) => w == target) ||
        targetWords.any((w) => w == detected);
  }

  void dispose() {
    if (_isInitialized) {
      _labeler.close();
      _isInitialized = false;
    }
  }
}
