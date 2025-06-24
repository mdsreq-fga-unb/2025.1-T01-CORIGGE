import 'package:corigge/config/size_config.dart';
import 'package:corigge/environment.dart';
import 'package:corigge/routes.dart';
import 'package:corigge/widgets/error_handling_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'features/login/login_page.dart';
import 'widgets/router_widget.dart';

late SharedPreferences sp;

void main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      //print('${record.level.name}: ${record.time}: ${record.message}\n Stacktrace-> ${record.stackTrace}');
    }
  });
  WidgetsFlutterBinding.ensureInitialized();
  sp = await SharedPreferences.getInstance();

  if (const String.fromEnvironment("CORIGGE_DEBUG", defaultValue: "") != "") {
    Environment.setEnvironment(EnvironmentType.DEV);
  } else {
    Environment.setEnvironment(EnvironmentType.PROD);
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
        )),
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
              )),
            ),
          )),
      routes: Routes.routes.entries.map((e) {
        return GoRoute(
          path: e.key,
          pageBuilder: (context, state) {
            SystemChrome.setApplicationSwitcherDescription(
                ApplicationSwitcherDescription(
              label: 'Corigge', //- $routedynamic,
              primaryColor: Theme.of(context).primaryColor.value,
            ));
            return NoTransitionPage(
              child: RouterWidget(route: e.key, state: state),
            );
          },
        );
      }).toList());

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
}
