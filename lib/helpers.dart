import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:flutter/material.dart';
// Helper to write the PNG bytes to a temporary file (required for fromFilePath)
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<InputImage?> getOCRTextFromImage(String path) async {
  debugPrint('path: ${path}');

  // Create InputImage directly from bytes (ML Kit will auto-handle decoding PNG)

  final InputImage inputImage = InputImage.fromFilePath(path);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognizedText = await textRecognizer.processImage(
    inputImage,
  );
  debugPrint(recognizedText.text);
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
