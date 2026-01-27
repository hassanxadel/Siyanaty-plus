import 'package:flutter/material.dart';
import '../../shared/utils/responsive_utils.dart';

/// Wrapper widget that enforces responsive sizing constraints
/// Wrap your MaterialApp with this to ensure consistent sizing across all devices
/// 
/// This widget:
/// - Clamps text scale factor to prevent overflow
/// - Provides responsive MediaQuery data
/// - Ensures consistent sizing across different screen sizes
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double minTextScaleFactor;
  final double maxTextScaleFactor;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.minTextScaleFactor = 0.8,
    this.maxTextScaleFactor = 1.3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor.clamp(
              minTextScaleFactor,
              maxTextScaleFactor,
            )),
          ),
          child: child,
        );
      },
    );
  }
}

/// Extension to make any widget responsive
extension ResponsiveWidgetExtension on Widget {
  /// Wrap this widget with responsive constraints
  Widget responsive({
    double minTextScaleFactor = 0.8,
    double maxTextScaleFactor = 1.3,
  }) {
    return ResponsiveWrapper(
      minTextScaleFactor: minTextScaleFactor,
      maxTextScaleFactor: maxTextScaleFactor,
      child: this,
    );
  }
}

/// A responsive SizedBox that scales with screen size
class ResponsiveSizedBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;

  const ResponsiveSizedBox({
    super.key,
    this.width,
    this.height,
    this.child,
  });

  /// Create a responsive vertical space
  const ResponsiveSizedBox.height(double height, {super.key})
      : width = null,
        height = height,
        child = null;

  /// Create a responsive horizontal space
  const ResponsiveSizedBox.width(double width, {super.key})
      : width = width,
        height = null,
        child = null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width != null ? context.responsiveSize(width!) : null,
      height: height != null ? context.responsiveSize(height!) : null,
      child: child,
    );
  }
}

/// A responsive Container that scales with screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;

  const ResponsiveContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width != null ? context.responsiveSize(width!) : null,
      height: height != null ? context.responsiveSize(height!) : null,
      padding: padding,
      margin: margin,
      decoration: decoration,
      alignment: alignment,
      constraints: constraints,
      child: child,
    );
  }
}

/// A responsive Padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double? all;
  final double? horizontal;
  final double? vertical;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.all,
    this.horizontal,
    this.vertical,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  /// Create responsive padding with all sides equal
  const ResponsivePadding.all(double value, {super.key, required this.child})
      : all = value,
        horizontal = null,
        vertical = null,
        left = null,
        top = null,
        right = null,
        bottom = null;

  /// Create responsive padding with symmetric values
  const ResponsivePadding.symmetric({
    super.key,
    required this.child,
    double? horizontal,
    double? vertical,
  })  : all = null,
        horizontal = horizontal,
        vertical = vertical,
        left = null,
        top = null,
        right = null,
        bottom = null;

  /// Create responsive padding with individual values
  const ResponsivePadding.only({
    super.key,
    required this.child,
    double? left,
    double? top,
    double? right,
    double? bottom,
  })  : all = null,
        horizontal = null,
        vertical = null,
        left = left,
        top = top,
        right = right,
        bottom = bottom;

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding;

    if (all != null) {
      padding = EdgeInsets.all(context.responsiveSize(all!));
    } else if (horizontal != null || vertical != null) {
      padding = EdgeInsets.symmetric(
        horizontal: horizontal != null ? context.responsiveSize(horizontal!) : 0,
        vertical: vertical != null ? context.responsiveSize(vertical!) : 0,
      );
    } else {
      padding = EdgeInsets.only(
        left: left != null ? context.responsiveSize(left!) : 0,
        top: top != null ? context.responsiveSize(top!) : 0,
        right: right != null ? context.responsiveSize(right!) : 0,
        bottom: bottom != null ? context.responsiveSize(bottom!) : 0,
      );
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// A responsive Text widget with automatic font scaling
class ResponsiveText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final String? fontFamily;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;
  final TextDecoration? decoration;

  const ResponsiveText(
    this.text, {
    super.key,
    required this.fontSize,
    this.fontWeight,
    this.color,
    this.fontFamily,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.responsiveTextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontFamily: fontFamily,
        height: height,
        decoration: decoration,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
