import 'dart:ui' as ui;

import 'package:corigge/config/theme.dart';
import 'package:flutter/material.dart';

import '../data/box_details.dart';

class ImageBoundingBoxPainter extends CustomPainter {
  final ui.Image? image;
  final List<BoxDetails> boxes;
  final void Function(Matrix4 matrix) onTransformationChange;
  final void Function(Rect) onImageRectChanged;

  ImageBoundingBoxPainter({
    required this.image,
    required this.boxes,
    required this.onTransformationChange,
    required this.onImageRectChanged,
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
          dstRect != lastDstRect) {
        onTransformationChange(Matrix4.identity()
          ..translate(offsetX, offsetY)
          ..scale(scale));

        onImageRectChanged(dstRect);
      }

      lastDstRect = dstRect;

      lastOffset = Offset(offsetX, offsetY);

      lastScale = scale;

      // Draw the boxes adjusted to the image's scale and position
      for (var box in boxes) {
        Paint paint = _getPaintForLabel(box);

        Rect scaledBox = Rect.fromLTWH(
          box.rect.left * dstRect.width + dstRect.left,
          box.rect.top * dstRect.height + dstRect.top,
          box.rect.width * dstRect.width,
          box.rect.height * dstRect.height,
        );

        canvas.drawRect(scaledBox, paint);
      }
    }
  }

  Paint _getPaintForLabel(BoxDetails box) {
    if (box.hoveredOver) {
      return Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
    }

    switch (box.label) {
      case BoxDetailsType.typeB:
        return Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

      case BoxDetailsType.matricula:
        return Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
      case BoxDetailsType.temp:
        return Paint()
          ..color = Colors.purple
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
      case BoxDetailsType.colunaDeQuestoes:
        return Paint()
          ..color = kPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
      default:
        return Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
