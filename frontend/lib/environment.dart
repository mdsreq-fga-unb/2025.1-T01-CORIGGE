//EnvironmentType
// ignore: constant_identifier_names
import 'package:logging/logging.dart';

// ignore: constant_identifier_names
enum EnvironmentType { DEV, PROD }

final log = Logger("Routes");

class Environment {
  static String supabaseUrl = '';
  static String supabaseAnonKey = '';
  static EnvironmentType currentEnvironmentType = EnvironmentType.PROD;

  static bool isDebug() {
    return const String.fromEnvironment("CORIGGE_DEBUG", defaultValue: "") != "";
  }

  static setEnvironment(EnvironmentType env) {
    switch (env) {
      case EnvironmentType.DEV:
        log.info('****** Environment: DEV');
        supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
        supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
        break;
      case EnvironmentType.PROD:
        log.info('****** Environment: PROD');
        supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
        supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
        break;
    }
    currentEnvironmentType = env;
  }
}
