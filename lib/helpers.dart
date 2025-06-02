import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:flutter/material.dart';
// Helper to write the PNG bytes to a temporary file (required for fromFilePath)
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<InputImage?> getCroppedImage(File image, Rect cropRect) async {
  debugPrint(image.path);

  if (!await File(image.path).exists()) {
    debugPrint("❌ File does not exist: ${image.path}");
    return null;
  }

  final imageDir = await getCroppedPath();
  final imagePath =
      '${imageDir}/cropped_${DateTime.now().millisecondsSinceEpoch}.png';
  final x = cropRect.left.toInt(),
      width = (cropRect.right.toInt() - cropRect.left.toInt()),
      y = cropRect.top.toInt(),
      height = (cropRect.bottom.toInt() - cropRect.top.toInt());

  debugPrint('$x $y {$width}x{$height}');
  final cmd = img.Command()
    ..decodeImageFile(image.path)
    ..copyResize(width: 1000, maintainAspect: true)
    // NOTE this is broken!!
    ..copyCrop(
      x: x,
      y: y,
      width: width,
      height: height,
      radius: 0,
      antialias: false,
    )
    ..encodePngFile(imagePath);

  await cmd.executeThread();

  debugPrint('Rect: $cropRect');
  debugPrint('path: $imagePath');

  // Create InputImage directly from bytes (ML Kit will auto-handle decoding PNG)
  // final imagePath = await getCroppedPath(croppedImage);

  final InputImage inputImage = InputImage.fromFilePath(imagePath);
  return inputImage;
}

Future<String?> getCroppedPath() async {
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
  return downloadsDir!.path;
}
