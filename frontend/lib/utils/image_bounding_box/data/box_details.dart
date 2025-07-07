import 'dart:ui';

import 'image_circle.dart';

class BoxDetailsType {
  static const String colunaDeQuestoes =
      "Coluna de Questões (A e C PAS ou Enem)";
  static const String typeB = "Tipo B";
  static const String matricula = "Matricula";
  static const String exemploCirculo = "Exemplo de Circulo";
  static const String outro = "Outro";
  static const String temp = "Temp";
}

class BoxDetails {
  Rect rect;
  String label;
  bool hoveredOver = false;
  bool shouldShowBox = true;
  bool shouldShowCircles = false;
  List<ImageCircle> circles = [];

  BoxDetails({
    required this.rect,
    required this.label,
  });

  //from json
  factory BoxDetails.fromJson(Map<String, dynamic> json) {
    return BoxDetails(
        rect:
            Rect.fromLTWH(json['x'], json['y'], json['width'], json['height']),
        label: json['label']);
  }

  //to json
  Map<String, dynamic> toJson() {
    return {
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
      'label': label,
    };
  }
}
