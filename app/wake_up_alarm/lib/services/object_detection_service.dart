import 'dart:io';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
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
  late final ObjectDetector _detector;
  bool _isInitialized = false;

  // Broad ML Kit category mapping
  static const Map<String, List<String>> _labelMap = {
    'bottle': ['bottle', 'drink', 'food and drink', 'beverage'],
    'cup': ['cup', 'drink', 'food and drink', 'beverage', 'home good'],
    'book': ['book', 'home good', 'paper'],
    'laptop': ['laptop', 'computer', 'electronic', 'home good'],
    'plant': ['plant', 'tree', 'flower', 'home good'],
    'chair': ['chair', 'furniture', 'home good', 'seat'], // ← home good
    'footwear': [
      'shoe',
      'footwear',
      'fashion good',
      'clothing'
    ], // ← fashion good
    'glasses': [
      'glasses',
      'eyewear',
      'fashion good',
      'optical'
    ], // ← fashion good
    'bag': ['bag', 'fashion good', 'clothing', 'accessory'],
    'pen': ['pen', 'pencil', 'home good', 'stationery'],
    'watch': ['watch', 'fashion good', 'accessory', 'jewelry'],
    'pillow': ['pillow', 'home good', 'furniture', 'textile'],
  };

  Future<void> init() async {
    if (_isInitialized) return;
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );
    _detector = ObjectDetector(options: options);
    _isInitialized = true;
  }

  Future<DetectionResult> detectFromFile(
    File imageFile,
    String targetMlLabel,
  ) async {
    if (!_isInitialized) await init();

    final inputImage = InputImage.fromFile(imageFile);
    final objects = await _detector.processImage(inputImage);

    final allLabels = <String>[];
    String bestMatchLabel = '';
    double bestMatchConfidence = 0.0;

    // Get all accepted labels for this target
    final acceptedLabels =
        _labelMap[targetMlLabel.toLowerCase()] ?? [targetMlLabel.toLowerCase()];

    for (final obj in objects) {
      for (final label in obj.labels) {
        final lowerLabel = label.text.toLowerCase();
        allLabels.add(lowerLabel);

        // Check if detected label matches any accepted label for this item
        final isMatch = acceptedLabels.any((accepted) =>
            lowerLabel.contains(accepted) || accepted.contains(lowerLabel));

        if (isMatch && label.confidence > bestMatchConfidence) {
          bestMatchConfidence = label.confidence;
          bestMatchLabel = label.text;
        }
      }
    }

    final matched =
        bestMatchConfidence >= AppConstants.detectionConfidenceThreshold;

    return DetectionResult(
      matched: matched,
      detectedLabel: bestMatchLabel.isEmpty
          ? (allLabels.isNotEmpty ? allLabels.first : 'nothing')
          : bestMatchLabel,
      confidence: bestMatchConfidence,
      allDetected: allLabels,
    );
  }

  void dispose() {
    if (_isInitialized) {
      _detector.close();
      _isInitialized = false;
    }
  }
}
