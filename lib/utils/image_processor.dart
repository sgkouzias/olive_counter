import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class PreprocessedImage {
  final Float32List data;
  final int originalWidth;
  final int originalHeight;

  PreprocessedImage({
    required this.data,
    required this.originalWidth,
    required this.originalHeight,
  });
}

class ImageProcessor {
  /// Preprocess image for YOLO ONNX model
  /// - Resize to target dimensions
  /// - Convert to RGB
  /// - Normalize pixel values to [0, 1]
  /// - Convert to CHW format (channels first)
  static Future<PreprocessedImage> preprocessImage(
    String imagePath,
    int targetWidth,
    int targetHeight,
  ) async {
    // Read image file
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final originalWidth = image.width;
    final originalHeight = image.height;

    // Resize image using letterbox (maintain aspect ratio)
    image = _letterboxResize(image, targetWidth, targetHeight);

    // Convert to Float32List in CHW format
    final data = _imageToFloat32List(image, targetWidth, targetHeight);

    return PreprocessedImage(
      data: data,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
    );
  }

  /// Resize image with letterbox (padding to maintain aspect ratio)
  static img.Image _letterboxResize(
    img.Image image,
    int targetWidth,
    int targetHeight,
  ) {
    final aspectRatio = image.width / image.height;
    final targetAspectRatio = targetWidth / targetHeight;

    int newWidth, newHeight;

    if (aspectRatio > targetAspectRatio) {
      // Image is wider
      newWidth = targetWidth;
      newHeight = (targetWidth / aspectRatio).round();
    } else {
      // Image is taller or square
      newHeight = targetHeight;
      newWidth = (targetHeight * aspectRatio).round();
    }

    // Resize image
    final resized = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    // Create padded image
    final padded = img.Image(width: targetWidth, height: targetHeight);
    img.fill(padded, color: img.ColorRgb8(114, 114, 114)); // Gray padding

    // Calculate padding offsets (center the image)
    final offsetX = (targetWidth - newWidth) ~/ 2;
    final offsetY = (targetHeight - newHeight) ~/ 2;

    // Composite resized image onto padded canvas
    img.compositeImage(padded, resized, dstX: offsetX, dstY: offsetY);

    return padded;
  }

  /// Convert image to Float32List in CHW format with normalization
  static Float32List _imageToFloat32List(
    img.Image image,
    int width,
    int height,
  ) {
    final data = Float32List(3 * width * height);

    int pixelIndex = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);

        // Extract RGB values
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        // Normalize to [0, 1] and arrange in CHW format
        data[pixelIndex] = r / 255.0; // R channel
        data[width * height + pixelIndex] = g / 255.0; // G channel
        data[2 * width * height + pixelIndex] = b / 255.0; // B channel

        pixelIndex++;
      }
    }

    return data;
  }
}
