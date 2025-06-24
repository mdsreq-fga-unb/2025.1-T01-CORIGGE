import 'package:flutter/material.dart';
import 'navigation/app_router.dart';
import 'core/theme/light_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}