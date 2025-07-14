//EnvironmentType
// ignore: constant_identifier_names
import 'dart:async';

import 'package:corigge/utils/utils.dart';
import 'package:logging/logging.dart';
import 'package:dio/dio.dart';
import 'package:stack_trace/stack_trace.dart';

// ignore: constant_identifier_names
enum EnvironmentType { DEV, PROD }

class Environment {
  static String supabaseUrl = 'https://ryhkypmurkztpzlwkmaq.supabase.co';
  static String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5aGt5cG11cmt6dHB6bHdrbWFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5NDQ5MzIsImV4cCI6MjA2NjUyMDkzMn0.lXz6ZHn7ehdBdGsF0LzeyjSEx9vlH5LWN7-PhzvQdOk';
  static String backendAPIUrl = 'http://localhost:4512';
  static EnvironmentType currentEnvironmentType = EnvironmentType.PROD;
  static bool shouldHandleLocalServer = true;
  static final _routesLogger = getLogger('routes');

  static bool _loggingInitialized = false;
  static StreamSubscription<LogRecord>? _logSubscription;

  /// Initialize logging configuration. This should be called once at app startup.
  static void initializeLogging() {
    if (_loggingInitialized) return;

    // Cancel any existing subscription
    _logSubscription?.cancel();

    // Remove any existing handlers
    Logger.root.clearListeners();

    Logger.root.level = Level.ALL;

    // Create a new subscription
    _logSubscription = Logger.root.onRecord.listen((record) {
      final time = Utils.formatDateTime(record.time.toUtc());
      final level = record.level.name;
      final loggerName = record.loggerName;
      var message = record.message;

      // Clean up any extra brackets in the message
      if (message.startsWith("[") && !message.startsWith("[\b")) {
        message = "\b$message";
      }

      // Only add brackets to logger name if it's not empty
      final formattedLoggerName = loggerName.isEmpty ? '' : "[$loggerName]";
      String logMessage = '[$level][$time]$formattedLoggerName $message';

      // Print to console
      print(logMessage);

      // If there's an error and stack trace, print them
      if (record.error != null) {
        print('Error: ${record.error}');
        if (record.stackTrace != null) {
          // Format the stack trace
          final chain = Chain.forTrace(record.stackTrace!);
          final trace = chain.terse;
          print('Stack trace:\n$trace');
        }
      }
    });

    hierarchicalLoggingEnabled = true;
    _loggingInitialized = true;
  }

  /// Get a logger instance with the specified name.
  /// The name should be in the format 'component_name' without brackets.
  static Logger getLogger(String name) {
    if (!_loggingInitialized) {
      initializeLogging();
    }
    // Remove any extra brackets to prevent double bracketing
    final cleanName = name.replaceAll(RegExp(r'^\[+|\]+$'), '');
    return Logger(cleanName);
  }

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
        _routesLogger.info(
            '****** Environment: DEV, not handling local server, make sure to run the opencv server');
        Environment.setShouldHandleLocalServer(false);
        //supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
        //supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
        _dio.options.baseUrl = backendAPIUrl;
        break;
      case EnvironmentType.PROD:
        _routesLogger.info('****** Environment: PROD');
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

  /// Clean up logging resources when the app is disposed
  static void dispose() {
    _logSubscription?.cancel();
    Logger.root.clearListeners();
    _loggingInitialized = false;
  }
}
