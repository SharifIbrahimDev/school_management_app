# Responsive Design System

This document explains how to make the School Management App responsive across different screen sizes (mobile, tablet, and desktop).

## Overview

The app now includes a comprehensive responsive design system with:
- **ResponsiveUtils**: Core utilities for responsive sizing and breakpoints
- **Responsive Widgets**: Pre-built widgets that adapt to screen size
- **AppTheme Extensions**: Responsive methods integrated into AppTheme

## Breakpoints

- **Mobile**: < 600px width
- **Tablet**: 600px - 1200px width  
- **Desktop**: >= 1200px width

## Quick Start

### 1. Using Context Extensions

The easiest way to check screen size:

```dart
import 'package:flutter/material.dart';
import '../core/utils/responsive_utils.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Check device type
    if (context.isMobile) {
      return MobileLayout();
    } else if (context.isTablet) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  }
}
```

### 2. Using Responsive Values

Get different values based on screen size:

```dart
// Responsive padding
final padding = AppTheme.responsivePadding(
  context,
  mobile: 16.0,
  tablet: 24.0,
  desktop: 32.0,
);

// Responsive font size
final fontSize = AppTheme.fontSize(
  context,
  mobile: 14.0,
  tablet: 16.0,
  desktop: 18.0,
);

// Responsive spacing
final spacing = AppTheme.spacing(
  context,
  mobile: 8.0,
  tablet: 12.0,
  desktop: 16.0,
);
```

### 3. Using Responsive Widgets

#### ResponsiveScaffold

Automatically adapts layout with optional sidebar for larger screens:

```dart
ResponsiveScaffold(
  appBar: CustomAppBar(title: 'Dashboard'),
  body: MyContent(),
  sidebar: MySidebar(), // Only shows on tablet/desktop
  centerContentOnLargeScreens: true, // Centers content on large screens
  maxContentWidth: 1200, // Max width for centered content
)
```

#### ResponsiveGridView

Grid that adapts column count based on screen size:

```dart
ResponsiveGridView(
  mobileColumns: 1,
  tabletColumns: 2,
  desktopColumns: 3,
  spacing: 16.0,
  children: [
    StatCard(title: 'Total Students', value: '1,234'),
    StatCard(title: 'Total Teachers', value: '56'),
    StatCard(title: 'Total Classes', value: '24'),
  ],
)
```

#### ResponsiveRowColumn

Switches between Row and Column based on screen size:

```dart
ResponsiveRowColumn(
  rowOnMobile: false,  // Column on mobile
  rowOnTablet: true,   // Row on tablet
  rowOnDesktop: true,  // Row on desktop
  children: [
    Expanded(child: Widget1()),
    Expanded(child: Widget2()),
  ],
)
```

#### ResponsiveText

Text that scales font size automatically:

```dart
ResponsiveText(
  'Welcome',
  mobileFontSize: 24.0,
  tabletFontSize: 28.0,
  desktopFontSize: 32.0,
  fontWeight: FontWeight.bold,
)
```

#### ResponsivePadding

Padding that adapts to screen size:

```dart
ResponsivePadding(
  mobile: 16.0,
  tablet: 24.0,
  desktop: 32.0,
  child: MyWidget(),
)
```

## Common Patterns

### Pattern 1: Responsive Dashboard Cards

```dart
Widget build(BuildContext context) {
  final columns = AppTheme.gridColumns(
    context,
    mobile: 1,
    tablet: 2,
    desktop: 4,
  );

  return GridView.count(
    crossAxisCount: columns,
    padding: AppTheme.responsivePadding(context),
    crossAxisSpacing: AppTheme.spacing(context),
    mainAxisSpacing: AppTheme.spacing(context),
    children: [
      _buildStatCard('Students', '1,234'),
      _buildStatCard('Teachers', '56'),
      _buildStatCard('Classes', '24'),
      _buildStatCard('Revenue', '\$45,678'),
    ],
  );
}
```

### Pattern 2: Responsive List/Detail View

```dart
Widget build(BuildContext context) {
  if (context.isDesktop) {
    // Side-by-side layout for desktop
    return Row(
      children: [
        SizedBox(
          width: 400,
          child: StudentList(),
        ),
        Expanded(
          child: StudentDetail(),
        ),
      ],
    );
  } else {
    // Navigate to detail on mobile/tablet
    return StudentList();
  }
}
```

### Pattern 3: Responsive Dialog

```dart
void showResponsiveDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        width: ResponsiveUtils.dialogWidth(context),
        padding: AppTheme.responsivePadding(context),
        child: DialogContent(),
      ),
    ),
  );
}
```

### Pattern 4: Responsive Form Layout

