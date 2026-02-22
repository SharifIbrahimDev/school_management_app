import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final Color? backgroundColor;
  final Color? iconThemeColor;
  final TextStyle? titleTextStyle;
  final bool automaticallyImplyLeading;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.bottom,
    this.elevation = 0,
    this.backgroundColor,
    this.iconThemeColor,
    this.titleTextStyle,
    this.automaticallyImplyLeading = true,
    this.systemOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: titleWidget ?? (title != null 
        ? Text(
            title!,
            style: titleTextStyle ?? GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          )
        : null),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation,
      backgroundColor: Colors.transparent, // Transparent to show gradient
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          boxShadow: elevation > 0 
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        ),
      ),
      bottom: bottom,
      iconTheme: IconThemeData(
        color: iconThemeColor ?? Colors.white,
      ),
      actionsIconTheme: IconThemeData(
        color: iconThemeColor ?? Colors.white,
      ),
      systemOverlayStyle: systemOverlayStyle ?? SystemUiOverlayStyle.light,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
