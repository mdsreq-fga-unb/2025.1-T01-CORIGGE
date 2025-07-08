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
import 'cache/shared_preferences_helper.dart';
import 'config/theme.dart';
import 'features/login/presentation/page/login_page.dart';
import 'widgets/router_widget.dart';
import 'services/local_process_server_service.dart';
import 'services/opencv_service.dart';
import 'dart:async';

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
  await SharedPreferences.getInstance();
  await SharedPreferencesHelper.init();
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      //print('${record.level.name}: ${record.time}: ${record.message}\n Stacktrace-> ${record.stackTrace}');
    }
  });
  Environment.initializeLogging();
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

  // Initialize OpenCV service
  if (!Environment.shouldHandleLocalServer) {
    try {
      await OpenCVService.connect(maxRetries: 1);
      Logger.root.info('Connected to WebSocket server');
    } catch (e) {
      Logger.root.warning('Could not connect to WebSocket server: $e');
    }
  } else {
    try {
      // First, ensure the process is stopped
      await LocalProcessServerService.stopProcess();

      // Initialize and start the process
      await LocalProcessServerService.initialize(
        onProgress: (message) {
          Logger.root.info('OpenCV initialization: $message');
        },
      );

      await LocalProcessServerService.startProcess();

      // Wait a bit for the process to fully start
      await Future.delayed(const Duration(seconds: 2));

      // Try to connect with retries
      await OpenCVService.connect(maxRetries: 5);
      Logger.root.info('OpenCV service initialized successfully');
    } catch (e) {
      Logger.root.severe('Error initializing OpenCV service: $e');
    }
  }

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
  bool isProcessRunning = false;
  String? _error;
  Timer? _processCheckTimer;
  bool _isReconnecting = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  Widget _buildReconnectionOverlay(Widget child) {
    return Stack(
      children: [
        child,
        if (!isProcessRunning)
          Material(
            color: Colors.transparent,
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Reconectando ao serviço...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: kError,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _initializeOpenCV() async {
    if (!Environment.shouldHandleLocalServer) {
      try {
        await OpenCVService.connect(maxRetries: 1);
        Logger.root.info('Connected to WebSocket server');
        setState(() {
          isProcessRunning = true;
        });
      } catch (e) {
        Logger.root.warning('Could not connect to WebSocket server: $e');
        setState(() {
          isProcessRunning = false;
          _error = e.toString();
        });
      }
    } else {
      try {
        // First, ensure the process is stopped
        await LocalProcessServerService.stopProcess();

        // Initialize and start the process
        await LocalProcessServerService.initialize(
          onProgress: (message) {
            Logger.root.info('OpenCV initialization: $message');
          },
        );

        await LocalProcessServerService.startProcess();

        // Wait a bit for the process to fully start
        await Future.delayed(const Duration(seconds: 2));

        // Try to connect with retries
        await OpenCVService.connect(maxRetries: 5);
        Logger.root.info('OpenCV service initialized successfully');
        setState(() {
          isProcessRunning = true;
        });
      } catch (e) {
        Logger.root.severe('Error initializing OpenCV service: $e');
        setState(() {
          isProcessRunning = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _checkProcessStatus() async {
    if (_isReconnecting || !mounted) return;

    try {
      final isAlive = await OpenCVService.ping();
      if (!isAlive && !_isReconnecting) {
        setState(() {
          isProcessRunning = false;
        });

        // Try to reconnect
        try {
          await OpenCVService.connect(maxRetries: 1);
          if (mounted) {
            setState(() {
              isProcessRunning = true;
              _error = null;
            });
          }
        } catch (e) {
          Logger.root.warning('Could not reconnect to WebSocket server: $e');
          if (mounted) {
            setState(() {
              _error = e.toString();
            });
          }
        }
      } else if (isAlive && !isProcessRunning) {
        setState(() {
          isProcessRunning = true;
          _error = null;
        });
      }
    } catch (e) {
      Logger.root.warning('Error checking process status: $e');
      if (mounted) {
        setState(() {
          isProcessRunning = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeOpenCV();

    // Start periodic process check
    _processCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkProcessStatus(),
    );
  }

  @override
  void dispose() {
    _processCheckTimer?.cancel();
    super.dispose();
  }

  late final GoRouter router = GoRouter(
    navigatorKey: _navigatorKey,
    errorPageBuilder: (context, state) => NoTransitionPage(
      child: _buildReconnectionOverlay(
        Scaffold(
          backgroundColor: kBackground,
          body: SafeArea(
            child: Center(
              child: ErrorHandlingPage(
                errorText: "Erro: ${state.error}",
                child: Container(),
              ),
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
              label: 'Corigge',
              primaryColor: Theme.of(context).primaryColor.value,
            ),
          );
          return NoTransitionPage(
            child: _buildReconnectionOverlay(
              RouterWidget(route: e.key, state: state),
            ),
          );
        },
      );
    }).toList(),
  );

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final themeSP = sp.getBool("theme");
    var isDark = themeSP ?? false;

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
