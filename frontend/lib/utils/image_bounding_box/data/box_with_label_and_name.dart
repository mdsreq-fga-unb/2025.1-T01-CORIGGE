import 'dart:ui';

import 'package:corigge/utils/image_bounding_box/data/image_circle.dart';

class BoxWithLabelAndName {
  Rect box;
  String label;
  String name;
  List<ImageCircle>? templateCircles;

  BoxWithLabelAndName({
    required this.box,
    required this.label,
    required this.name,
    this.templateCircles,
  });

  Map<String, dynamic> toJson() {
    return {
      'rect': {
        'left': box.left,
        'top': box.top,
        'width': box.width,
        'height': box.height,
      },
      'rect_type': label,
      'name': name,
      'template_circles': templateCircles?.map((e) => e.toJson()).toList(),
    };
  }
}
