import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageBoundingBoxController {
  Matrix4 _transformationMatrix = Matrix4.identity();
  ValueNotifier<Matrix4> _transformationNotifier =
      ValueNotifier(Matrix4.identity());

  Matrix4 get transformationMatrix => _transformationMatrix;

  // Listen to changes on the transformation matrix
  ValueListenable<Matrix4> get transformationListenable =>
      _transformationNotifier;

  // Method to reset the transformation matrix to the identity matrix
  void resetTransformation() {
    _transformationMatrix = Matrix4.identity();
    _transformationNotifier.value = _transformationMatrix;
  }

  // Apply a transformation
  void applyTransformation(Matrix4 matrix) {
    _transformationMatrix = matrix;
    _transformationNotifier.value = _transformationMatrix;
  }

  // Other transformation methods can be added here (e.g., zoom, pan)
}
