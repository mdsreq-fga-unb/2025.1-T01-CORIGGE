import 'package:flutter/material.dart';

import '../config/size_config.dart';
import '../config/theme.dart';

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
      this.width,
      this.shape,
      this.expanded = false});

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
  final ShapeBorder? shape;
  final bool expanded;

  @override
  State<SelectableButtonWidget> createState() => _SelectableButtonWidgetState();
}

class _SelectableButtonWidgetState extends State<SelectableButtonWidget>
    with TickerProviderStateMixin {
  bool selected = false;
  late AnimationController _underlineController;
  late AnimationController _colorController;
  late Animation<double> _underlineAnimation;
  late Animation<Color?> _colorAnimation;

  final GlobalKey _buttonKey = GlobalKey();
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _underlineController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _underlineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _underlineController,
      curve: Curves.ease,
    ));

    _updateColorAnimation();
  }

  void _updateColorAnimation() {
    _colorAnimation = ColorTween(
      begin: _getDefaultTextColor(),
      end: _getHoverTextColor(),
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.ease,
    ));
  }

  @override
  void didUpdateWidget(SelectableButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color ||
        oldWidget.selectedColor != widget.selectedColor ||
        oldWidget.selected != widget.selected) {
      _updateColorAnimation();
    }
  }

  Color _getCurrentButtonColor() {
    final bool isSelected = widget.selected ?? selected;
    return isSelected
        ? widget.selectedColor ?? kSecondary
        : widget.color ?? kPrimary;
  }

  Color _getDefaultTextColor() {
    final buttonColor = _getCurrentButtonColor();
    // Use white text for dark buttons, dark text for light buttons
    return _isLightColor(buttonColor) ? kOnSurface : kOnPrimary;
  }

  Color _getHoverTextColor() {
    final buttonColor = _getCurrentButtonColor();
    // Slightly different shade for hover
    return _isLightColor(buttonColor)
        ? kSecondary
        : kOnPrimary.withOpacity(0.8);
  }

  bool _isLightColor(Color color) {
    // Calculate luminance to determine if color is light or dark
    return color.computeLuminance() > 0.5;
  }

  @override
  void dispose() {
    _underlineController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (widget.disabled) return;

    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _underlineController.forward();
      _colorController.forward();
    } else {
      _underlineController.reverse();
      _colorController.reverse();
    }
  }

  double _getButtonWidth() {
    if (_buttonKey.currentContext != null) {
      final RenderBox renderBox =
          _buttonKey.currentContext!.findRenderObject() as RenderBox;
      return renderBox.size.width;
    }
    return widget.width ?? getProportionateScreenWidth(200); // fallback width
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.selected ?? selected;
    final buttonColor = _getCurrentButtonColor();

    Widget button = Padding(
      padding: EdgeInsets.all(getProportionateScreenWidth(2)),
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: AnimatedBuilder(
          animation: Listenable.merge([_underlineAnimation, _colorAnimation]),
          builder: (context, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                MaterialButton(
                  key: _buttonKey,
                  disabledColor: buttonColor.withOpacity(0.5),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: widget.disabled
                      ? null
                      : () {
                          if (widget.selected == null) {
                            setState(() {
                              selected = !selected;
                            });
                          }
                          widget.onPressed(widget.selected ?? !selected);
                        },
                  height: widget.height,
                  color: buttonColor,
                  minWidth: widget.minWidth,
                  elevation: buttonColor != Colors.transparent ? null : 0,
                  focusElevation: buttonColor != Colors.transparent ? null : 0,
                  hoverElevation: buttonColor != Colors.transparent ? null : 0,
                  shape: widget.shape ??
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              widget.borderRadius ?? kDefaultBorderRadius),
                          side: widget.borderSide ?? BorderSide.none),
                  child: widget.child is Text
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(16),
                              vertical: getProportionateScreenHeight(8)),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.ease,
                            style: (widget.child as Text).style?.copyWith(
                                      color: _colorAnimation.value,
                                      fontWeight: FontWeight.w500,
                                    ) ??
                                TextStyle(
                                  color: _colorAnimation.value,
                                  fontWeight: FontWeight.w500,
                                  fontSize: getProportionateFontSize(16),
                                ),
                            child: Text((widget.child as Text).data ?? ''),
                          ),
                        )
                      : Theme(
                          data: Theme.of(context).copyWith(
                            iconTheme:
                                IconThemeData(color: _colorAnimation.value),
                          ),
                          child: widget.child!,
                        ),
                ),
                // Animated underline
                Positioned(
                  bottom: -getProportionateScreenHeight(4),
                  left: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.ease,
                    height: getProportionateScreenHeight(2),
                    width: _underlineAnimation.value * _getButtonWidth(),
                    color: kSecondaryVariant,
                  ),
                ),
                // Selection indicator (small dot or different underline for selected state)
                if (isSelected)
                  Positioned(
                    top: getProportionateScreenHeight(4),
                    right: getProportionateScreenWidth(4),
                    child: Container(
                      width: getProportionateScreenWidth(8),
                      height: getProportionateScreenHeight(8),
                      decoration: BoxDecoration(
                        color: _isLightColor(buttonColor)
                            ? kSecondary
                            : kOnPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );

    if (widget.width == null) {
      button = SizedBox(
        width: widget.expanded
            ? double.infinity
            : (widget.expands ? double.infinity : null),
        height: widget.height,
        child: button,
      );
    } else {
      button = SizedBox(
        width: widget.width,
        height: widget.height,
        child: button,
      );
    }

    return button;
  }
}
