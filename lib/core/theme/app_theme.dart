import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme configuration.
class AppTheme {
  AppTheme._();

  static const Color primaryMint = Color(0xFFA8E6CF);
  static const Color secondaryLavender = Color(0xFFCDB4DB);
  static const Color accentPeach = Color(0xFFFFD6A5);
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardTintMint = Color(0xFFEAF7F1);
  static const Color cardTintLavender = Color(0xFFF3EFFF);
  static const Color textPrimary = Color(0xFF1E1E1E);
  /// Muted labels on white/pastel cards (stronger contrast than pure gray-500).
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color softError = Color(0xFFFF8A80);
  static const Color darkBackground = Color(0xFF12171C);
  static const Color darkSurface = Color(0xFF1A222A);
  static const Color darkSurfaceAlt = Color(0xFF222D37);
  static const Color darkTextPrimary = Color(0xFFF5F7F9);
  static const Color darkTextSecondary = Color(0xFFB6C2CC);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundColor(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? darkSurface : cardTintMint;

  static Color surfaceAltColor(BuildContext context) =>
      isDark(context) ? darkSurfaceAlt : cardTintLavender;

  static Color cardTintMintColor(BuildContext context) => surfaceColor(context);

  static Color cardTintLavenderColor(BuildContext context) =>
      surfaceAltColor(context);

  static Color textPrimaryColor(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryColor(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color borderColor(BuildContext context) => Theme.of(
    context,
  ).colorScheme.outlineVariant;

  static Color shadowColor(BuildContext context) =>
      isDark(context) ? const Color(0x33000000) : const Color(0x14000000);

  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: primaryMint,
      onPrimary: Colors.white,
      secondary: secondaryLavender,
      onSecondary: textPrimary,
      tertiary: accentPeach,
      onTertiary: textPrimary,
      error: softError,
      onError: Colors.white,
      surface: background,
      onSurface: textPrimary,
      outline: Color(0xFFD8DEE2),
      outlineVariant: Color(0xFFE7ECEF),
      shadow: Color(0x12000000),
      scrim: Color(0x1A000000),
      inverseSurface: textPrimary,
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFF7CCFAE),
    );

    final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: textSecondary, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textSecondary),
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: cardTintMint,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryMint,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryMint,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelMedium,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE6E9EC),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardTintLavender,
        disabledColor: const Color(0xFFE9EBEE),
        selectedColor: secondaryLavender,
        secondarySelectedColor: secondaryLavender,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: textTheme.labelMedium!.copyWith(color: textSecondary),
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(
          color: textPrimary,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryMint;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryMint.withValues(alpha: 0.45);
          }
          return const Color(0xFFE3E6E9);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: secondaryLavender,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryMint,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          shadowColor: const Color(0x12000000),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: secondaryLavender),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: textTheme.labelMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryMint, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: secondaryLavender,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryMint,
      onPrimary: textPrimary,
      secondary: secondaryLavender,
      onSecondary: textPrimary,
      tertiary: accentPeach,
      onTertiary: textPrimary,
      error: softError,
      onError: textPrimary,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      outline: Color(0xFF3A4751),
      outlineVariant: Color(0xFF2A3640),
      shadow: Color(0x55000000),
      scrim: Color(0x66000000),
      inverseSurface: Colors.white,
      onInverseSurface: textPrimary,
      inversePrimary: Color(0xFF6AB792),
    );

    final textTheme = GoogleFonts.poppinsTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).copyWith(
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: darkTextPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkTextPrimary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: darkTextSecondary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: darkTextPrimary,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: darkTextSecondary,
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: darkTextSecondary, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkTextSecondary),
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryMint,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: darkTextPrimary,
        unselectedLabelColor: darkTextSecondary,
        indicatorColor: primaryMint,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelMedium,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: darkTextSecondary,
        textColor: darkTextPrimary,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: darkTextSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E3943),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceAlt,
        disabledColor: const Color(0xFF25303A),
        selectedColor: secondaryLavender,
        secondarySelectedColor: secondaryLavender,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: textTheme.labelMedium!.copyWith(color: darkTextSecondary),
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(
          color: textPrimary,
        ),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryMint;
          return darkTextPrimary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryMint.withValues(alpha: 0.45);
          }
          return const Color(0xFF3A4751);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: secondaryLavender,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryMint,
          foregroundColor: textPrimary,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          shadowColor: const Color(0x55000000),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: secondaryLavender),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkTextPrimary,
          textStyle: textTheme.labelMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceAlt,
        hintStyle: textTheme.bodyMedium?.copyWith(color: darkTextSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: darkTextSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryMint, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkSurfaceAlt,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
