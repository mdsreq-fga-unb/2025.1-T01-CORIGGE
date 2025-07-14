import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:corigge/environment.dart';
import 'package:flutter/material.dart';
import 'package:corigge/utils/image_bounding_box/data/image_circle.dart';
import 'package:corigge/utils/image_bounding_box/data/box_with_label_and_name.dart';
import 'package:corigge/utils/image_bounding_box/data/pdf_to_images_result.dart';
import 'package:corigge/features/templates/data/python_circle_identification_params.dart';
import 'package:dartz/dartz.dart';

final log = Environment.getLogger('opencv_service');

/// A simple class to handle file data, similar to PlatformFile
class FileData {
  /// The name of the file
  final String name;

  /// The size of the file in bytes
  final int size;

  /// The bytes of the file
  final List<int> bytes;

  FileData({
    required this.name,
    required this.size,
    required this.bytes,
  });
}

/// Status codes for WebSocket messages as defined in the Python server
enum WebsocketMessageStatus {
  connected,
  sendingChunk,
  finalChunk,
  progress,
  completedTask,
  error,
  pong
}

/// Commands that can be sent to the Python server
enum WebsocketMessageCommand {
  readToImages,
  findCircles,
  ping,
  identifyCircles,
  getCalibration
}

/// Represents a response from the server
class ServerResponse {
  final WebsocketMessageStatus status;
  final Map<String, dynamic>? data;

  ServerResponse(this.status, this.data);

  factory ServerResponse.fromJson(Map<String, dynamic> json) {
    return ServerResponse(
      _parseStatus(json['status']),
      json['data'] as Map<String, dynamic>?,
    );
  }

  static WebsocketMessageStatus _parseStatus(String status) {
    return WebsocketMessageStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => WebsocketMessageStatus.error,
    );
  }
}

class OpenCVService {
  static const String _wsUrl = 'ws://localhost:8765';
  static WebSocketChannel? _channel;
  static final Map<String, Completer<ServerResponse>> _taskCompleters = {};
  static final Map<String, void Function(String)> _progressCallbacks = {};
  static StreamSubscription? _subscription;
  static bool _isConnected = false;
  static Stream<dynamic>? _broadcastStream;

