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

var log = Logger("RouterWidget");

class RouterWidget extends StatefulWidget {
  final String route;
  final GoRouterState state;
  const RouterWidget({super.key, required this.route, required this.state});

  @override
  State<RouterWidget> createState() => _RouterWidgetState();
}

class _RouterWidgetState extends State<RouterWidget> {
  bool loading = true;
  bool isProcessRunning = false;
  Timer? _processCheckTimer;
  bool _isReconnecting = false;
  final FocusNode _focusNode = FocusNode();
  String? _loadingStatus;
  bool _isError = false;

  Future<void> _initializeProcess() async {
    if (_isReconnecting) return;

    try {
      setState(() {
        _isReconnecting = true;
        _loadingStatus = 'Iniciando serviço local...';
        _isError = false;
      });

      // First, ensure any existing process is stopped
      await LocalProcessServerService.stopProcess();
      await OpenCVService.disconnect();

      // Wait a moment before restarting
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _loadingStatus = 'Inicializando serviço local...';
      });

      // Start the local process
      await LocalProcessServerService.initialize(onProgress: (msg) {
        if (mounted) {
          setState(() {
            _loadingStatus = msg;
          });
        }
      });
      await LocalProcessServerService.startProcess();

      // Wait a moment for the process to be fully ready
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _loadingStatus = 'Conectando ao serviço local...';
      });

      // Connect to the WebSocket
      await OpenCVService.connect();

      setState(() {
        isProcessRunning = true;
        _isReconnecting = false;
        _loadingStatus = null;
      });
    } catch (e) {
      log.severe('Error initializing process: $e');
      setState(() {
        isProcessRunning = false;
        _isReconnecting = false;
        _isError = true;
        _loadingStatus = 'Erro ao inicializar o serviço:\n${e.toString()}';
      });

      // Schedule a retry after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (!isProcessRunning && mounted && !_isError) {
          _initializeProcess();
        }
      });
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
        loadingStatus: _loadingStatus,
        isError: _isError,
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
                          if (_loadingStatus != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _loadingStatus!,
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
