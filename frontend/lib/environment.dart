//EnvironmentType
// ignore: constant_identifier_names
import 'package:logging/logging.dart';
import 'package:dio/dio.dart';

// ignore: constant_identifier_names
enum EnvironmentType { DEV, PROD }

final log = Logger("Routes");

class Environment {
  static String supabaseUrl = 'https://ryhkypmurkztpzlwkmaq.supabase.co';
  static String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5aGt5cG11cmt6dHB6bHdrbWFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5NDQ5MzIsImV4cCI6MjA2NjUyMDkzMn0.lXz6ZHn7ehdBdGsF0LzeyjSEx9vlH5LWN7-PhzvQdOk';
  static String backendAPIUrl = 'http://localhost:4512';
  static EnvironmentType currentEnvironmentType = EnvironmentType.PROD;
  static bool shouldHandleLocalServer = true;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: backendAPIUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Getter for the Dio instance
  static Dio get dio => _dio;

  static bool isDebug() {
    return const String.fromEnvironment("CORIGGE_DEBUG", defaultValue: "") !=
        "";
  }

  static setEnvironment(EnvironmentType env) {
    switch (env) {
      case EnvironmentType.DEV:
        log.info(
            '****** Environment: DEV, not handling local server, make sure to run the opencv server');
        Environment.setShouldHandleLocalServer(false);
        //supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
        //supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
        _dio.options.baseUrl = backendAPIUrl;
        break;
      case EnvironmentType.PROD:
        log.info('****** Environment: PROD');
        //supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
        //supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
        _dio.options.baseUrl = backendAPIUrl;
        break;
    }
    currentEnvironmentType = env;
  }

  static void setShouldHandleLocalServer(bool value) {
    shouldHandleLocalServer = value;
  }
}