  /// Initialize the WebSocket connection
  static Future<void> connect({int maxRetries = 5}) async {
    if (_isConnected) {
      log.info('[connect] Already connected to WebSocket server');
      return;
    }

    if (!Environment.shouldHandleLocalServer) {
      // When not handling local server, just try to connect once without retries
      try {
        log.info(
            '[connect] Attempting to connect to WebSocket server (no retries)');
        _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
        _broadcastStream = _channel!.stream.asBroadcastStream();

        // Wait for connection confirmation
        final completer = Completer<void>();

        // Add timeout for connection
        Timer(const Duration(seconds: 5), () {
          if (!completer.isCompleted) {
            completer.completeError('Connection timeout', StackTrace.current);
          }
        });

        // Set up the message handler
        _setupMessageHandler(_broadcastStream!);

        // Listen for the initial connection message
        _broadcastStream!.listen(
          (message) {
            try {
              final response = ServerResponse.fromJson(jsonDecode(message));

              // The server sends a welcome message
              if (!completer.isCompleted) {
                if (response.data != null &&
                    response.data!['message'] != null &&
                    response.data!['message']
                        .toString()
                        .contains('Connected to local processing server')) {
                  _isConnected = true;
                  completer.complete();
                }
              }
            } catch (e, stackTrace) {
              if (!completer.isCompleted) {
                completer.completeError(
                    'Failed to parse server response: $e', stackTrace);
              }
            }
          },
          onError: (error, stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError('WebSocket error: $error', stackTrace);
            }
            _isConnected = false;
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.completeError(
                  'WebSocket connection closed', StackTrace.current);
            }
            _isConnected = false;
          },
        );

        await completer.future;
        log.info(
            '[connect] Successfully connected to WebSocket server at $_wsUrl');
        return;
      } catch (e, stackTrace) {
        _isConnected = false;
        log.warning('[connect] Failed to connect to WebSocket server: $e', e,
            stackTrace);
        // Don't throw when not handling local server, just log the error
        return;
      }
    }

    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        // Wait a bit before attempting to connect, increasing delay with each retry
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));

        log.info(
            '[connect] Attempting to connect to WebSocket server (attempt ${retryCount + 1}/$maxRetries)');
        _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
        _broadcastStream = _channel!.stream.asBroadcastStream();

        // Wait for connection confirmation
        final completer = Completer<void>();

        // Add timeout for connection
        Timer(const Duration(seconds: 5), () {
          if (!completer.isCompleted) {
            completer.completeError('Connection timeout', StackTrace.current);
          }
        });

        // Set up the message handler
        _setupMessageHandler(_broadcastStream!);

        // Listen for the initial connection message
        _broadcastStream!.listen(
          (message) {
            try {
              final response = ServerResponse.fromJson(jsonDecode(message));

              // The server sends a welcome message
              if (!completer.isCompleted) {
                if (response.data != null &&
                    response.data!['message'] != null &&
                    response.data!['message']
                        .toString()
                        .contains('Connected to local processing server')) {
                  _isConnected = true;
                  completer.complete();
                }
              }
            } catch (e, stackTrace) {
              if (!completer.isCompleted) {
                completer.completeError(
                    'Failed to parse server response: $e', stackTrace);
              }
            }
          },
          onError: (error, stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError('WebSocket error: $error', stackTrace);
            }
            _isConnected = false;
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.completeError(
                  'WebSocket connection closed', StackTrace.current);
            }
            _isConnected = false;
          },
        );

        await completer.future;
        log.info(
            '[connect] Successfully connected to WebSocket server at $_wsUrl');
        return; // Exit the retry loop on success
      } catch (e, stackTrace) {
        _isConnected = false;
        retryCount++;

        if (retryCount >= maxRetries) {
          log.severe(
              '[connect] Failed to connect to WebSocket server after $maxRetries attempts: $e',
              e,
              stackTrace);
          throw Exception(
              'Failed to connect to WebSocket server after $maxRetries attempts: $e');
        } else {
          log.warning(
              '[connect] Connection attempt $retryCount failed, retrying...',
              e,
              stackTrace);
        }
      }
    }
  }

  /// Set up the WebSocket message handler
  static void _setupMessageHandler(Stream<dynamic> stream) {
    log.info('[_setupMessageHandler] Setting up new WebSocket message handler');
    _subscription?.cancel();
    _subscription = stream.listen(
      (message) {
        try {
          final response = ServerResponse.fromJson(jsonDecode(message));
          final taskId = response.data?['task_id'] as String?;
          log.fine(
              '[_setupMessageHandler] Received message with status: ${response.status}, taskId: $taskId');

          switch (response.status) {
            case WebsocketMessageStatus.progress:
              if (taskId != null && _progressCallbacks.containsKey(taskId)) {
                log.fine(
                    '[_setupMessageHandler] Processing progress update for task: $taskId');
                _progressCallbacks[taskId]?.call(response.data!['message']);
              }
              break;
            case WebsocketMessageStatus.completedTask:
              if (taskId != null && _taskCompleters.containsKey(taskId)) {
                log.info(
                    '[_setupMessageHandler] Task completed successfully: $taskId');
                final completer = _taskCompleters.remove(taskId)!;
                completer.complete(response);
              }
              break;
            case WebsocketMessageStatus.error:
              if (taskId != null && _taskCompleters.containsKey(taskId)) {
                final error = response.data!['error'];
                log.warning(
                    '[_setupMessageHandler] Task failed with error: $error, taskId: $taskId',
                    error,
                    StackTrace.current);
                final completer = _taskCompleters.remove(taskId)!;
                completer.completeError(error);
              }
              break;
            default:
              log.fine(
                  '[_setupMessageHandler] Received message with status: ${response.status}');
              break;
          }
        } catch (e, stackTrace) {
          log.warning('[_setupMessageHandler] Error processing message: $e', e,
              stackTrace);
        }
      },
      onError: (error, stackTrace) {
        log.severe('[_setupMessageHandler] WebSocket error: $error', error,
            stackTrace);
        _isConnected = false;
      },
      onDone: () {
        log.info('[_setupMessageHandler] WebSocket connection closed');
        _isConnected = false;
      },
    );
  }

  /// Send a file to the server in chunks
  static Future<void> _sendFileInChunks(
      String taskId, List<int> fileData, String fileId) async {
    const int chunkSize =
        1024 * 200; // 200KB chunks as defined in the Python server
    final totalChunks = (fileData.length / chunkSize).ceil();
    log.info(
        '[_sendFileInChunks] Starting to send file $fileId in $totalChunks chunks for task $taskId');

    for (var i = 0; i < fileData.length; i += chunkSize) {
      final chunk = fileData.sublist(
        i,
        i + chunkSize > fileData.length ? fileData.length : i + chunkSize,
      );

      final isLastChunk = i + chunkSize >= fileData.length;
      final status = isLastChunk
          ? WebsocketMessageStatus.finalChunk
          : WebsocketMessageStatus.sendingChunk;

      final currentChunk = (i ~/ chunkSize) + 1;
      log.fine(
          '[_sendFileInChunks] Sending chunk $currentChunk/$totalChunks for file $fileId');

      _channel!.sink.add(jsonEncode({
        'status': status.toString().split('.').last,
        'data': {
          'task_id': taskId,
          'chunk': base64Encode(chunk),
          'file_id': fileId,
        },
      }));
    }
    log.info(
        '[_sendFileInChunks] Completed sending file $fileId for task $taskId');
  }

  /// Send a command to the server
  static Future<ServerResponse> _sendCommand(
    WebsocketMessageCommand command,
    String taskId,
    Map<String, dynamic> data,
    void Function(String)? onProgress,
  ) async {
    if (!_isConnected) {
      log.severe(
          '[_sendCommand] Attempted to send command while not connected to WebSocket server');
      throw Exception('Not connected to WebSocket server');
    }

    log.info(
        '[_sendCommand] Sending command: ${command.toString().split('.').last}, taskId: $taskId');
    final completer = Completer<ServerResponse>();
    _taskCompleters[taskId] = completer;
    if (onProgress != null) {
      _progressCallbacks[taskId] = onProgress;
    }

    _channel!.sink.add(jsonEncode({
      'command': command.toString().split('.').last,
      'data': {
        'task_id': taskId,
        ...data,
      },
    }));

    return completer.future;
  }

  /// Convert PDF to images
  static Future<Either<String, PdfToImagesResult>> convertPdfToImages(
    FileData pdfData,
    String filename, {
    void Function(String)? onProgress,
  }) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    log.info(
        '[convertPdfToImages] Starting PDF conversion for file: $filename, taskId: $taskId');

    try {
      if (_broadcastStream == null) {
        throw Exception('WebSocket stream not initialized');
      }

      final fileId = 'pdf_$taskId';
      log.info(
          '[convertPdfToImages] Sending PDF file in chunks, size: ${pdfData.size} bytes');

      // Create maps to store received image data
      final Map<String, List<int>> receivedImageChunks = {};
      final Map<String, dynamic> imageCalibrationRects = {};
      final Map<String, dynamic> imageSizes = {};
      final List<String> imageHashes = [];

      // Create completers to wait for the final response
      final completer = Completer<void>();
      final errorCompleter = Completer<String>();

      // Create a message handler for this specific task
      void messageHandler(dynamic message) {
        try {
          final response = ServerResponse.fromJson(jsonDecode(message));
          final responseTaskId = response.data?['task_id'] as String?;

          if (responseTaskId != taskId)
            return; // Ignore messages for other tasks

          switch (response.status) {
            case WebsocketMessageStatus.progress:
              if (onProgress != null) {
                onProgress(response.data!['message']);
              }
              break;

            case WebsocketMessageStatus.sendingChunk:
            case WebsocketMessageStatus.finalChunk:
              final imageHash = response.data!['file_id'] as String;
              if (!imageHashes.contains(imageHash)) {
                imageHashes.add(imageHash);
                receivedImageChunks[imageHash] = [];
              }
              final chunk = base64Decode(response.data!['chunk']);
              receivedImageChunks[imageHash]!.addAll(chunk);
              break;

            case WebsocketMessageStatus.completedTask:
              // Process final metadata
              for (var imageHash in response.data!['images_ids'] as List) {
                imageCalibrationRects[imageHash] =
                    response.data!['image_calibration_rects']?[imageHash] ?? {};
                imageSizes[imageHash] =
                    response.data!['image_sizes']?[imageHash] ?? {};
              }
              completer.complete();
              break;

            case WebsocketMessageStatus.error:
              errorCompleter.complete(response.data!['error']);
              break;

            default:
              // Ignore other message types
              break;
          }
        } catch (e, stackTrace) {
          log.severe(
              '[convertPdfToImages] Error processing message', e, stackTrace);
          if (!errorCompleter.isCompleted) {
            errorCompleter.complete(e.toString());
          }
        }
      }

      // Add our handler to the existing broadcast stream
      final subscription = _broadcastStream!.listen(messageHandler);

      await _sendFileInChunks(taskId, pdfData.bytes, fileId);

      // Send the command to start processing
      _channel!.sink.add(jsonEncode({
        'command':
            WebsocketMessageCommand.readToImages.toString().split('.').last,
        'data': {
          'task_id': taskId,
          'file_ids': [fileId],
          'filename': filename,
        },
      }));

      // Wait for either completion or error
      await Future.any([completer.future, errorCompleter.future]);

      // Clean up our subscription
      await subscription.cancel();

      if (errorCompleter.isCompleted) {
        throw Exception(await errorCompleter.future);
      }

      // Convert the received chunks into the final format
      final actualJson = {
        "calibration_rects": <String, dynamic>{},
        "image_sizes": <String, dynamic>{},
        "image_bytes": <String, List<int>>{},
      };

      for (var imageHash in imageHashes) {
        actualJson["image_bytes"]![imageHash] = receivedImageChunks[imageHash];
        actualJson["calibration_rects"]![imageHash] =
            Map<String, dynamic>.from(imageCalibrationRects[imageHash] ?? {});
        actualJson["image_sizes"]![imageHash] =
            Map<String, dynamic>.from(imageSizes[imageHash] ?? {});
      }

      log.info(
          '[convertPdfToImages] Successfully processed ${imageHashes.length} images');

      return Right(
          PdfToImagesResult.fromJson(Map<String, dynamic>.from(actualJson)));
    } catch (e, stackTrace) {
      log.severe('[convertPdfToImages] Failed to convert PDF', e, stackTrace);
      return Left(e.toString());
    }
  }

  /// Find circles in images
  static Future<Either<String, Map<String, List<ImageCircle>>>> findCircles(
    FileData imageData,
    List<BoxWithLabelAndName> boxes, {
    void Function(String)? onProgress,
    Offset? imageOffset,
    double? imageAngle,
    PythonCircleIdentificationParams? params,
  }) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    log.info(
        '[findCircles] Starting circle detection, taskId: $taskId, boxes count: ${boxes.length}');

    try {
      final fileId = 'image_$taskId';

      var dataToSend = {
        ...(params?.toJson() ?? {}),
        "boxes": boxes.map((e) => e.toJson()).toList(),
      };

      if (imageOffset != null) {
        log.fine('[findCircles] Using image offset: $imageOffset');
        dataToSend["image_offset"] = {
          "x": imageOffset.dx,
          "y": imageOffset.dy,
        };
      }

      if (imageAngle != null) {
        log.fine('[findCircles] Using image angle: $imageAngle');
        dataToSend["image_angle"] = imageAngle;
      }

      log.info(
          '[findCircles] Sending image file in chunks, size: ${imageData.size} bytes');
      await _sendFileInChunks(taskId, imageData.bytes, fileId);

      final response = await _sendCommand(
        WebsocketMessageCommand.findCircles,
        taskId,
        {
          'file_ids': [fileId],
          ...dataToSend,
        },
        onProgress,
      );

      final result =
          ((response.data!["circles"].values.first) as Map<String, dynamic>)
              .map((key, value) => MapEntry(
                  key,
                  List<ImageCircle>.from((value as List)
                      .map((e) => ImageCircle.fromJson(e))
                      .toList())));

      log.info(
          '[findCircles] Successfully detected circles in ${result.length} regions');
      return Right(result);
    } catch (e) {
      log.severe('[findCircles] Failed to detect circles: $e');
      return Left(e.toString());
    }
  }

  /// Count circles in a specific rectangle
  static Future<Either<String, Map<String, List<ImageCircle>>>>
      countCirclesInRect(
    FileData imageData,
    List<BoxWithLabelAndName> boxes, {
    void Function(String)? onProgress,
    PythonCircleIdentificationParams? params,
  }) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    log.info(
        '[countCirclesInRect] Starting circle counting, taskId: $taskId, boxes count: ${boxes.length}');

    try {
      final fileId = 'image_$taskId';

      var dataToSend = {
        ...(params?.toJson() ?? {}),
        "boxes": boxes.map((e) => e.toJson()).toList(),
      };

      log.info(
          '[countCirclesInRect] Sending image file in chunks, size: ${imageData.size} bytes');
      await _sendFileInChunks(taskId, imageData.bytes, fileId);

      final response = await _sendCommand(
        WebsocketMessageCommand.findCircles,
        taskId,
        {
          'file_ids': [fileId],
          ...dataToSend,
        },
        onProgress,
      );

      final result =
          ((response.data!["circles"].values.first) as Map<String, dynamic>)
              .map((key, value) => MapEntry(
                  key,
                  List<ImageCircle>.from((value as List)
                      .map((e) => ImageCircle.fromJson(e))
                      .toList())));

      log.info(
          '[countCirclesInRect] Successfully counted circles in ${result.length} regions');
      return Right(result);
    } catch (e) {
      log.severe('[countCirclesInRect] Failed to count circles: $e');
      return Left(e.toString());
    }
  }

  /// Check server connection with ping
  static Future<bool> ping() async {
    if (!_isConnected) {
      log.fine('[ping] Not connected to server, returning false');
      return false;
    }

    try {
      final taskId = DateTime.now().millisecondsSinceEpoch.toString();
      log.fine('[ping] Sending ping request, taskId: $taskId');
      await _sendCommand(
        WebsocketMessageCommand.ping,
        taskId,
        {},
        null,
      );
      log.fine('[ping] Ping successful');
      return true;
    } catch (e) {
      log.warning('[ping] Ping failed: $e');
      return false;
    }
  }

  /// Disconnect from the WebSocket server
  static Future<void> disconnect() async {
    log.info('[disconnect] Disconnecting from WebSocket server');
    _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _taskCompleters.clear();
    _progressCallbacks.clear();
    log.info('[disconnect] Successfully disconnected from WebSocket server');
  }

  // Private constructor to prevent instantiation
  OpenCVService._();
}
