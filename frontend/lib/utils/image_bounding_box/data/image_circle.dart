import 'package:flutter/material.dart';

class ImageCircle {
  Offset center;

  double radius;
  bool filled;
  String id;

  ImageCircle(this.center, this.radius, {this.filled = false, this.id = ""});

  factory ImageCircle.fromJson(Map<String, dynamic> json) {
    return ImageCircle(
        Offset(json['center_x'], json['center_y']), json['radius'],
        filled: json['filled'] ?? false, id: json['id'] ?? "");
  }

  Map<String, dynamic> toJson() {
    return {
      'center_x': center.dx,
      'center_y': center.dy,
      'radius': radius,
      'filled': filled,
      'id': id,
    };
  }
}
