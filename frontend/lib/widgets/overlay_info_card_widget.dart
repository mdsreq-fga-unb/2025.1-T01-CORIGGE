import 'package:flutter/material.dart';
import 'package:corigge/config/size_config.dart';
import 'package:corigge/config/theme.dart';

/// A reusable overlay information card widget with consistent styling
/// Used for displaying information that overlays on backgrounds
class OverlayInfoCardWidget extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final double? opacity;
  final bool showShadow;

  const OverlayInfoCardWidget({
    super.key,
    required this.title,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.opacity,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 12),
      child: Container(
        padding: padding ?? EdgeInsets.all(getProportionateScreenWidth(16)),
        decoration: BoxDecoration(
          color: (backgroundColor ?? kSurface).withOpacity(opacity ?? 0.9),
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          border: Border.all(color: kSecondary.withOpacity(0.3)),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: getProportionateFontSize(18),
                fontWeight: FontWeight.bold,
                color: kOnSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: getProportionateScreenHeight(8)),
            child,
          ],
        ),
      ),
    );
  }
}
