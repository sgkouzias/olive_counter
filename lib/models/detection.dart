class Detection {
  final BoundingBox bbox;
  final double confidence;
  final int classId;
  final String className;

  Detection({
    required this.bbox,
    required this.confidence,
    required this.classId,
    required this.className,
  });

  @override
  String toString() {
    return 'Detection(class: $className, confidence: ${confidence.toStringAsFixed(2)}, bbox: $bbox)';
  }
}

class BoundingBox {
  final double x1; // Top-left x
  final double y1; // Top-left y
  final double x2; // Bottom-right x
  final double y2; // Bottom-right y

  BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  double get width => x2 - x1;
  double get height => y2 - y1;
  double get centerX => (x1 + x2) / 2;
  double get centerY => (y1 + y2) / 2;
  double get area => width * height;

  @override
  String toString() {
    return 'BoundingBox(x1: ${x1.toStringAsFixed(1)}, y1: ${y1.toStringAsFixed(1)}, '
        'x2: ${x2.toStringAsFixed(1)}, y2: ${y2.toStringAsFixed(1)})';
  }
}
