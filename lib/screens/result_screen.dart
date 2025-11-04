import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/tflite_service.dart';
import '../models/detection.dart';
import '../utils/detection_painter.dart';
import 'package:image/image.dart' as img;

class ResultScreen extends StatefulWidget {
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<Detection>? _detections;
  bool _isProcessing = true;
  img.Image? _processedImage;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      final tfliteService = Provider.of<TfliteService>(context, listen: false);

      // Run inference
      final detections = await tfliteService.detectObjects(widget.imagePath);

      // Load image for dimensions
      final bytes = await File(widget.imagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (!mounted) return;

      setState(() {
        _detections = detections;
        _processedImage = image;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection Results'), centerTitle: true),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Image with bounding boxes
                  if (_processedImage != null && _detections != null)
                    AspectRatio(
                      aspectRatio:
                          _processedImage!.width / _processedImage!.height,
                      child: CustomPaint(
                        painter: DetectionPainter(
                          imageFile: File(widget.imagePath),
                          detections: _detections!,
                        ),
                        child: Container(),
                      ),
                    )
                  else
                    Image.file(File(widget.imagePath)),
                  const SizedBox(height: 20),
                  // Results summary
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Total Olives Detected: ${_detections?.length ?? 0}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_detections != null && _detections!.isNotEmpty)
                            ..._detections!.asMap().entries.map((entry) {
                              final index = entry.key + 1;
                              final detection = entry.value;

                              return ListTile(
                                leading: CircleAvatar(child: Text('$index')),
                                title: Text('Olive #$index'),
                                subtitle: Text(
                                  'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                                ),
                              );
                            })
                          else
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No olives detected in this image',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
