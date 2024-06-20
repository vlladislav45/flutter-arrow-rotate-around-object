import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Moving Arrow Widget')),
        body: Center(child: MovingArrowWidget()),
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

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _angle += details.delta.dx * 0.01; // Adjust the sensitivity of the sliding
      _angle %= 2 * pi; // Keep the angle within 0 to 2*PI
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      child: CustomPaint(
        size: Size(300, 300),
        painter: ArrowPainter(_angle),
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  final double angle;

  ArrowPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final double arrowSize = 20.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - arrowSize;

    // Calculate the new angle based on 15 degree steps (15 degrees = pi/12 radians)
    final double adjustedAngle = (angle / (pi / 12)).round() * (pi / 12);

    final Offset arrowPosition = Offset(
      center.dx + radius * cos(adjustedAngle),
      center.dy + radius * sin(adjustedAngle),
    );

    // Draw the arrow
    drawArrow(canvas, paint, arrowPosition, arrowSize, adjustedAngle);

    // Draw the center image
    final centerImage = AssetImage('assets/images/motorcycle.png');
    centerImage.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        final imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
        final Rect src = Offset.zero & imageSize;
        final Rect dst = Rect.fromCenter(center: center, width: 60, height: 60);
        canvas.drawImageRect(info.image, src, dst, Paint());
      }),
    );
  }

  void drawArrow(Canvas canvas, Paint paint, Offset position, double size, double angle) {
    final Path path = Path();
    path.moveTo(position.dx, position.dy);
    path.lineTo(position.dx - size, position.dy - size / 2);
    path.lineTo(position.dx - size, position.dy + size / 2);
    path.close();

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);
    canvas.translate(-position.dx, -position.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
