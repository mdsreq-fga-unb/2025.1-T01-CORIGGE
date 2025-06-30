import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Primary Colors
const kPrimary = Color(0xFF8B4513); // Brown
const kPrimaryVariant = Color(0xFF654321); // Darker Brown
const kSecondary = Color(0xFFF0EFEA); // Light Beige
const kSecondaryVariant = Color(0xFFE5E4DF); // Darker Beige
const kBackground = Color(0xFFF0EFEA); // Light Beige
const kSurface = Colors.white;
const kError = Color(0xFFB00020);

// On Colors (text/icon colors for each surface)
const kOnPrimary = Colors.white;
const kOnSecondary = Color(0xFF4A4A4A); // Dark Grey for text
const kOnBackground = Color(0xFF4A4A4A);
const kOnSurface = Color(0xFF4A4A4A);
const kOnError = Colors.white;

// Dark Theme Colors
const kPrimaryDark = Color(0xFF8B4513);
const kSecondaryDark = Color(0xFF654321);
const kBackgroundDark = Color(0xFF222222);
const kSurfaceDark = Color(0xFF333333);
const kErrorDark = Color(0xFFCF6679);
const kOnPrimaryDark = Colors.white;
const kOnSecondaryDark = Colors.white;
const kOnBackgroundDark = Colors.white;
const kOnSurfaceDark = Colors.white;
const kOnErrorDark = Colors.black;
const kSuccess = Color(0xFF00FF00);

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
