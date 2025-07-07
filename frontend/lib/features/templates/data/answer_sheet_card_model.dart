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
}
