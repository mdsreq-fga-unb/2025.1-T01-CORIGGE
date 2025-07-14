import '../../../utils/image_bounding_box/data/box_details.dart';
import '../../../utils/image_bounding_box/data/image_circle.dart';

class AnswerSheetIdentifiableBox {
  BoxDetails box;
  List<ImageCircle> circles = [];
  bool hasCalculatedCircles;

  String name;

  AnswerSheetIdentifiableBox(
      {required this.box,
      required this.name,
      this.hasCalculatedCircles = false});

  factory AnswerSheetIdentifiableBox.fromJson(Map<String, dynamic> json) {
    return AnswerSheetIdentifiableBox(
        box: BoxDetails.fromJson(json),
        hasCalculatedCircles: json['has_calculated_circles'],
        name: json['name'])
      ..circles = ((json['circles'] as List<dynamic>?)
              ?.map((e) => ImageCircle.fromJson(e))
              .toList()) ??
          [];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      "circles": circles.map((e) => e.toJson()).toList(),
      ...box.toJson(),
      "has_calculated_circles": hasCalculatedCircles
    };
  }

  //copy with

  AnswerSheetIdentifiableBox copyWith({
    BoxDetails? box,
    List<ImageCircle>? circles,
    bool? hasCalculatedCircles,
    String? name,
  }) {
    return AnswerSheetIdentifiableBox(
      box: box ?? this.box,
      hasCalculatedCircles: hasCalculatedCircles ?? this.hasCalculatedCircles,
      name: name ?? this.name,
    )..circles = circles ?? this.circles;
  }
}
