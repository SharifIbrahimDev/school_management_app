import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../core/utils/app_theme.dart';

class CustomSpeedDial extends StatelessWidget {
  final List<SpeedDialChild> children;
  final IconData icon;
  final IconData activeIcon;
  final Color? backgroundColor;
  final String? tooltip;

  const CustomSpeedDial({
    super.key,
    required this.children,
    this.icon = Icons.add,
    this.activeIcon = Icons.close,
    this.backgroundColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: icon,
      activeIcon: activeIcon,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      foregroundColor: Colors.white,
      activeBackgroundColor: Colors.redAccent,
      activeForegroundColor: Colors.white,
      visible: true,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      tooltip: tooltip ?? 'Quick Actions',
      heroTag: 'speed-dial-hero-tag',
      elevation: 8.0,
      isOpenOnStart: false,
      animationDuration: const Duration(milliseconds: 300),
      children: children,
    );
  }
}
