import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
        body: MovingArrowWidget(
          onExport: (a) {
            print(a);
          },
          isFirstParticipant: true,
        ),
      ),
    );
  }
}

class MovingArrowWidget extends StatefulWidget {
  final bool isFirstParticipant;
  final Function(Uint8List) onExport;

  MovingArrowWidget({required this.onExport, required this.isFirstParticipant});

  @override
  _MovingArrowWidgetState createState() => _MovingArrowWidgetState();
}

class _MovingArrowWidgetState extends State<MovingArrowWidget> {
  double _angle = 0.0;
  double _adjustedAngle = 0.0; // This variable stores the angle that is rounded to the nearest 45 degrees.
  ui.Image? _arrowImage;
  ui.Image? _centerImage;
  bool _imagesLoaded = false;
  GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  String getAngleText() {
    final angleDegrees = (_adjustedAngle * 180 / pi) % 360;

    if (angleDegrees >= 45 && angleDegrees < 90) {
      return 'Rear right part';
    }
    if (angleDegrees >= 90 && angleDegrees < 135) {
      return 'Rear part';
    }
    if (angleDegrees >= 135 && angleDegrees < 180) {
      return 'Rear left part';
    }
    if (angleDegrees >= 180 && angleDegrees < 225) {
      return 'Left part';
    }
    if (angleDegrees >= 225 && angleDegrees < 270) {
      return 'Front left part';
    }
    if (angleDegrees >= 270 && angleDegrees < 315) {
      return 'Front part';
    }
    if (angleDegrees >= 315 || angleDegrees < 45) {
      return 'Front right part';
    }

    return 'Right part';
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
      _angle += details.delta.dx * 0.01; // Adjust the sensitivity of the sliding
      _angle %= 2 * pi; // Keep the angle within 0 to 2*PI
      _adjustedAngle = (_angle / (pi / 4)).round() * (pi / 4);
    });
  }

  Future<void> _capturePng() async {
    try {
      RenderRepaintBoundary boundary =
      _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Call the callback function with the PNG bytes
      widget.onExport(pngBytes);
    } catch (e) {
      print(e);
      // TODO: REMOVE THE PRINT
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 20,
          left: 20,
          child: Text(
            getAngleText() + ' ' + ((_adjustedAngle * 180 / pi) % 360).toStringAsFixed(2),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: (end) => _capturePng(),
          child: Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: CustomPaint(
                size: const Size(500, 500),
                painter: _imagesLoaded
                    ? ArrowPainter(_adjustedAngle, _arrowImage!, _centerImage!)
                    : null,
              ),
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

    final Offset arrowPosition = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );

    // Draw the center image to fit the full size
    final Rect centerImageDst = Rect.fromCenter(
        center: center, width: size.width / 2.3, height: size.height / 2.3);
    final Rect centerImageSrc =
    Offset.zero & Size(centerImage.width.toDouble(), centerImage.height.toDouble());
    canvas.drawImageRect(centerImage, centerImageSrc, centerImageDst, Paint());

    // Draw the arrow image
    final arrowSize = Size(arrowImage.width.toDouble(), arrowImage.height.toDouble());
    final Rect arrowSrc = Offset.zero & arrowSize;
    final Rect arrowDst = Rect.fromCenter(center: arrowPosition, width: 40, height: 40);

    canvas.save();
    canvas.translate(arrowPosition.dx, arrowPosition.dy);
    canvas.rotate(angle);
    canvas.translate(-arrowPosition.dx, -arrowPosition.dy);
    canvas.drawImageRect(arrowImage, arrowSrc, arrowDst, Paint());
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
