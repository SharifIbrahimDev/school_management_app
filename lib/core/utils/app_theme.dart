import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'responsive_utils.dart';

class AppTheme {
  // Modern "Fintech" Color Palette
  static const Color primaryColor = Color(0xFF064E3B); // Deep Emerald
  static const Color primaryColorDark = Color(0xFF022C22); // Darker Emerald
  static const Color secondaryColor = Color(0xFF10B981); // Vibrant Green
  static const Color accentColor = Color(0xFFD1FAE5); // Mint
  static const Color errorColor = Color(0xFFEF4444); // Modern Red
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color successColorDark = Color(0xFF059669); // Dark Emerald
  static const Color backgroundColor = Color(0xFFF0FDF4); // Very Light Mint/White mix for freshness
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  
  // Text Colors - High Contrast
  static const Color textPrimaryColor = Color(0xFF0F172A); // Almost Black for primary text
  static const Color textSecondaryColor = Color(0xFF475569); // Dark Slate for secondary text
  static const Color textHintColor = Color(0xFF94A3B8); // Light Slate
  static const Color dividerColor = Color(0xFFE2E8F0); // Soft Divider

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, Color(0xFF047857)], // Slightly brighter second color for depth
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF020617), Color(0xFF0F172A)],
  );

  // Neon Design Tokens
  static const Color neonPurple = Color(0xFFC084FC); // Brighter purple for dark mode/accents
  static const Color neonBlue = Color(0xFF60A5FA);
  static const Color neonTeal = Color(0xFF5EEAD4);
  static const Color neonEmerald = Color(0xFF34D399);

  static LinearGradient get neonPurpleGradient => LinearGradient(
    colors: [neonPurple, neonPurple.withValues(alpha: 0.5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get neonBlueGradient => LinearGradient(
    colors: [neonBlue, neonBlue.withValues(alpha: 0.5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get neonTealGradient => LinearGradient(
    colors: [neonTeal, neonTeal.withValues(alpha: 0.5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get neonEmeraldGradient => LinearGradient(
    colors: [neonEmerald, neonEmerald.withValues(alpha: 0.5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism effects
  static BoxDecoration glassDecoration({
    required BuildContext context,
    double opacity = 0.9, // Increased opacity for better text readability
    double blur = 12.0,
    double borderRadius = 16.0,
    Color? borderColor,
    bool hasGlow = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: isDark ? 0.7 : opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        width: 1.0,
      ),
      boxShadow: hasGlow ? [
        BoxShadow(
          color: (borderColor ?? primaryColor).withOpacity(isDark ? 0.3 : 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        )
      ] : [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        error: errorColor,
        surface: surfaceColor,
        primary: primaryColor,
        secondary: secondaryColor,
        onSurface: textPrimaryColor,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 24),
          titleLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w700, fontSize: 20),
          titleMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w600, fontSize: 18),
          titleSmall: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: TextStyle(color: textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(color: textSecondaryColor, fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(color: textSecondaryColor, fontSize: 12),
          labelLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(color: textSecondaryColor),
        hintStyle: GoogleFonts.inter(color: textHintColor),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
        color: cardColor,
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          color: textSecondaryColor,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: surfaceColor,
        selectedTileColor: accentColor.withOpacity(0.3),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 16,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
        backgroundColor: surfaceColor,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        error: errorColor,
        surface: const Color(0xFF1E293B),
        onSurface: Colors.white,
        primary: secondaryColor, // Use brighter green for primary actions in dark mode
        onPrimary: const Color(0xFF020617), // Dark text on bright green button
        secondary: accentColor,
        onSecondary: const Color(0xFF064E3B),
        outline: const Color(0xFF94A3B8),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
          titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w400), // Slate 300
          bodySmall: TextStyle(color: Color(0xFF94A3B8), fontSize: 12), // Slate 400
          labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F172A), // Match scaffold background for clean look
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: const Color(0xFF020617),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: const BorderSide(color: secondaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        color: const Color(0xFF1E293B),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: const Color(0xFF1E293B),
        selectedTileColor: secondaryColor.withOpacity(0.2),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
        space: 16,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: secondaryColor,
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 8,
      ),
    );
  }

  // Responsive Helper Methods
  
  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context, {
    double mobile = 16.0,
    double? tablet,
    double? desktop,
  }) {
    return ResponsiveUtils.responsivePadding(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context, {
    double mobile = 16.0,
    double? tablet,
    double? desktop,
  }) {
    return ResponsiveUtils.responsiveHorizontalPadding(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, {
    double mobile = 8.0,
    double? tablet,
    double? desktop,
  }) {
    return ResponsiveUtils.spacing(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive font size
  static double fontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return ResponsiveUtils.responsiveFontSize(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, {
    double mobile = 24.0,
    double? tablet,
    double? desktop,
  }) {
    return ResponsiveUtils.responsiveIconSize(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get number of grid columns based on screen size
  static int gridColumns(BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? desktop,
  }) {
    return ResponsiveUtils.gridColumns(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive border radius
  static double borderRadius(BuildContext context, {
    double mobile = 12.0,
    double? tablet,
    double? desktop,
  }) {
    return ResponsiveUtils.borderRadius(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Wrap content with max width for large screens
  static Widget constrainedContent({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) {
    return ResponsiveUtils.constrainedContent(
      context: context,
      child: child,
      maxWidth: maxWidth,
    );
  }

  /// Build responsive layout
  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    return ResponsiveUtils.responsiveBuilder(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
