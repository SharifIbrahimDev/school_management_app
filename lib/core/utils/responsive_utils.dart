import 'package:flutter/material.dart';

/// Responsive utilities for adaptive layouts across different screen sizes
class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive value based on screen size
  static T valueByDevice<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context, {
    double mobile = 16.0,
    double? tablet,
    double? desktop,
  }) {
    final value = valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2,
    );
    return EdgeInsets.all(value);
  }

  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context, {
    double mobile = 16.0,
    double? tablet,
    double? desktop,
  }) {
    final value = valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2,
    );
    return EdgeInsets.symmetric(horizontal: value);
  }

  /// Get responsive font size
  static double responsiveFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? mobile * 1.2,
    );
  }

  /// Get responsive icon size
  static double responsiveIconSize(BuildContext context, {
    double mobile = 24.0,
    double? tablet,
    double? desktop,
  }) {
    return valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.4,
    );
  }

  /// Get number of columns for grid based on screen size
  static int gridColumns(BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? desktop,
  }) {
    return valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet ?? 2,
      desktop: desktop ?? 3,
    );
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, {
    double mobile = 8.0,
    double? tablet,
    double? desktop,
  }) {
    return valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2,
    );
  }

  /// Get max content width for centered layouts on large screens
  static double maxContentWidth(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: double.infinity,
      tablet: 800,
      desktop: 1200,
    );
  }

  /// Wrap content with max width constraint for large screens
  static Widget constrainedContent({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) {
    if (isDesktop(context)) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? maxContentWidth(context),
          ),
          child: child,
        ),
      );
    }
    return child;
  }

  /// Build responsive layout with different widgets for different screen sizes
  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive card elevation
  static double cardElevation(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 2.0,
      tablet: 4.0,
      desktop: 6.0,
    );
  }

  /// Get responsive border radius
  static double borderRadius(BuildContext context, {
    double mobile = 12.0,
    double? tablet,
    double? desktop,
  }) {
    return valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.5,
    );
  }

  /// Get responsive button height
  static double buttonHeight(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 48.0,
      tablet: 52.0,
      desktop: 56.0,
    );
  }

  /// Get responsive app bar height
  static double appBarHeight(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 56.0,
      tablet: 64.0,
      desktop: 72.0,
    );
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get safe area padding
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Calculate responsive width percentage
  static double widthPercent(BuildContext context, double percent) {
    return screenWidth(context) * (percent / 100);
  }

  /// Calculate responsive height percentage
  static double heightPercent(BuildContext context, double percent) {
    return screenHeight(context) * (percent / 100);
  }

  /// Get adaptive dialog width
  static double dialogWidth(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: screenWidth(context) * 0.9,
      tablet: 500,
      desktop: 600,
    );
  }

  /// Get adaptive sidebar width
  static double sidebarWidth(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: screenWidth(context) * 0.75,
      tablet: 300,
      desktop: 350,
    );
  }
}

/// Extension on BuildContext for easier access to responsive utilities
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  bool get isPortrait => ResponsiveUtils.isPortrait(this);
  
  double get screenWidth => ResponsiveUtils.screenWidth(this);
  double get screenHeight => ResponsiveUtils.screenHeight(this);
  
  double responsiveValue({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return ResponsiveUtils.valueByDevice(
      context: this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
