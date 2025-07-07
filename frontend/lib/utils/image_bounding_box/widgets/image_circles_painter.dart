import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../data/box_details.dart';
import '../data/image_circle.dart';
import 'image_bounding_box_painter.dart';

class ImageCirclesPainter extends CustomPainter {
  final ui.Image? image;
  final List<BoxDetails> boxes;
  final ImageCircle? selectedCircle;

  ImageCirclesPainter({
    required this.image,
    required this.boxes,
    this.selectedCircle,
  });

  double scale = 1.0;
  double lastScale = 1.0;
  Offset lastOffset = Offset(0, 0);
  Rect lastDstRect = Rect.zero;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (image != null) {
      // Calculate scale to preserve aspect ratio
      final double imgWidth = image!.width.toDouble();
      final double imgHeight = image!.height.toDouble();
      final double aspectRatio = imgWidth / imgHeight;

      double scale, offsetX, offsetY;
      if (size.width / size.height > aspectRatio) {
        // Limited by height
        scale = size.height / imgHeight;
        offsetX = (size.width - scale * imgWidth) / 2;
        offsetY = 0;
      } else {
        // Limited by width
        scale = size.width / imgWidth;
        offsetX = 0;
        offsetY = (size.height - scale * imgHeight) / 2;
      }

      // Draw the image with the calculated scale and position
      Rect dstRect =
          Rect.fromLTWH(offsetX, offsetY, imgWidth * scale, imgHeight * scale);

      if (scale != lastScale ||
          offsetX != lastOffset.dx ||
          offsetY != lastOffset.dy ||
          dstRect != lastDstRect) {}

      lastDstRect = dstRect;

      lastOffset = Offset(offsetX, offsetY);

      lastScale = scale;

      // Draw the boxes adjusted to the image's scale and position
      for (var box in boxes) {
        Paint circlesPaint = Paint()
          ..color = kSecondary
          ..style = PaintingStyle.fill;

        for (var circle in box.circles) {
          if (selectedCircle != null && selectedCircle!.id == circle.id) {
            circlesPaint.color = Colors.blue;
          } else {
            if (circle.filled) {
              circlesPaint.color = kWarning;
            } else {
              circlesPaint.color = kSecondary;
            }
          }

          Offset scaledCircle = Offset(
            circle.center.dx * dstRect.width + dstRect.left,
            circle.center.dy * dstRect.height + dstRect.top,
          );

          canvas.drawCircle(
              scaledCircle, circle.radius * dstRect.width, circlesPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
