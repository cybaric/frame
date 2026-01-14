import 'package:flutter/material.dart';

class TransparencyGrid extends StatelessWidget {
  final double squareSize;
  final Color lightColor;
  final Color darkColor;

  const TransparencyGrid({
    super.key,
    this.squareSize = 10,
    this.lightColor = const Color(0xFFFFFFFF),
    this.darkColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _CheckerboardPainter(
            squareSize: squareSize,
            lightColor: lightColor,
            darkColor: darkColor,
          ),
        );
      },
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  final double squareSize;
  final Color lightColor;
  final Color darkColor;

  _CheckerboardPainter({
    required this.squareSize,
    required this.lightColor,
    required this.darkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var y = 0.0; y < size.height; y += squareSize) {
      for (var x = 0.0; x < size.width; x += squareSize) {
        // Use floor to ensure consistent grid indices
        final xIndex = (x / squareSize).floor();
        final yIndex = (y / squareSize).floor();

        final isLight = (xIndex + yIndex) % 2 == 0;
        paint.color = isLight ? lightColor : darkColor;

        // Calculate rect width and height to clean edges
        final width = (x + squareSize > size.width)
            ? size.width - x
            : squareSize;
        final height = (y + squareSize > size.height)
            ? size.height - y
            : squareSize;

        canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
