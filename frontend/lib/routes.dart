import 'package:corigge/features/home/presentation/pages/home_page.dart';
import 'package:corigge/features/login/presentation/page/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:corigge/environment.dart';

import 'cache/shared_preferences_helper.dart';
import 'features/analyze_cards/presentation/pages/analyze_cards_page.dart';
import 'features/register/presentation/pages/register_page.dart';
import 'features/splash/domain/repositories/auth_service.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/templates/presentation/pages/template_selection_page.dart';

final log = Environment.getLogger('routes');

class Routes {
  static List<String> routesThatNeedNoLogin = ["/login", "/registro", "/"];

  static Future<void> checkLoggedIn(
    BuildContext context, {
    bool inSplash = false,
    VoidCallback? onFoundUser,
    VoidCallback? onDontFoundUserWhenDosentBillingMethod,
    VoidCallback? backToLogin,
  }) async {
    log.info(
        "checkLoggedIn SharedPreferencesHelper.currentUser: ${SharedPreferencesHelper.currentUser}");
    if (SharedPreferencesHelper.currentUser == null) {
      var email = Supabase.instance.client.auth.currentUser?.email;
      log.info("checkLoggedIn email: $email");
      if (email == null) {
        log.warning("checkLoggedIn redirecting to /login - no email found");
        backToLogin?.call();
        return;
      }

      var value = await AuthService.databaseSearchUser(email);
      value.fold(
        (error) {
          log.info("checkLoggedIn error searching email $email: $error");
          onDontFoundUserWhenDosentBillingMethod?.call();
        },
        (user) async {
          log.info("checkLoggedIn found user $user");
          if (routesThatNeedNoLogin
                  .contains(GoRouterState.of(context).uri.path) &&
              GoRouterState.of(context).uri.path != "/") {
            if (GoRouterState.of(context).uri.path == "/registro") {
              context.go("/home");
              return;
            }
            return;
          }

          if (user.email == email) {
            log.info("checkLoggedIn redirecting to /home - user verified");
            SharedPreferencesHelper.currentUser = user;

            onFoundUser?.call();

            return;
          } else {
            log.info("checkLoggedIn redirecting to /login - email mismatch");
            backToLogin?.call();
            return;
          }
        },
      );
    } else {
      if (inSplash) {
        // ignore: use_build_context_synchronously
        context.go("/home");
      }
    }
  }

  static Map<String, dynamic Function(BuildContext, GoRouterState)> routes = {
    '/': (context, state) {
      return const SplashPage();
    },
    '/login': (context, state) {
      return const LoginPage();
    },
    '/home': (context, state) {
      return const HomePage();
    },
    '/registro': (context, state) {
      return const RegisterPage();
    },
    '/templates': (context, state) {
      return TemplateSelectionPage();
    },
    '/analyze-cards': (context, state) {
      return AnalyzeCardsPage();
    },
  };
}
