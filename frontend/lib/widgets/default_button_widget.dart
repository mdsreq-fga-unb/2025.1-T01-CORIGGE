import 'package:flutter/material.dart';

import '../config/size_config.dart';
import '../config/theme.dart';

class DefaultButtonWidget extends StatefulWidget {
  const DefaultButtonWidget(
      {this.child,
      super.key,
      this.disabled = false,
      this.width,
      this.onPressed,
      this.shape,
      this.expanded = false,
      this.padding,
      this.height,
      this.color});

  final Widget? child;
  final double? height;
  final double? width;
  final bool disabled;
  final EdgeInsets? padding;
  final Color? color;
  final void Function()? onPressed;
  final ShapeBorder? shape;
  final bool expanded;

  @override
  State<DefaultButtonWidget> createState() => _DefaultButtonWidgetState();
}

class _DefaultButtonWidgetState extends State<DefaultButtonWidget>
    with TickerProviderStateMixin {
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
  void didUpdateWidget(DefaultButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _updateColorAnimation();
    }
  }

  Color _getDefaultTextColor() {
    final buttonColor = widget.color ?? kPrimary;
    // Use white text for dark buttons, dark text for light buttons
    return _isLightColor(buttonColor) ? kOnSurface : kOnPrimary;
  }

  Color _getHoverTextColor() {
    final buttonColor = widget.color ?? kPrimary;
    // Slightly different shade for hover
    return _isLightColor(buttonColor)
        ? kSecondary
        : kOnPrimary.withOpacity(0.8);
  }

  bool _isLightColor(Color color) {
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
    Widget button = Padding(
      padding: EdgeInsets.all(getProportionateScreenWidth(2)),
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: AnimatedBuilder(
          animation: Listenable.merge([_underlineAnimation, _colorAnimation]),
          builder: (context, child) {
            return Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                MaterialButton(
                  key: _buttonKey,
                  disabledColor: (widget.color ?? kPrimary).withOpacity(0.5),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed:
                      widget.disabled ? null : (widget.onPressed ?? () {}),
                  height: widget.height,
                  color: widget.color ?? kPrimary,
                  minWidth: widget.width ?? 0,
                  elevation: widget.color != Colors.transparent ? null : 0,
                  focusElevation: widget.color != Colors.transparent ? null : 0,
                  hoverElevation: widget.color != Colors.transparent ? null : 0,
                  shape: widget.shape ??
                      RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(kDefaultBorderRadius)),
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
              ],
            );
          },
        ),
      ),
    );

    if (widget.width == null) {
      button = SizedBox(
        width: widget.expanded ? double.infinity : null,
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
