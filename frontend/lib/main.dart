import 'package:corigge/config/size_config.dart';
import 'package:corigge/environment.dart';
import 'package:corigge/routes.dart';
import 'package:corigge/widgets/error_handling_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'config/theme.dart';
import 'features/login/presentation/page/login_page.dart';
import 'widgets/router_widget.dart';
import 'services/local_process_server_service.dart';
import 'services/opencv_service.dart';

late SharedPreferences sp;

class AppWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    // Clean up processes
    await OpenCVService.disconnect();
    await LocalProcessServerService.dispose();
    await windowManager.destroy();
  }
}

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      //print('${record.level.name}: ${record.time}: ${record.message}\n Stacktrace-> ${record.stackTrace}');
    }
  });
  sp = await SharedPreferences.getInstance();

  if (const String.fromEnvironment("CORIGGE_DEBUG", defaultValue: "") != "") {
    Environment.setEnvironment(EnvironmentType.DEV);
  } else {
    Environment.setEnvironment(EnvironmentType.PROD);
  }

  // Set minimum window size for desktop
  if (!kIsWeb) {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      await windowManager.ensureInitialized();
      await windowManager.waitUntilReadyToShow();

      // Set window properties
      await windowManager.setTitle('Corigge');
      await windowManager.setMinimumSize(const Size(800, 600));
      await windowManager.setSize(const Size(1280, 720));
      await windowManager.center();

      // Handle window close event
      windowManager.addListener(AppWindowListener());

      await windowManager.show();
    }
  }

  await Supabase.initialize(
    url: Environment.supabaseUrl,
    anonKey: Environment.supabaseAnonKey,
  );

  ErrorWidget.builder = (FlutterErrorDetails details) {
    var errorStr = "Erro inesperado: ${details.exceptionAsString()}";

    if (details.context != null) {
      errorStr += "\nNo context: ${details.context!.toDescription()}";
      errorStr += details.context!.showName
          ? "\nEncontrado em: ${details.context!.name} com prefixo '${details.context!.linePrefix}'"
          : "";
      if (details.context!.value != null) {
        errorStr += "\nValor: ${details.context!.value}";
      }
    }

    if (details.informationCollector != null) {
      errorStr += "\nInformações adicionais:\n";
      errorStr +=
          details.informationCollector!().map((e) => '- "$e"').join("\n");
    }

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: ErrorHandlingPage(
            errorText: errorStr,
            showHomeButton: true,
            child: Container(),
          ),
        ),
      ),
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter router = GoRouter(
    errorPageBuilder: (context, state) => NoTransitionPage(
      /* transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child), */
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Center(
            child: ErrorHandlingPage(
              errorText: "Url inválida!",
              child: Container(),
            ),
          ),
        ),
      ),
    ),
    routes: Routes.routes.entries.map((e) {
      return GoRoute(
        path: e.key,
        pageBuilder: (context, state) {
          SystemChrome.setApplicationSwitcherDescription(
            ApplicationSwitcherDescription(
              label: 'Corigge', //- $routedynamic,
              primaryColor: Theme.of(context).primaryColor.value,
            ),
          );
          return NoTransitionPage(
            child: RouterWidget(route: e.key, state: state),
          );
        },
      );
    }).toList(),
  );

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final themeSP = sp.getBool("theme");
    var isDark = themeSP ??
        false; // Se não houver um tema salvo, usa o tema claro por padrão

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: isDark ? darkTheme() : theme(),
      routerConfig: router,
    );
  }

  @override
  void reassemble() {
    // Called on hot reload. Ensure resources are cleaned to avoid duplicates.
    OpenCVService.disconnect();
    LocalProcessServerService.dispose();
    super.reassemble();
  }
}
