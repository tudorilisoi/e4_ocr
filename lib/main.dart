import 'dart:io';

import 'package:e4_ocr/helpers.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Crop OCR',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const ImagePickerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image OCR Cropper")),
      body: Center(
        child: _image == null
            ? ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text("Pick Image"),
              )
            : ImageCropScreen(image: _image!),
      ),
    );
  }
}

class ImageCropScreen extends StatefulWidget {
  final File image;
  const ImageCropScreen({super.key, required this.image});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  bool _showCropOverlay = true;
  String _recognizedText = "";
  final GlobalKey _imageKey = GlobalKey();

  final double handleSize = 20;
  Rect cropRect = const Rect.fromLTWH(100, 100, 200, 200);

  Offset? _dragStart;
  Rect? _startRect;

  void _onDragStart(DragStartDetails details) {
    _dragStart = details.localPosition;
    _startRect = cropRect;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dragStart == null || _startRect == null) return;
    final dx = details.localPosition.dx - _dragStart!.dx;
    final dy = details.localPosition.dy - _dragStart!.dy;
    setState(() {
      cropRect = _startRect!.translate(dx, dy);
    });
  }

  void _onHandleDrag(DragUpdateDetails details, String corner) {
    setState(() {
      double newLeft = cropRect.left;
      double newTop = cropRect.top;
      double newRight = cropRect.right;
      double newBottom = cropRect.bottom;

      switch (corner) {
        case 'tl':
          newLeft += details.delta.dx;
          newTop += details.delta.dy;
          break;
        case 'tr':
          newRight += details.delta.dx;
          newTop += details.delta.dy;
          break;
        case 'bl':
          newLeft += details.delta.dx;
          newBottom += details.delta.dy;
          break;
        case 'br':
          newRight += details.delta.dx;
          newBottom += details.delta.dy;
          break;
      }

      cropRect = Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
    });
  }

  Future<void> _cropAndRecognizeText() async {
    final inputImage = await getInputImageFromRepaintBoundary(
      _imageKey,
      cropRect,
    );

    if (inputImage == null) {
      print("No OCR image");
      return;
    }

    // final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    // final result = await recognizer.processImage(inputImage);

    // setState(() => _recognizedText = result.text);
    // recognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop & OCR'),
        actions: [
          IconButton(
            icon: Icon(_showCropOverlay ? Icons.zoom_out_map : Icons.crop),
            tooltip: 'Toggle Overlay',
            onPressed: () =>
                setState(() => _showCropOverlay = !_showCropOverlay),
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner),
            tooltip: 'Crop and OCR',
            onPressed: _cropAndRecognizeText,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 1,
                  maxScale: 4,
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        key: _imageKey,
                        child: Image.file(widget.image, fit: BoxFit.contain),
                      ),
                      if (_showCropOverlay)
                        Positioned.fill(
                          child: GestureDetector(
                            onPanStart: _onDragStart,
                            onPanUpdate: _onDragUpdate,
                            child: CustomPaint(
                              painter: CropRectPainter(cropRect),
                            ),
                          ),
                        ),
                      if (_showCropOverlay) ..._buildHandles(),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_recognizedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black.withOpacity(0.6),
              width: double.infinity,
              child: Text(
                _recognizedText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildHandles() {
    return [
      _handle(cropRect.topLeft, 'tl'),
      _handle(cropRect.topRight, 'tr'),
      _handle(cropRect.bottomLeft, 'bl'),
      _handle(cropRect.bottomRight, 'br'),
    ];
  }

  Widget _handle(Offset offset, String corner) {
    return Positioned(
      left: offset.dx - handleSize / 2,
      top: offset.dy - handleSize / 2,
      child: GestureDetector(
        onPanUpdate: (details) => _onHandleDrag(details, corner),
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class CropRectPainter extends CustomPainter {
  final Rect rect;
  CropRectPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
