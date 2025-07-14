import 'dart:typed_data';

import 'package:flutter/material.dart';

class PdfToImagesResult {
  Map<String, Uint8List> imageBytes;
  Map<String, Offset> calibrationPoints;
  Map<String, Size> imageSizes;

  PdfToImagesResult(this.imageBytes, this.calibrationPoints, this.imageSizes);

  factory PdfToImagesResult.fromJson(Map<String, dynamic> json) {
    return PdfToImagesResult(
      (json['image_bytes'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(key, Uint8List.fromList(List<int>.from(value))),
      ),
      (json['calibration_rects'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(key, Offset(value['x'] ?? 0.0, value['y'] ?? 0.0)),
      ),
      (json['image_sizes'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
            key, Size(value['width'].toDouble(), value['height'].toDouble())),
      ),
    );
  }
}
