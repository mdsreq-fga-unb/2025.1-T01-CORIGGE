import 'package:flutter/material.dart';

import '../config/size_config.dart';
import '../config/theme.dart';

class DefaultButtonWidget extends StatelessWidget {
  const DefaultButtonWidget(
      {this.child,
      super.key,
      this.disabled = false,
      this.width,
      this.onPressed,
      this.shape,
      this.expanded = true,
      this.height,
      this.color});

  final Widget? child;
  final double? height;
  final double? width;
  final bool disabled;
  final Color? color;
  final void Function()? onPressed;
  final ShapeBorder? shape;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    Widget button = MaterialButton(
      disabledColor: kPrimary.withOpacity(0.5),
      splashColor: Colors.transparent,
      onPressed: disabled ? null : (onPressed ?? () {}),
      height: height,
      color: color ?? kPrimary,
      minWidth: width,
      elevation: color != Colors.transparent ? null : 0,
      focusElevation: color != Colors.transparent ? null : 0,
      hoverElevation: color != Colors.transparent ? null : 0,
      shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: child is Text
          ? Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(16), vertical: getProportionateScreenHeight(8)),
              child: child,
            )
          : child,
    );
    if (width == null) {
      button = SizedBox(
        width: expanded ? double.infinity : null,
        height: height,
        child: button,
      );
    } else {
      button = SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    return button;
  }
}
