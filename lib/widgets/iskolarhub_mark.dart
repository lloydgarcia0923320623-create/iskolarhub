import 'dart:math' as math;
import 'package:flutter/material.dart';

class IskolarHubMark extends StatelessWidget {
  final double size;
  final Color color;
  final Color accentColor;

  const IskolarHubMark({
    super.key,
    this.size = 52,
    this.color = const Color(0xFF6366F1),
    this.accentColor = const Color(0xFF10B981),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _IskolarHubMarkPainter(
        color: color,
        accentColor: accentColor,
      ),
    );
  }
}

class _IskolarHubMarkPainter extends CustomPainter {
  static const double _bookRadiusRatio = 0.31;
  static const double _strokeRatio = 0.075;

  static const double _arcStartAngle = 0.12;
  static const double _arcSweepAngle = 0.76;
  static const double _secondArcStartAngle = 1.12;

  static const double _bookLeftX = 0.17;
  static const double _bookRightX = 0.83;
  static const double _bookTopY = 0.45;
  static const double _bookBottomY = 0.75;
  static const double _bookCenterX = 0.5;
  static const double _bookCenterY = 0.48;
  static const double _bookCenterBottomY = 0.78;
  static const double _bookControlLeftX = 0.34;
  static const double _bookControlRightX = 0.66;
  static const double _bookControlY = 0.37;
  static const double _bookControlBottomY = 0.67;

  static const double _nodeLeftX = 0.18;
  static const double _nodeRightX = 0.82;
  static const double _nodeTopY = 0.2;
  static const double _nodeTopCenterY = 0.08;
  static const double _nodeRadiusRatio = 0.06;

  static const double _connectionLineRatio = 0.025;

  final Color color;
  final Color accentColor;

  const _IskolarHubMarkPainter({
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * _bookRadiusRatio;
    final stroke = size.width * _strokeRatio;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    _drawArcPair(canvas, center, radius, linePaint);

    _drawBook(canvas, size, linePaint);

    _drawConnectionNodes(canvas, size, linePaint, center);
  }

  void _drawArcPair(
      Canvas canvas, Offset center, double radius, Paint linePaint) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * _arcStartAngle,
      math.pi * _arcSweepAngle,
      false,
      linePaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * _secondArcStartAngle,
      math.pi * _arcSweepAngle,
      false,
      linePaint,
    );
  }

  void _drawBook(Canvas canvas, Size size, Paint linePaint) {
    final book = Path()
      ..moveTo(size.width * _bookLeftX, size.height * _bookTopY)
      ..quadraticBezierTo(
        size.width * _bookControlLeftX,
        size.height * _bookControlY,
        size.width * _bookCenterX,
        size.height * _bookCenterY,
      )
      ..quadraticBezierTo(
        size.width * _bookControlRightX,
        size.height * _bookControlY,
        size.width * _bookRightX,
        size.height * _bookTopY,
      )
      ..lineTo(size.width * _bookRightX, size.height * _bookBottomY)
      ..quadraticBezierTo(
        size.width * _bookControlRightX,
        size.height * _bookControlBottomY,
        size.width * _bookCenterX,
        size.height * _bookCenterBottomY,
      )
      ..quadraticBezierTo(
        size.width * _bookControlLeftX,
        size.height * _bookControlBottomY,
        size.width * _bookLeftX,
        size.height * _bookBottomY,
      )
      ..close();

    canvas.drawPath(book, linePaint);

    canvas.drawLine(
      Offset(size.width * _bookCenterX, size.height * _bookCenterY),
      Offset(size.width * _bookCenterX, size.height * _bookCenterBottomY),
      linePaint,
    );
  }

  void _drawConnectionNodes(
    Canvas canvas,
    Size size,
    Paint linePaint,
    Offset center,
  ) {
    final nodePaint = Paint()..color = accentColor;
    final nodeRadius = size.width * _nodeRadiusRatio;
    final connectionLineStroke = size.width * _connectionLineRatio;

    final nodePositions = [
      Offset(size.width * _nodeLeftX, size.height * _nodeTopY),
      Offset(size.width * _nodeRightX, size.height * _nodeTopY),
      Offset(size.width * _bookCenterX, size.height * _nodeTopCenterY),
    ];

    for (final nodePoint in nodePositions) {
      canvas.drawCircle(nodePoint, nodeRadius, nodePaint);

      canvas.drawLine(
        nodePoint,
        center,
        linePaint..strokeWidth = connectionLineStroke,
      );
    }
  }

  @override
  bool shouldRepaint(_IskolarHubMarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accentColor != accentColor;
}
