import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Cropper',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
      ),
      home: const ImageSelectorScreen(),
    );
  }
}

class ImageSelectorScreen extends StatefulWidget {
  const ImageSelectorScreen({super.key});
  @override
  State<ImageSelectorScreen> createState() => _ImageSelectorScreenState();
}

class _ImageSelectorScreenState extends State<ImageSelectorScreen> {
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImageCropScreen(image: _image!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Image')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.photo),
          label: const Text('Pick from Gallery'),
          onPressed: _pickImage,
        ),
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

  final double handleSize = 20;
  Rect cropRect = const Rect.fromLTWH(10, 10, 50, 50);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Image'),
        actions: [
          IconButton(
            icon: Icon(_showCropOverlay ? Icons.zoom_out_map : Icons.crop),
            onPressed: () {
              setState(() => _showCropOverlay = !_showCropOverlay);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 1.0,
            maxScale: 4.0,
            child: Stack(
              children: [
                Image.file(widget.image, fit: BoxFit.contain),
                if (_showCropOverlay)
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: _onDragStart,
                      onPanUpdate: _onDragUpdate,
                      child: CustomPaint(painter: CropRectPainter(cropRect)),
                    ),
                  ),
                if (_showCropOverlay) ..._buildHandles(),
              ],
            ),
          );
        },
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
