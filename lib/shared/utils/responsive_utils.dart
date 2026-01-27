import 'package:flutter/material.dart';

/// Utility class for responsive sizing and layout helpers
/// Use these helpers instead of hardcoded pixel values
/// 
/// This system uses a base design width of 375px (iPhone 11 Pro size)
/// and scales all dimensions proportionally to the actual device width
class ResponsiveUtils {
  // Base design dimensions (iPhone 11 Pro as reference)
  static const double _baseWidth = 375.0;
  
  // Device size categories
  static const double _smallDeviceWidth = 340.0;
  static const double _mediumDeviceWidth = 375.0;
  static const double _largeDeviceWidth = 414.0;
  static const double _tabletWidth = 600.0;

  /// Get the scale factor based on screen width
  /// This ensures consistent sizing across all devices
  static double _getScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / _baseWidth;
    
    // Clamp the scale factor to prevent extreme scaling
    // Min: 0.75 (very small devices), Max: 1.5 (tablets)
    return scale.clamp(0.75, 1.5);
  }

  /// Get responsive size based on base design size
  /// This is the main method to use for all sizing
  /// Example: ResponsiveUtils.size(context, 16) for 16px in base design
  static double size(BuildContext context, double baseSize) {
    return baseSize * _getScaleFactor(context);
  }

  /// Get responsive height based on screen size
  /// Use this sparingly - prefer flexible layouts
  static double height(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * (percentage / 100);
  }

  /// Get responsive width based on screen size
  /// Use this sparingly - prefer flexible layouts
  static double width(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get safe area padding
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Check if device is small (width < 360)
  static bool isSmallDevice(BuildContext context) {
    return MediaQuery.of(context).size.width < _smallDeviceWidth;
  }

  /// Check if device is medium (360 <= width < 414)
  static bool isMediumDevice(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _mediumDeviceWidth && width < _largeDeviceWidth;
  }

  /// Check if device is large (414 <= width < 600)
  static bool isLargeDevice(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _largeDeviceWidth && width < _tabletWidth;
  }

  /// Check if device is tablet (width >= 600)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= _tabletWidth;
  }

  /// Get responsive font size based on screen width
  /// Uses the scale factor for consistent sizing
  static double fontSize(BuildContext context, double baseSize) {
    final scale = _getScaleFactor(context);
    
    // Apply slightly less aggressive scaling for fonts
    // to maintain readability
    final adjustedScale = 1.0 + (scale - 1.0) * 0.7;
    
    return baseSize * adjustedScale;
  }

  /// Get responsive spacing based on screen size
  /// Uses the scale factor for consistent sizing
  static double spacing(BuildContext context, double baseSpacing) {
    return baseSpacing * _getScaleFactor(context);
  }

  /// Get responsive padding with scale factor
  static EdgeInsets responsivePadding(BuildContext context, {
    double horizontal = 16,
    double vertical = 16,
  }) {
    final scale = _getScaleFactor(context);
    
    return EdgeInsets.symmetric(
      horizontal: horizontal * scale,
      vertical: vertical * scale,
    );
  }

  /// Get responsive padding with individual values
  static EdgeInsets responsivePaddingAll(BuildContext context, {
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    final scale = _getScaleFactor(context);
    
    return EdgeInsets.only(
      left: left * scale,
      top: top * scale,
      right: right * scale,
      bottom: bottom * scale,
    );
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, double baseSize) {
    return baseSize * _getScaleFactor(context);
  }

  /// Get responsive border radius
  static double borderRadius(BuildContext context, double baseRadius) {
    return baseRadius * _getScaleFactor(context);
  }

  /// Get responsive button height
  static double buttonHeight(BuildContext context, double baseHeight) {
    return baseHeight * _getScaleFactor(context);
  }

  /// Get responsive container size
  static Size containerSize(BuildContext context, double baseWidth, double baseHeight) {
    final scale = _getScaleFactor(context);
    return Size(baseWidth * scale, baseHeight * scale);
  }

  /// Get text scale factor from system settings
  static double textScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Clamp text scale factor to prevent extreme scaling
  /// This prevents render overflow from accessibility settings
  static double clampedTextScaleFactor(BuildContext context, {
    double min = 0.8,
    double max = 1.3,
  }) {
    final scaleFactor = MediaQuery.of(context).textScaleFactor;
    return scaleFactor.clamp(min, max);
  }

  /// Get responsive TextStyle with proper scaling
  static TextStyle responsiveTextStyle(BuildContext context, {
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    String? fontFamily,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontSize: ResponsiveUtils.fontSize(context, fontSize),
      fontWeight: fontWeight,
      color: color,
      fontFamily: fontFamily,
      height: height,
      decoration: decoration,
    );
  }

  /// Get responsive BoxConstraints
  static BoxConstraints responsiveConstraints(BuildContext context, {
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    final scale = _getScaleFactor(context);
    
    return BoxConstraints(
      minWidth: minWidth != null ? minWidth * scale : 0,
      maxWidth: maxWidth != null ? maxWidth * scale : double.infinity,
      minHeight: minHeight != null ? minHeight * scale : 0,
      maxHeight: maxHeight != null ? maxHeight * scale : double.infinity,
    );
  }

  /// Get device category as string (for debugging)
  static String getDeviceCategory(BuildContext context) {
    if (isSmallDevice(context)) return 'Small';
    if (isMediumDevice(context)) return 'Medium';
    if (isLargeDevice(context)) return 'Large';
    if (isTablet(context)) return 'Tablet';
    return 'Unknown';
  }

  /// Get scale factor for debugging
  static double getScaleFactorDebug(BuildContext context) {
    return _getScaleFactor(context);
  }
}

/// Extension on BuildContext for easier access to responsive utilities
extension ResponsiveContext on BuildContext {
  // Screen properties
  double get screenWidth => ResponsiveUtils.screenWidth(this);
  double get screenHeight => ResponsiveUtils.screenHeight(this);
  EdgeInsets get safeAreaPadding => ResponsiveUtils.safeAreaPadding(this);
  
  // Device type checks
  bool get isSmallDevice => ResponsiveUtils.isSmallDevice(this);
  bool get isMediumDevice => ResponsiveUtils.isMediumDevice(this);
  bool get isLargeDevice => ResponsiveUtils.isLargeDevice(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  
  // Scale factors
  double get textScaleFactor => ResponsiveUtils.textScaleFactor(this);
  double get clampedTextScaleFactor => ResponsiveUtils.clampedTextScaleFactor(this);
  double get scaleFactor => ResponsiveUtils.getScaleFactorDebug(this);
  
  // Responsive sizing methods
  double r(double baseSize) => ResponsiveUtils.size(this, baseSize);
  double responsiveSize(double baseSize) => ResponsiveUtils.size(this, baseSize);
  double responsiveHeight(double percentage) => ResponsiveUtils.height(this, percentage);
  double responsiveWidth(double percentage) => ResponsiveUtils.width(this, percentage);
  double responsiveFontSize(double baseSize) => ResponsiveUtils.fontSize(this, baseSize);
  double responsiveSpacing(double baseSize) => ResponsiveUtils.spacing(this, baseSize);
  double responsiveIconSize(double baseSize) => ResponsiveUtils.iconSize(this, baseSize);
  double responsiveBorderRadius(double baseRadius) => ResponsiveUtils.borderRadius(this, baseRadius);
  double responsiveButtonHeight(double baseHeight) => ResponsiveUtils.buttonHeight(this, baseHeight);
  
  // Responsive padding methods
  EdgeInsets responsivePadding({double horizontal = 16, double vertical = 16}) {
    return ResponsiveUtils.responsivePadding(this, horizontal: horizontal, vertical: vertical);
  }
  
  EdgeInsets responsivePaddingAll({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return ResponsiveUtils.responsivePaddingAll(
      this,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }
  
  // Responsive TextStyle
  TextStyle responsiveTextStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    String? fontFamily,
    double? height,
    TextDecoration? decoration,
  }) {
    return ResponsiveUtils.responsiveTextStyle(
      this,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: fontFamily,
      height: height,
      decoration: decoration,
    );
  }
  
  // Debug info
  String get deviceCategory => ResponsiveUtils.getDeviceCategory(this);
}
