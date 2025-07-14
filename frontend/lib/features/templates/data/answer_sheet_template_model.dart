import 'package:flutter/material.dart';

import 'answer_sheet_identifiable_box.dart';
import 'python_circle_identification_params.dart';

class AnswerSheetTemplateModel {
  String id;
  String name;
  Offset? calibrationPoint;
  Size? imageSize;
  PythonCircleIdentificationParams circleParams;
  bool hasImg;

  List<AnswerSheetIdentifiableBox> boxes;

  AnswerSheetTemplateModel(
      {required this.name,
      required this.boxes,
      required this.id,
      this.hasImg = false,
      PythonCircleIdentificationParams? circleParams,
      this.calibrationPoint = const Offset(0, 0),
      this.imageSize})
      : circleParams = circleParams ?? PythonCircleIdentificationParams();

  factory AnswerSheetTemplateModel.fromJson(Map<String, dynamic> json) {
    return AnswerSheetTemplateModel(
        id: json['id'],
        name: json['name'],
        calibrationPoint: json["calibration_point"] == null
            ? null
            : Offset(
                json['calibration_point']['x'], json['calibration_point']['y']),
        imageSize: json["image_size"] == null
            ? null
            : Size(json['image_size']['width'], json['image_size']['height']),
        hasImg: json["has_img"] ?? false,
        circleParams: json["circle_params"] == null
            ? null
            : PythonCircleIdentificationParams.fromJson(json["circle_params"]),
        boxes: (json['boxes'] as List)
            .map((e) => AnswerSheetIdentifiableBox.fromJson(e))
            .toList());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'has_img': hasImg,
      'circle_params': circleParams.toJson(),
      'calibration_point': calibrationPoint == null
          ? null
          : {
              'x': calibrationPoint!.dx,
              'y': calibrationPoint!.dy,
            },
      'image_size': imageSize == null
          ? null
          : {'width': imageSize!.width, 'height': imageSize!.height},
      'boxes': boxes.map((e) => e.toJson()).toList()
    };
  }
}
