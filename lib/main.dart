import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Moving Arrow Widget')),
        body: MovingArrowWidget(),
      ),
    );
  }
}

class MovingArrowWidget extends StatefulWidget {
  @override
  _MovingArrowWidgetState createState() => _MovingArrowWidgetState();
}

class _MovingArrowWidgetState extends State<MovingArrowWidget> {
  double _angle = 0.0;
  ui.Image? _arrowImage;
  ui.Image? _centerImage;
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    _arrowImage = await _loadImage('assets/images/arrow.png');
    _centerImage = await _loadImage('assets/images/motorcycle.png');
    setState(() {
      _imagesLoaded = true;
    });
  }

  Future<ui.Image> _loadImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(data.buffer.asUint8List(), (image) {
      completer.complete(image);
    });
    return completer.future;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _angle += details.delta.dx * 0.02; // Adjust the sensitivity of the sliding
      _angle %= 2 * pi; // Keep the angle within 0 to 2*PI
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 20,
          left: 20,
          child: Text(
            'Angle: ${(_angle * 180 / pi).toStringAsFixed(2)}°',
            style: TextStyle(fontSize: 18),
          ),
        ),
        GestureDetector(
          onPanUpdate: _onPanUpdate,
          child: Center(
            child: CustomPaint(
              size: Size(300, 300),
              painter: _imagesLoaded ? ArrowPainter(_angle, _arrowImage!, _centerImage!) : null,
            ),
          ),
        ),
      ],
    );
  }
}

class ArrowPainter extends CustomPainter {
  final double angle;
  final ui.Image arrowImage;
  final ui.Image centerImage;

  ArrowPainter(this.angle, this.arrowImage, this.centerImage);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 20.0;

    // Calculate the new angle based on 45 degree steps (45 degrees = pi/4 radians)
    final double adjustedAngle = (angle / (pi / 4)).round() * (pi / 4);

    final Offset arrowPosition = Offset(
      center.dx + radius * cos(adjustedAngle),
      center.dy + radius * sin(adjustedAngle),
    );

    // Draw the center image
    final imageSize = Size(centerImage.width.toDouble(), centerImage.height.toDouble());
    final Rect src = Offset.zero & imageSize;
    final Rect dst = Rect.fromCenter(center: center, width: 60, height: 60);
    canvas.drawImageRect(centerImage, src, dst, Paint());

    // Draw the arrow image
    final arrowSize = Size(arrowImage.width.toDouble(), arrowImage.height.toDouble());
    final Rect arrowSrc = Offset.zero & arrowSize;
    final Rect arrowDst = Rect.fromCenter(center: arrowPosition, width: 40, height: 40);

    canvas.save();
    canvas.translate(arrowPosition.dx, arrowPosition.dy);
    canvas.rotate(adjustedAngle);
    canvas.translate(-arrowPosition.dx, -arrowPosition.dy);
    canvas.drawImageRect(arrowImage, arrowSrc, arrowDst, Paint());
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
