import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/detection.dart';

class TfliteService extends ChangeNotifier {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // Model configuration
  static const int inputWidth = 640;
  static const int inputHeight = 640;
  static const double confidenceThreshold = 0.25;
  static const double iouThreshold = 0.45;

  bool get isModelLoaded => _isModelLoaded;

  /// Load TFLite model from file system path
  Future<void> loadModel(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Model file not found at: $filePath');
      }

      debugPrint('Loading TFLite model from: $filePath');
      debugPrint('File size: ${await file.length()} bytes');

      // Create interpreter options
      final options = InterpreterOptions()..threads = 4;

      // Load model from file
      _interpreter = Interpreter.fromFile(file, options: options);

      _isModelLoaded = true;
      notifyListeners();

      debugPrint('TFLite model loaded successfully!');
      debugPrint(
        'Input tensor shape: ${_interpreter!.getInputTensor(0).shape}',
      );
      debugPrint(
        'Output tensor shape: ${_interpreter!.getOutputTensor(0).shape}',
      );

      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Error loading TFLite model: $e');
      _isModelLoaded = false;
      rethrow;
    }
  }

  /// Perform object detection on an image
  Future<List<Detection>> detectObjects(String imagePath) async {
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception(
        'Model not loaded. Please wait for model initialization.',
      );
    }

    try {
      // Read and preprocess image
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to model input size
      final resized = img.copyResize(
        image,
        width: inputWidth,
        height: inputHeight,
      );

      // Get original dimensions for scaling
      final originalWidth = image.width;
      final originalHeight = image.height;

      // Prepare input tensor
      final inputTensor = _preprocessImage(resized);

      // Prepare output tensor - allocate as a 3D list directly
      // Shape: [1, 5, 8400]
      final outputTensor = List.generate(
        1,
        (i) => List.generate(5, (j) => List.filled(8400, 0.0)),
      );

      // Run inference
      debugPrint('Running inference with input shape: [1, 3, 640, 640]');
      _interpreter!.run(inputTensor, outputTensor);

      debugPrint('Inference completed. Output shape: [1, 5, 8400]');

      // Parse output
      final detections = _parseYoloOutput(
        outputTensor,
        originalWidth,
        originalHeight,
      );

      // Apply NMS
      final filteredDetections = _applyNMS(detections, iouThreshold);

      debugPrint('Detected ${filteredDetections.length} objects after NMS');
      return filteredDetections;
    } catch (e) {
      debugPrint('Error during inference: $e');
      rethrow;
    }
  }

  /// Preprocess image to TFLite input format
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // Create 4D tensor: [batch=1, height=640, width=640, channels=3]
    final input = List.generate(
      1,
      (b) => List.generate(
        inputHeight,
        (y) => List.generate(
          inputWidth,
          (x) => List.generate(3, (c) {
            final pixel = image.getPixelSafe(x, y);
            // Normalize to 0-1 range
            if (c == 0) return pixel.r.toDouble() / 255.0; // R
            if (c == 1) return pixel.g.toDouble() / 255.0; // G
            return pixel.b.toDouble() / 255.0; // B
          }),
        ),
      ),
    );
    return input;
  }

  /// Parse YOLO output [1, 5, 8400] to detections
  /// For single-class model: 5 = [x, y, w, h, confidence]
  List<Detection> _parseYoloOutput(
    List<List<List<double>>> output,
    int originalWidth,
    int originalHeight,
  ) {
    List<Detection> detections = [];

    try {
      debugPrint('Parsing output with shape [1, 5, 8400]');

      final scaleX = originalWidth / inputWidth;
      final scaleY = originalHeight / inputHeight;

      debugPrint('Scale factors: scaleX=$scaleX, scaleY=$scaleY');

      // Iterate through all 8400 anchors
      for (int i = 0; i < 8400; i++) {
        // Extract values for this anchor from the 5 features
        final centerX = (output[0][0][i]) * scaleX; // x (row 0)
        final centerY = (output[0][1][i]) * scaleY; // y (row 1)
        final width = (output[0][2][i]) * scaleX; // w (row 2)
        final height = (output[0][3][i]) * scaleY; // h (row 3)
        final confidence = output[0][4][i]; // confidence (row 4)

        // Only process detections above threshold
        if (confidence >= confidenceThreshold) {
          // Convert from center format to corner format
          final x1 = centerX - width / 2;
          final y1 = centerY - height / 2;
          final x2 = centerX + width / 2;
          final y2 = centerY + height / 2;

          // Clamp coordinates to image boundaries and convert to double
          final clampedX1 = (x1.clamp(
            0.0,
            originalWidth.toDouble(),
          )).toDouble();
          final clampedY1 = (y1.clamp(
            0.0,
            originalHeight.toDouble(),
          )).toDouble();
          final clampedX2 = (x2.clamp(
            0.0,
            originalWidth.toDouble(),
          )).toDouble();
          final clampedY2 = (y2.clamp(
            0.0,
            originalHeight.toDouble(),
          )).toDouble();

          debugPrint(
            'Detection $i: x=$centerX, y=$centerY, w=$width, h=$height, conf=$confidence',
          );

          detections.add(
            Detection(
              bbox: BoundingBox(
                x1: clampedX1,
                y1: clampedY1,
                x2: clampedX2,
                y2: clampedY2,
              ),
              confidence: confidence,
              classId: 0, // Single class (olive)
              className: 'olive',
            ),
          );
        }
      }

      debugPrint('Parsed ${detections.length} detections before NMS');
    } catch (e) {
      debugPrint('Error parsing YOLO output: $e');
    }

    return detections;
  }

  /// Apply Non-Maximum Suppression
  List<Detection> _applyNMS(List<Detection> detections, double iouThreshold) {
    if (detections.isEmpty) return [];

    // Sort by confidence (descending)
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    List<Detection> keep = [];
    List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      keep.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        final iou = _calculateIoU(detections[i].bbox, detections[j].bbox);
        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    debugPrint('After NMS: ${keep.length} detections');
    return keep;
  }

  /// Calculate Intersection over Union (IoU)
  double _calculateIoU(BoundingBox box1, BoundingBox box2) {
    final x1 = box1.x1 > box2.x1 ? box1.x1 : box2.x1;
    final y1 = box1.y1 > box2.y1 ? box1.y1 : box2.y1;
    final x2 = box1.x2 < box2.x2 ? box1.x2 : box2.x2;
    final y2 = box1.y2 < box2.y2 ? box1.y2 : box2.y2;

    if (x2 < x1 || y2 < y1) return 0.0;

    final intersectionArea = (x2 - x1) * (y2 - y1);
    final box1Area = (box1.x2 - box1.x1) * (box1.y2 - box1.y1);
    final box2Area = (box2.x2 - box2.x1) * (box2.y2 - box2.y1);
    final unionArea = box1Area + box2Area - intersectionArea;

    return intersectionArea / unionArea;
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}
