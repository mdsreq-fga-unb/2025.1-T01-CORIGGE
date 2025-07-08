import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Primary Colors
const kPrimary = Color(0xFF2D3250); // Deep Navy Blue
const kPrimaryVariant = Color(0xFF1A1F3D); // Darker Navy
const kSecondary = Color(0xFF7077A1); // Muted Blue
const kSecondaryVariant = Color(0xFF424769); // Dark Muted Blue
const kBackground = Color(0xFFF6F8FA); // Light Gray with slight blue tint
const kSurface = Colors.white;
const kError = Color(0xFFDC3545); // Modern Red
const kWarning = Color(0xFFFFC107); // Vibrant Amber
const kSuccess = Color(0xFF28A745); // Fresh Green

// On Colors (text/icon colors for each surface)
const kOnPrimary = Colors.white;
const kOnSecondary = Colors.white;
const kOnBackground = Color(0xFF2D3250); // Using primary as text color
const kOnSurface = Color(0xFF2D3250);
const kOnError = Colors.white;

// Dark Theme Colors
const kPrimaryDark = Color(0xFF424769);
const kSecondaryDark = Color(0xFF7077A1);
const kBackgroundDark = Color(0xFF121212); // Material Dark theme background
const kSurfaceDark = Color(0xFF1E1E1E); // Slightly lighter than background
const kErrorDark = Color(0xFFEF5350); // Lighter Red for dark theme
const kOnPrimaryDark = Colors.white;
const kOnSecondaryDark = Colors.white;
const kOnBackgroundDark = Colors.white;
const kOnSurfaceDark = Colors.white;
const kOnErrorDark = Colors.black;

ThemeData darkTheme() {
  return ThemeData(
    scaffoldBackgroundColor: kBackgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: kPrimaryDark,
      secondary: kSecondaryDark,
      surface: kSurfaceDark,
      background: kBackgroundDark,
      error: kErrorDark,
      onPrimary: kOnPrimaryDark,
      onSecondary: kOnSecondaryDark,
      onSurface: kOnSurfaceDark,
      onBackground: kOnBackgroundDark,
      onError: kOnErrorDark,
    ),
    appBarTheme: appBarTheme(true),
    textTheme: textTheme(true),
    fontFamily: 'Roboto',
    inputDecorationTheme: inputDecorationTheme(),
    elevatedButtonTheme: elevatedButtonTheme(),
    textButtonTheme: textButtonTheme(),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

ThemeData theme() {
  return ThemeData(
    scaffoldBackgroundColor: kBackground,
    colorScheme: const ColorScheme.light(
      primary: kPrimary,
      secondary: kSecondary,
      surface: kSurface,
      background: kBackground,
      error: kError,
      onPrimary: kOnPrimary,
      onSecondary: kOnSecondary,
      onSurface: kOnSurface,
      onBackground: kOnBackground,
      onError: kOnError,
    ),
    appBarTheme: appBarTheme(false),
    textTheme: textTheme(false),
    fontFamily: 'Roboto',
    inputDecorationTheme: inputDecorationTheme(),
    elevatedButtonTheme: elevatedButtonTheme(),
    textButtonTheme: textButtonTheme(),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

InputDecorationTheme inputDecorationTheme() {
  OutlineInputBorder outlineInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(28),
    borderSide: const BorderSide(color: kPrimary),
    gapPadding: 10,
  );
  return InputDecorationTheme(
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: const EdgeInsets.symmetric(horizontal: 42, vertical: 20),
    enabledBorder: outlineInputBorder,
    focusedBorder: outlineInputBorder,
    border: outlineInputBorder,
    fillColor: kSurface,
    filled: true,
  );
}

ElevatedButtonThemeData elevatedButtonTheme() {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kSurface,
      foregroundColor: kOnSurface,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
      ),
      elevation: 5,
    ),
  );
}

TextButtonThemeData textButtonTheme() {
  return TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kPrimary,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

TextTheme textTheme(bool isDark) {
  Color textColor = isDark ? Colors.white : const Color(0xFF4A4A4A);
  return TextTheme(
    displayLarge: TextStyle(
      color: textColor,
      fontSize: 48,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      color: textColor,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: TextStyle(
      color: textColor,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: textColor,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: textColor,
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      color: textColor,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: textColor,
      fontSize: 14,
    ),
  );
}

AppBarTheme appBarTheme(bool isDark) {
  return AppBarTheme(
    scrolledUnderElevation: 0,
    color: isDark ? kSurfaceDark : kSurface,
    systemOverlayStyle:
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    elevation: 0,
    iconTheme: IconThemeData(color: isDark ? kOnSurfaceDark : kPrimary),
    titleTextStyle: TextStyle(
      color: isDark ? kOnSurfaceDark : kPrimary,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  );
}
