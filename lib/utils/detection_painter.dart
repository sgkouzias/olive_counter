import 'dart:io';
import 'package:flutter/material.dart';
import '../models/detection.dart';

class DetectionPainter extends CustomPainter {
  final File imageFile;
  final List<Detection> detections;

  DetectionPainter({required this.imageFile, required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw bounding boxes
    for (final detection in detections) {
      _drawBoundingBox(canvas, size, detection);
    }
  }

  void _drawBoundingBox(Canvas canvas, Size size, Detection detection) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final bbox = detection.bbox;
    final rect = Rect.fromLTRB(bbox.x1, bbox.y1, bbox.x2, bbox.y2);

    // Draw rectangle
    canvas.drawRect(rect, paint);

    // Draw label background
    final textSpan = TextSpan(
      text:
          '${detection.className} ${(detection.confidence * 100).toStringAsFixed(1)}%',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelRect = Rect.fromLTWH(
      bbox.x1,
      bbox.y1 - 20,
      textPainter.width + 8,
      20,
    );

    final labelPaint = Paint()..color = Colors.green;
    canvas.drawRect(labelRect, labelPaint);

    // Draw label text
    textPainter.paint(canvas, Offset(bbox.x1 + 4, bbox.y1 - 18));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
