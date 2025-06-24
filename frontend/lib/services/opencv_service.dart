import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:async/async.dart';
import 'package:archive/archive.dart';

final log = Logger("OpenCVService");

class OpenCVService {
  static const String _assetBasePath = 'assets/lib';
  static String? _executablePath;
  static Process? _process;
  static bool _isShuttingDown = false;

  // Register shutdown handler when the class is loaded
  static void _ensureShutdownHandler() {
    if (!_isShuttingDown) {
      // Handle app exit
      ProcessSignal.sigterm.watch().listen((_) => dispose());
      if (!Platform.isWindows) {
        ProcessSignal.sigint.watch().listen((_) => dispose());
      }
      _isShuttingDown = true;
    }
  }

  /// Returns the platform-specific executable name
  static String get _executableName {
    if (Platform.isWindows) {
      return 'main_processing_computer_local.exe';
    } else {
      return 'main_processing_computer_local/main_processing_computer_local';
    }
  }

  /// Returns the platform-specific folder name
  static String get _platformFolder {
    if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'darwin';
    } else {
      return 'linux';
    }
  }

  /// Initialize the service by unpacking the binary
  static Future<void> initialize() async {
    _ensureShutdownHandler();
    log.info('Initializing OpenCV service...');
    if (_executablePath != null) {
      log.info('OpenCV service already initialized at: $_executablePath');
      return;
    }

    try {
      final appDir = await _getApplicationDirectory();
      log.info('Using application directory: ${appDir.path}');

      final binDir = Directory(path.join(appDir.path, 'bin'));
      // Clean up any existing files/directories
      if (await binDir.exists()) {
        await binDir.delete(recursive: true);
      }
      await binDir.create(recursive: true);
      log.info('Created bin directory at: ${binDir.path}');

      // Load and extract the zip file
      final zipAsset = '$_assetBasePath/$_platformFolder/opencv_executable.zip';
      log.info('Loading executable zip from assets: $zipAsset');

      try {
        // Read the zip file from assets
        final zipBytes = await rootBundle.load(zipAsset);
        final archive = ZipDecoder().decodeBytes(zipBytes.buffer.asUint8List());

        // Extract each file
        for (final file in archive) {
          final filePath = path.join(binDir.path, file.name);
          if (file.isFile) {
            final fileData = file.content as List<int>;
            final outFile = File(filePath);
            await outFile.parent.create(recursive: true);
            await outFile.writeAsBytes(fileData);
            log.info('Extracted: ${file.name}');
          }
        }

        log.info('Successfully extracted all files');
      } catch (e) {
        log.severe('Failed to extract executable zip: $e');
        throw Exception('Failed to extract executable zip: $e');
      }

      // Make the executable file executable on Unix systems
      if (!Platform.isWindows) {
        log.info('Setting executable permissions...');
        final execPath = path.join(binDir.path, _executableName);
        final result = await Process.run('chmod', ['+x', execPath]);
        if (result.exitCode != 0) {
          log.severe('Failed to set executable permissions: ${result.stderr}');
          throw Exception(
              'Failed to set executable permissions: ${result.stderr}');
        }
        log.info('Successfully set executable permissions');
      }

      _executablePath = path.join(binDir.path, _executableName);
      log.info('OpenCV service initialized successfully');
    } catch (e) {
      log.severe('Failed to initialize OpenCV service: $e');
      throw Exception('Failed to initialize OpenCV service: $e');
    }
  }

  /// Start the OpenCV process
  static Future<void> startProcess() async {
    _ensureShutdownHandler();
    log.info('Starting OpenCV process...');

    if (_executablePath == null) {
      const msg = 'OpenCV service not initialized. Call initialize() first.';
      log.severe(msg);
      throw Exception(msg);
    }

    if (_process != null) {
      const msg = 'Process already running';
      log.warning(msg);
      throw Exception(msg);
    }

    try {
      // On macOS, check file permissions
      if (Platform.isMacOS) {
        try {
          final result = await Process.run('ls', ['-l', _executablePath!]);
          log.info('File permissions: ${result.stdout}');
        } catch (e) {
          log.warning('Error checking binary permissions: $e');
        }
      }

      log.info('Launching process from: $_executablePath');

      // Create a broadcast stream controller for process output
      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();

      // Set up stream listeners with proper error handling
      _process = await Process.start(
        _executablePath!,
        [], // Add any command line arguments here if needed
        runInShell: Platform.isWindows,
      );

      if (_process == null) {
        throw Exception('Failed to start process');
      }

      log.info('Process started with PID: ${_process!.pid}');

      // Set up stream listeners with proper error handling
      _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (!line.contains('PyiFrozenFinder') &&
              !line.contains('find_spec:') &&
              !line.contains('# code object from')) {
            log.info('[OpenCV] $line');
            stdoutController.add(line);
          }
        },
        onError: (error) {
          log.severe('Error reading stdout: $error');
          stdoutController.addError(error);
        },
        cancelOnError: false,
      );

      _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (!line.contains('PyiFrozenFinder') &&
              !line.contains('find_spec:') &&
              !line.contains('# code object from')) {
            log.severe('[OpenCV][Error] $line');
            stderrController.add(line);
          }
        },
        onError: (error) {
          log.severe('Error reading stderr: $error');
          stderrController.addError(error);
        },
        cancelOnError: false,
      );

      // Handle process exit with proper cleanup
      unawaited(_process!.exitCode.then((code) {
        if (!_isShuttingDown) {
          if (code != 0) {
            log.severe('[OpenCV] Process exited unexpectedly with code: $code');
          } else {
            log.info('[OpenCV] Process exited with code: $code');
          }
          _process = null;

          // Clean up controllers
          stdoutController.close();
          stderrController.close();
        }
      }).onError((error, stackTrace) {
        if (!_isShuttingDown) {
          log.severe('Error waiting for process exit: $error\n$stackTrace');
          _process = null;

          // Clean up controllers on error
          stdoutController.close();
          stderrController.close();
        }
      }));

      // Check if process is still running after a short delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify process is running
      if (_process == null) {
        throw Exception('Process failed to start or terminated immediately');
      }

      try {
        final exitCode = await _process!.exitCode.timeout(
          const Duration(milliseconds: 1),
          onTimeout: () => -1,
        );

        if (exitCode != -1) {
          throw Exception(
              'Process terminated immediately with code: $exitCode');
        }
      } catch (e) {
        if (e.toString().contains('Process failed to start') ||
            e.toString().contains('Process terminated immediately')) {
          rethrow;
        }
      }
    } catch (e, stackTrace) {
      if (Platform.isMacOS &&
          e.toString().contains('Operation not permitted')) {
        log.severe(
            '''Failed to start OpenCV process due to macOS security restrictions.
Please ensure the app is properly signed with your development team ID.

Technical details:
$e
$stackTrace''');
        throw Exception(
            '''Failed to start OpenCV process due to macOS security restrictions.
Please ensure the app is properly signed with your development team ID.
Error: $e''');
      } else {
        log.severe('Failed to start OpenCV process: $e\n$stackTrace');
        throw Exception('Failed to start OpenCV process: $e');
      }
    }
  }

  /// Stop the OpenCV process
  static Future<void> stopProcess() async {
    if (_process != null) {
      _isShuttingDown = true;
      final pid = _process!.pid;
      log.info('Stopping OpenCV process (PID: $pid)...');

      try {
        _process!.kill();
        log.info('Kill signal sent to process');

        final exitCode = await _process!.exitCode;
        log.info('Process exited with code: $exitCode');
      } catch (e) {
        log.severe('Error stopping process: $e');
      } finally {
        _process = null;
        _isShuttingDown = false;
        log.info('Process reference cleared');
      }
    } else {
      log.info('No process to stop');
    }
  }

  /// Get the application directory where we can store our executable
  static Future<Directory> _getApplicationDirectory() async {
    log.info(
        'Getting application directory for platform: ${Platform.operatingSystem}');

    try {
      if (Platform.isWindows || Platform.isLinux) {
        final dir = await getApplicationSupportDirectory();
        log.info('Using application support directory: ${dir.path}');
        return dir;
      } else if (Platform.isMacOS) {
        final appSupport = await getApplicationSupportDirectory();
        final dir = Directory(path.join(appSupport.path, 'com.corigge.app'));
        log.info('Using macOS application directory: ${dir.path}');
        return dir;
      } else {
        const msg = 'Unsupported platform';
        log.severe(msg);
        throw Exception(msg);
      }
    } catch (e) {
      log.severe('Failed to get application directory: $e');
      rethrow;
    }
  }

  /// Clean up resources
  static Future<void> dispose() async {
    log.info('Disposing OpenCV service...');
    await stopProcess();
    log.info('OpenCV service disposed');
  }

  // Private constructor to prevent instantiation
  OpenCVService._();
}
