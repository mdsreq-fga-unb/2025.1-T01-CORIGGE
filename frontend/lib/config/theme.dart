import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// write as kVariables
/*
static const Color primary = Color(0xFF6200EE);
  static const Color primaryVariant = Color(0xFF3700B3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color error = Color(0xFFB00020);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onBackground = Colors.black;
  static const Color onSurface = Colors.black;
  static const Color onError = Colors.white;
*/

const kPrimary = Color(0xFF6200EE);
const kPrimaryVariant = Color(0xFF3700B3);
const kSecondary = Color(0xFF03DAC6);
const kSecondaryVariant = Color(0xFF018786);
const kBackground = Color(0xFFFFFFFF);
const kSurface = Color(0xFFF5F5F5);
const kError = Color(0xFFB00020);
const kOnPrimary = Colors.white;
const kOnSecondary = Colors.black;
const kOnBackground = Colors.black;
const kOnSurface = Colors.black;
const kOnError = Colors.white;

const kPrimaryDark = Color(0xFF3700B3);
const kSecondaryDark = Color(0xFF018786);
const kBackgroundDark = Color(0xFF222222);
const kSurfaceDark = Color(0xFF222222);
const kErrorDark = Color(0xFFB00020);
const kOnPrimaryDark = Colors.white;
const kOnSecondaryDark = Colors.black;
const kOnBackgroundDark = Colors.white;
const kOnSurfaceDark = Colors.white;
const kOnErrorDark = Colors.white;


ThemeData darkTheme() {
  return ThemeData(
    scaffoldBackgroundColor: const Color(0xFF222222),
    appBarTheme: appBarTheme(true),
    textTheme: textTheme(true),
    fontFamily: 'Montserrat',
    inputDecorationTheme: inputDecorationTheme(),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

ThemeData theme() {
  return ThemeData(
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: appBarTheme(false),
    textTheme: textTheme(false),
    fontFamily: 'Montserrat',
    inputDecorationTheme: inputDecorationTheme(),
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
    // If  you are using latest version of flutter then lable text and hint text shown like this
    // if you r using flutter less then 1.20.* then maybe this is not working properly
    // if we are define our floatingLabelBehavior in our theme then it's not applayed
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: const EdgeInsets.symmetric(horizontal: 42, vertical: 20),
    enabledBorder: outlineInputBorder,
    focusedBorder: outlineInputBorder,
    border: outlineInputBorder,
  );
}

TextTheme textTheme(bool isDark) {
  return TextTheme(
    bodyLarge: TextStyle(
      color: isDark ? kPrimaryDark : kPrimary,
    ),
    bodyMedium: TextStyle(color: isDark ? kPrimaryDark : kPrimary),
  );
}

AppBarTheme appBarTheme(bool isDark) {
  return AppBarTheme(
    scrolledUnderElevation: 0,
    color: Colors.transparent,
    systemOverlayStyle:
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    elevation: 0,
    iconTheme: IconThemeData(color: isDark ? kPrimaryDark : kPrimary),
  );
}
