// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/splash/presentation/pages/splash_page.dart';
import '../routes.dart';
import '../services/local_process_server_service.dart';
import '../services/opencv_service.dart';
import '../environment.dart';

var log = Logger("RouterWidget");

class RouterWidget extends StatefulWidget {
  final String route;
  final GoRouterState state;
  const RouterWidget({super.key, required this.route, required this.state});

  @override
  State<RouterWidget> createState() => _RouterWidgetState();
}

class _RouterWidgetState extends State<RouterWidget> {
  bool loading = false;
  bool isProcessRunning = false;
  Timer? _processCheckTimer;
  bool _isReconnecting = false;
  final FocusNode _focusNode = FocusNode();
  bool _isInitialized = false;
  String? _initializationStatus;
  String? _error;

  Future<void> _initializeProcess() async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      if (!Environment.shouldHandleLocalServer) {
        // When not handling local server, just try to connect to WebSocket
        try {
          await OpenCVService.connect(maxRetries: 1);
          log.info('Connected to WebSocket server');
          setState(() {
            _isInitialized = true;
            loading = false;
            _initializationStatus = 'Conectado ao servidor';
            _error = null;
            isProcessRunning = true;
          });
        } catch (e) {
          log.warning('Could not connect to WebSocket server: $e');
          setState(() {
            _isInitialized = true;
            _initializationStatus = 'Servidor não disponível';
            _error = null;
            isProcessRunning = false;
          });
        }
        return;
      }

      // First, ensure the process is stopped
      await LocalProcessServerService.stopProcess();

      // Initialize and start the process
      await LocalProcessServerService.initialize(
        onProgress: (message) {
          setState(() {
            _initializationStatus = message;
          });
        },
      );

      await LocalProcessServerService.startProcess();

      // Wait a bit for the process to fully start
      await Future.delayed(const Duration(seconds: 2));

      // Try to connect with retries
      await OpenCVService.connect(maxRetries: 5);

      setState(() {
        _isInitialized = true;
        _initializationStatus = 'Inicialização concluída';
        _error = null;
        isProcessRunning = true;
      });
    } catch (e) {
      log.severe('Error initializing process: $e');
      setState(() {
        _error = e.toString();
        _initializationStatus = 'Erro na inicialização';
      });

      // Schedule a retry after a delay
      if (!_isInitialized) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && !_isInitialized) {
            log.info('Process is down, attempting to restart...');
            _initializeProcess();
          }
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

        // Attempt to restart the process
        log.info('Process is down, attempting to restart...');
        await _initializeProcess();
      } else if (isAlive && !isProcessRunning) {
        setState(() {
          isProcessRunning = true;
        });
      }
    } catch (e) {
      log.warning('Error checking process status: $e');
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

    // Start periodic process check
    _processCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkProcessStatus(),
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      () async {
        if (widget.route == "/") {
          if (widget.state.pathParameters.containsKey("code")) {
            await Supabase.instance.client.auth
                .exchangeCodeForSession(widget.state.pathParameters["code"]!);
          }

          await _initializeProcess();

          await Routes.checkLoggedIn(
            context,
            inSplash: true,
            onFoundUser: () => context.go("/home"),
            onDontFoundUserWhenDosentBillingMethod: () =>
                context.go("/registro"),
            backToLogin: () => context.go("/login"),
          );
        } else {
          await Routes.checkLoggedIn(
            context,
          );
        }
        setState(() {
          loading = false;
        });
      }();
    });
  }

  @override
  void dispose() {
    _processCheckTimer?.cancel();
    OpenCVService.disconnect();
    LocalProcessServerService.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SplashPage(
        loadingStatus: _initializationStatus,
        isError: _error != null,
      );
    }

    Widget content = Routes.routes[widget.route]!.call(context, widget.state);

    if (!isProcessRunning) {
      content = Focus(
        focusNode: _focusNode,
        child: Stack(
          children: [
            content,
            Positioned.fill(
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
                            'Reconectando ao serviço local...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(),
                          if (_isReconnecting) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Tentando reiniciar o serviço...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          if (_initializationStatus != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _initializationStatus!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
            // Invisible overlay to prevent clicks
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return content;
  }
}
