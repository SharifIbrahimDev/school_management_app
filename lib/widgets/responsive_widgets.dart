import 'package:flutter/material.dart';
import '../core/utils/responsive_utils.dart';

/// A responsive scaffold wrapper that adapts layout based on screen size
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  
  /// Optional sidebar for tablet/desktop layouts
  final Widget? sidebar;
  final double? sidebarWidth;
  
  /// Whether to center content on large screens
  final bool centerContentOnLargeScreens;
  final double? maxContentWidth;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.sidebar,
    this.sidebarWidth,
    this.centerContentOnLargeScreens = false,
    this.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    // Build the main content
    Widget content = body;

    // Center content on large screens if requested
    if (centerContentOnLargeScreens && (isTablet || isDesktop)) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxContentWidth ?? ResponsiveUtils.maxContentWidth(context),
          ),
          child: content,
        ),
      );
    }

    // Add sidebar for tablet/desktop if provided
    if (sidebar != null && !isMobile) {
      final width = sidebarWidth ?? ResponsiveUtils.sidebarWidth(context);
      content = Row(
        children: [
          SizedBox(
            width: width,
            child: sidebar,
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      appBar: appBar,
      body: content,
      drawer: isMobile ? drawer : null,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}

/// A responsive grid view that adapts columns based on screen size
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final double childAspectRatio;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.gridColumns(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding ?? ResponsiveUtils.responsivePadding(context),
      physics: physics,
      shrinkWrap: shrinkWrap,
      children: children,
    );
  }
}

/// A responsive card that adapts size and elevation based on screen
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveUtils.responsivePadding(context);
    final responsiveElevation = elevation ?? ResponsiveUtils.cardElevation(context);
    final responsiveBorderRadius = borderRadius ?? 
        BorderRadius.circular(ResponsiveUtils.borderRadius(context));

    Widget card = Card(
      elevation: responsiveElevation,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: responsiveBorderRadius),
      child: Padding(
        padding: responsivePadding,
        child: child,
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: responsiveBorderRadius,
        child: card,
      );
    }

    return card;
  }
}

/// A responsive container with adaptive padding
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double mobile;
  final double? tablet;
  final double? desktop;
  final bool horizontal;
  final bool vertical;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile = 16.0,
    this.tablet,
    this.desktop,
    this.horizontal = true,
    this.vertical = true,
  });

  @override
  Widget build(BuildContext context) {
    final value = ResponsiveUtils.valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2,
    );

    EdgeInsets padding;
    if (horizontal && vertical) {
      padding = EdgeInsets.all(value);
    } else if (horizontal) {
      padding = EdgeInsets.symmetric(horizontal: value);
    } else if (vertical) {
      padding = EdgeInsets.symmetric(vertical: value);
    } else {
      padding = EdgeInsets.zero;
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// A responsive text widget that scales font size
class ResponsiveText extends StatelessWidget {
  final String text;
  final double mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;
  final Color? color;

  const ResponsiveText(
    this.text, {
    super.key,
    required this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveUtils.responsiveFontSize(
      context,
      mobile: mobileFontSize,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// A responsive row/column that switches based on screen size
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool rowOnMobile;
  final bool rowOnTablet;
  final bool rowOnDesktop;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.rowOnMobile = false,
    this.rowOnTablet = true,
    this.rowOnDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    final useRow = ResponsiveUtils.valueByDevice(
      context: context,
      mobile: rowOnMobile,
      tablet: rowOnTablet,
      desktop: rowOnDesktop,
    );

    if (useRow) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    } else {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }
  }
}
