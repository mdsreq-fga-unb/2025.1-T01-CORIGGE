import 'dart:ui';

import '../../../utils/image_bounding_box/data/image_circle.dart';
import 'python_circle_identification_params.dart';

class AnswerSheetCardModel {
  String path;
  Offset calibrationPoint;
  Size? imageSize;
  String documentOriginalName;
  Map<String, List<ImageCircle>> circlesPerBox = {};
  Offset imageOffset = Offset(0, 0);
  double imageAngle = 0;
  PythonCircleIdentificationParams circleParams;

  AnswerSheetCardModel({
    required this.path,
    required this.calibrationPoint,
    required this.documentOriginalName,
    PythonCircleIdentificationParams? circleParams,
  }) : circleParams = circleParams ?? PythonCircleIdentificationParams();

  factory AnswerSheetCardModel.fromJson(Map<String, dynamic> json) {
    return AnswerSheetCardModel(
      path: json['path'],
      calibrationPoint:
          Offset(json['calibration_point_dx'], json['calibration_point_dy']),
      documentOriginalName: json['document_original_name'],
      circleParams: json['circle_params'] != null
          ? PythonCircleIdentificationParams.fromJson(json['circle_params'])
          : null,
    )
      ..imageSize = json['image_size'] != null
          ? Size(json['image_size']['width'], json['image_size']['height'])
          : null
      ..imageOffset =
          Offset(json['image_offset_dx'] ?? 0, json['image_offset_dy'] ?? 0)
      ..imageAngle = json['image_angle'] ?? 0
      ..circlesPerBox = (json['circles_per_box'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List).map((e) => ImageCircle.fromJson(e)).toList(),
            ),
          ) ??
          {};
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'calibration_point_dx': calibrationPoint.dx,
      'calibration_point_dy': calibrationPoint.dy,
      'document_original_name': documentOriginalName,
      'circle_params': circleParams.toJson(),
      'image_size': imageSize != null
          ? {
              'width': imageSize!.width,
              'height': imageSize!.height,
            }
          : null,
      'image_offset_dx': imageOffset.dx,
      'image_offset_dy': imageOffset.dy,
      'image_angle': imageAngle,
      'circles_per_box': circlesPerBox.map(
        (key, value) => MapEntry(
          key,
          value.map((e) => e.toJson()).toList(),
        ),
      ),
    };
  }
}
