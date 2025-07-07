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

var log = Environment.getLogger('[router_widget]');

class RouterWidget extends StatefulWidget {
  final String route;
  final GoRouterState state;
  const RouterWidget({super.key, required this.route, required this.state});

  @override
  State<RouterWidget> createState() => _RouterWidgetState();
}

class _RouterWidgetState extends State<RouterWidget> {
  bool loading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      () async {
        if (widget.route == "/") {
          if (widget.state.pathParameters.containsKey("code")) {
            await Supabase.instance.client.auth
                .exchangeCodeForSession(widget.state.pathParameters["code"]!);
          }

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
  Widget build(BuildContext context) {
    if (loading) {
      return SplashPage(
        loadingStatus: null,
        isError: false,
      );
    }

    return Routes.routes[widget.route]!.call(context, widget.state);
  }
}
