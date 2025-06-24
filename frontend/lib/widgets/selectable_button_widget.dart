import 'package:flutter/material.dart';

import '../../../../config/theme.dart';

class SelectableButtonWidget extends StatefulWidget {
  const SelectableButtonWidget(
      {super.key,
      required this.onPressed,
      this.child,
      this.minWidth,
      this.height,
      this.color,
      this.selectedColor,
      this.selected,
      this.borderRadius,
      this.colorChangeDuration = const Duration(seconds: 1),
      this.borderSide,
      this.elevation,
      this.disabled = false,
      this.expands = true,
      this.width});

  final bool disabled;
  final void Function(bool) onPressed;
  final Widget? child;
  final double? elevation;
  final double? borderRadius;
  final BorderSide? borderSide;
  final double? minWidth;
  final double? height;
  final Color? selectedColor;
  final Color? color;
  final bool? selected;
  final bool expands;
  final Duration? colorChangeDuration;
  final double? width;

  @override
  State<SelectableButtonWidget> createState() => _SelectableButtonWidgetState();
}

class _SelectableButtonWidgetState extends State<SelectableButtonWidget> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? (widget.expands ? double.infinity : null),
      child: MaterialButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
            side: widget.borderSide ?? BorderSide.none),
        splashColor: Colors.transparent,
        elevation: widget.elevation ?? 0,
        color: widget.selected != null
            ? (widget.selected!
                ? widget.selectedColor ?? kSecondary
                : widget.color ?? kPrimary)
            : (selected
                ? widget.selectedColor ?? kSecondary
                : widget.color ?? kPrimary),
        height: widget.height,
        minWidth: widget.minWidth,
        onPressed: widget.disabled
            ? null
            : () {
                setState(() {
                  selected = !selected;
                });
                widget.onPressed(selected);
              },
        child: widget.child,
      ),
    );
  }
}
