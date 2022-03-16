import 'package:flutter/material.dart';

import 'custom_path.dart';

class DrawingPainter extends CustomPainter {
  final CustomPath? currentPath;
  final List<CustomPath> pathList;
  final Color backgroundColor;

  DrawingPainter(this.currentPath, this.pathList, this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    for (CustomPath path in pathList) {
      canvas.drawPath(path.path, path.paint);
    }
    if (currentPath != null) {
      canvas.drawPath(currentPath!.path, currentPath!.paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
