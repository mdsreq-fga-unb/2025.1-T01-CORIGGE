// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/splash/presentation/pages/splash_page.dart';
import '../routes.dart';

class RouterWidget extends StatefulWidget {
  final String route;
  final GoRouterState state;
  const RouterWidget({super.key, required this.route, required this.state});

  @override
  State<RouterWidget> createState() => _RouterWidgetState();
}

class _RouterWidgetState extends State<RouterWidget> {
  bool loading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      () async {
        if (widget.route == "/") {
          if (widget.state.pathParameters.containsKey("code")) {
            await Supabase.instance.client.auth.exchangeCodeForSession(widget.state.pathParameters["code"]!);
          }

          await Routes.checkLoggedIn(
            context,
            inSplash: true,
            onFoundUser: () => context.go("/home"),
            onDontFoundUserWhenDosentBillingMethod: () => context.go("/registro"),
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
    return loading ? const SplashPage() : Routes.routes[widget.route]!.call(context, widget.state);
  }
}