```dart
Widget build(BuildContext context) {
  return ResponsiveRowColumn(
    rowOnMobile: false,
    rowOnTablet: true,
    rowOnDesktop: true,
    children: [
      Expanded(
        child: CustomTextField(
          labelText: 'First Name',
        ),
      ),
      SizedBox(
        width: context.isMobile ? 0 : 16,
        height: context.isMobile ? 16 : 0,
      ),
      Expanded(
        child: CustomTextField(
          labelText: 'Last Name',
        ),
      ),
    ],
  );
}
```

### Pattern 5: Constrained Content on Large Screens

```dart
Widget build(BuildContext context) {
  return AppTheme.constrainedContent(
    context: context,
    maxWidth: 1200,
    child: SingleChildScrollView(
      padding: AppTheme.responsivePadding(context),
      child: Column(
        children: [
          // Your content here
        ],
      ),
    ),
  );
}
```

## Responsive Helper Methods

### ResponsiveUtils Methods

```dart
// Check device type
bool isMobile = ResponsiveUtils.isMobile(context);
bool isTablet = ResponsiveUtils.isTablet(context);
bool isDesktop = ResponsiveUtils.isDesktop(context);

// Get screen dimensions
double width = ResponsiveUtils.screenWidth(context);
double height = ResponsiveUtils.screenHeight(context);

// Get percentage of screen
double halfWidth = ResponsiveUtils.widthPercent(context, 50);
double quarterHeight = ResponsiveUtils.heightPercent(context, 25);

// Check orientation
bool isLandscape = ResponsiveUtils.isLandscape(context);
bool isPortrait = ResponsiveUtils.isPortrait(context);

// Get adaptive sizes
double dialogWidth = ResponsiveUtils.dialogWidth(context);
double sidebarWidth = ResponsiveUtils.sidebarWidth(context);
double buttonHeight = ResponsiveUtils.buttonHeight(context);
```

### AppTheme Responsive Methods

```dart
// Padding
EdgeInsets padding = AppTheme.responsivePadding(context);
EdgeInsets hPadding = AppTheme.responsiveHorizontalPadding(context);

// Spacing
double space = AppTheme.spacing(context);

// Font size
double fontSize = AppTheme.fontSize(context, mobile: 14.0);

// Icon size
double iconSize = AppTheme.iconSize(context);

// Grid columns
int columns = AppTheme.gridColumns(context);

// Border radius
double radius = AppTheme.borderRadius(context);
```

## Best Practices

1. **Always use responsive utilities** instead of hardcoded values
2. **Test on multiple screen sizes** during development
3. **Use ResponsiveScaffold** for screens that need sidebar support
4. **Constrain content width** on very large screens for better readability
5. **Use responsive grids** for dashboard-style layouts
6. **Switch between Row/Column** based on available space
7. **Scale font sizes** appropriately for different devices
8. **Adjust padding and spacing** to prevent cramped or sparse layouts

## Migration Guide

To make an existing screen responsive:

### Before:
```dart
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('My Screen')),
    body: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('Title', style: TextStyle(fontSize: 24)),
          GridView.count(
            crossAxisCount: 2,
            children: cards,
          ),
        ],
      ),
    ),
  );
}
```

### After:
```dart
Widget build(BuildContext context) {
  return ResponsiveScaffold(
    appBar: CustomAppBar(title: 'My Screen'),
    centerContentOnLargeScreens: true,
    body: Padding(
      padding: AppTheme.responsivePadding(context),
      child: Column(
        children: [
          ResponsiveText(
            'Title',
            mobileFontSize: 24,
            tabletFontSize: 28,
            desktopFontSize: 32,
          ),
          ResponsiveGridView(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            children: cards,
          ),
        ],
      ),
    ),
  );
}
```

## Examples

Check these files for complete examples:
- `lib/widgets/responsive_widgets.dart` - Widget implementations
- `lib/core/utils/responsive_utils.dart` - Core utilities
- `lib/core/utils/app_theme.dart` - Theme integration

## Testing Responsive Layouts

### In Flutter DevTools:
1. Open DevTools
2. Go to "Inspector" tab
3. Click "Toggle Platform Mode" to switch between mobile/desktop
4. Use "Device Emulator" to test different screen sizes

### In Code:
```dart
// Force specific layout for testing
Widget build(BuildContext context) {
  // Temporarily override for testing
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(
      size: Size(800, 600), // Tablet size
    ),
    child: MyScreen(),
  );
}
```

## Summary

The responsive system provides:
- ✅ Automatic layout adaptation
- ✅ Consistent spacing and sizing
- ✅ Easy-to-use helper methods
- ✅ Pre-built responsive widgets
- ✅ Context extensions for quick checks
- ✅ Integration with existing AppTheme

Use these tools to create a seamless experience across all device sizes!
