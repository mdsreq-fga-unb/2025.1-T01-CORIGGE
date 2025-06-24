//EnvironmentType
// ignore: constant_identifier_names
import 'package:logging/logging.dart';

// ignore: constant_identifier_names
enum EnvironmentType { DEV, PROD }

final log = Logger("Routes");

class Environment {
  static String supabaseUrl = 'https://qbdqyvgfhsjvpuslkdgh.supabase.co';
  static String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFiZHF5dmdmaHNqdnB1c2xrZGdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MzU1ODIsImV4cCI6MjA2NjExMTU4Mn0.IQmGZDpEokX_1qqpOl3OUAvBD3-N2JQIdLwT2_6Xatk';
  static EnvironmentType currentEnvironmentType = EnvironmentType.PROD;

  static bool isDebug() {
    return const String.fromEnvironment("CORIGGE_DEBUG", defaultValue: "") !=
        "";
  }

  static setEnvironment(EnvironmentType env) {
    switch (env) {
      case EnvironmentType.DEV:
        log.info('****** Environment: DEV');
        //supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
        //supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
        break;
      case EnvironmentType.PROD:
        log.info('****** Environment: PROD');
        //supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
        //supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
        break;
    }
    currentEnvironmentType = env;
  }
}
