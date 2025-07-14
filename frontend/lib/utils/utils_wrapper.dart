import 'package:flutter/material.dart';
import 'package:corigge/utils/utils.dart';

class UtilsWrapper {
  void showTopSnackBar(BuildContext context, String message, {Color? color}) {
    Utils.showTopSnackBar(context, message, color: color);
  }
}
