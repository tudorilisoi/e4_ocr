import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:flutter/material.dart';
// Helper to write the PNG bytes to a temporary file (required for fromFilePath)
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<InputImage?> getInputImageFromRepaintBoundary(
  GlobalKey repaintBoundaryKey,
  Rect cropRect,
) async {
  // try {
  // Get the render object from the key
  final boundary =
      repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

  // Capture the widget as an image
  final ui.Image uiImage = boundary!.toImageSync(pixelRatio: 1.0);
  final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  // Decode the bytes into an image.Image
  final imageImage = img.decodeImage(bytes);
  debugPrint(imageImage!.data.toString());
  final croppedImage = img.copyCrop(
    imageImage!,
    x: cropRect.left.toInt(),
    width: (cropRect.right.toInt() - cropRect.left.toInt()),
    y: cropRect.top.toInt(),
    height: (cropRect.bottom.toInt() - cropRect.top.toInt()),
  );
  debugPrint('Rect: $cropRect');

  // Create InputImage directly from bytes (ML Kit will auto-handle decoding PNG)
  // final imagePath = await _savePngToTempFile(croppedImage);
  final imagePath = await _savePngToTempFile(imageImage);

  final InputImage inputImage = InputImage.fromFilePath(imagePath!);
  return inputImage;
  // } catch (e) {
  //   debugPrint('$cropRect');
  //   debugPrint('Error generating InputImage: $e');
  //   rethrow;
  //   // return null;
  // }
}

Future<String?> _savePngToTempFile(img.Image image) async {
  // final tempDir = await getTemporaryDirectory();
  Directory? downloadsDir;
  if (Platform.isAndroid) {
    downloadsDir = Directory('/storage/emulated/0/Download');
  } else if (Platform.isIOS) {
    // iOS doesn't allow direct access to Downloads; fallback to temp dir
    downloadsDir = await getApplicationDocumentsDirectory();
  } else {
    downloadsDir = await getDownloadsDirectory();
  }

  // if (downloadsDir?.path == null) {
  //   throw Exception("No download dir");
  // }

  final bytes = img.encodePng(image);
  await img.writeFile(
    '${downloadsDir!.path}/repaint_image_${DateTime.now().millisecondsSinceEpoch}.png',
    bytes,
  );
  return downloadsDir.path;
}
