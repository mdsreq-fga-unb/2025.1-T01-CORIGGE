import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final log = Logger('OpenCVService');

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
enum WebsocketMessageCommand { readToImages, findCircles, ping }

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
    switch (status.toLowerCase()) {
      case 'connected':
        return WebsocketMessageStatus.connected;
      case 'sending_chunk':
        return WebsocketMessageStatus.sendingChunk;
      case 'final_chunk':
        return WebsocketMessageStatus.finalChunk;
      case 'progress':
        return WebsocketMessageStatus.progress;
      case 'completed_task':
        return WebsocketMessageStatus.completedTask;
      case 'error':
        return WebsocketMessageStatus.error;
      case 'pong':
        return WebsocketMessageStatus.pong;
      default:
        throw Exception('Unknown status: $status');
    }
  }
}

class OpenCVService {
  static const String _wsUrl = 'ws://localhost:8765';
  static WebSocketChannel? _channel;
  static final Map<String, Completer<ServerResponse>> _taskCompleters = {};
  static final Map<String, void Function(String)> _progressCallbacks = {};
  static StreamSubscription? _subscription;
  static bool _isConnected = false;

  /// Initialize the WebSocket connection
  static Future<void> connect() async {
    if (_isConnected) {
      log.info('Already connected to WebSocket server');
      return;
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      // Wait for connection confirmation
      final completer = Completer<void>();

      // Add timeout for connection
      Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.completeError('Connection timeout');
        }
      });

      // Create a broadcast stream to allow multiple listeners
      final broadcastStream = _channel!.stream.asBroadcastStream();

      // Set up the message handler
      _setupMessageHandler(broadcastStream);

      // Listen for the initial connection message
      broadcastStream.listen(
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
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError('Failed to parse server response: $e');
            }
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError('WebSocket error: $error');
          }
          _isConnected = false;
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError('WebSocket connection closed');
          }
          _isConnected = false;
        },
      );

      await completer.future;

      log.info('Connected to WebSocket server');
    } catch (e) {
      _isConnected = false;
      log.severe('Failed to connect to WebSocket server: $e');
      throw Exception('Failed to connect to WebSocket server: $e');
    }
  }

  /// Set up the WebSocket message handler
  static void _setupMessageHandler(Stream<dynamic> stream) {
    _subscription?.cancel();
    _subscription = stream.listen(
      (message) {
        try {
          final response = ServerResponse.fromJson(jsonDecode(message));
          final taskId = response.data?['task_id'] as String?;

          switch (response.status) {
            case WebsocketMessageStatus.progress:
              if (taskId != null && _progressCallbacks.containsKey(taskId)) {
                _progressCallbacks[taskId]?.call(response.data!['message']);
              }
              break;
            case WebsocketMessageStatus.completedTask:
            case WebsocketMessageStatus.error:
              if (taskId != null && _taskCompleters.containsKey(taskId)) {
                final completer = _taskCompleters.remove(taskId)!;
                if (response.status == WebsocketMessageStatus.error) {
                  completer.completeError(response.data!['error']);
                } else {
                  completer.complete(response);
                }
              }
              break;
            default:
              // Handle other message types if needed
              break;
          }
        } catch (e) {
          log.warning('Error processing message: $e');
        }
      },
      onError: (error) {
        log.severe('WebSocket error: $error');
        _isConnected = false;
      },
      onDone: () {
        log.info('WebSocket connection closed');
        _isConnected = false;
      },
    );
  }

  /// Send a file to the server in chunks
  static Future<void> _sendFileInChunks(
      String taskId, List<int> fileData, String fileId) async {
    const int chunkSize =
        1024 * 200; // 200KB chunks as defined in the Python server

    for (var i = 0; i < fileData.length; i += chunkSize) {
      final chunk = fileData.sublist(
        i,
        i + chunkSize > fileData.length ? fileData.length : i + chunkSize,
      );

      final isLastChunk = i + chunkSize >= fileData.length;
      final status = isLastChunk
          ? WebsocketMessageStatus.finalChunk
          : WebsocketMessageStatus.sendingChunk;

      _channel!.sink.add(jsonEncode({
        'status': status.toString().split('.').last.toLowerCase(),
        'data': {
          'task_id': taskId,
          'chunk': base64Encode(chunk),
          'file_id': fileId,
        },
      }));
    }
  }

  /// Send a command to the server
  static Future<ServerResponse> _sendCommand(
    WebsocketMessageCommand command,
    String taskId,
    Map<String, dynamic> data,
    void Function(String)? onProgress,
  ) async {
    if (!_isConnected) {
      throw Exception('Not connected to WebSocket server');
    }

    final completer = Completer<ServerResponse>();
    _taskCompleters[taskId] = completer;
    if (onProgress != null) {
      _progressCallbacks[taskId] = onProgress;
    }

    _channel!.sink.add(jsonEncode({
      'command': command.toString().split('.').last.toLowerCase(),
      'data': {
        'task_id': taskId,
        ...data,
      },
    }));

    return completer.future;
  }

  /// Convert PDF to images
  static Future<Map<String, dynamic>> convertPdfToImages(
    List<int> pdfData,
    String filename, {
    void Function(String)? onProgress,
  }) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileId = 'pdf_$taskId';

    await _sendFileInChunks(taskId, pdfData, fileId);

    final response = await _sendCommand(
      WebsocketMessageCommand.readToImages,
      taskId,
      {
        'file_ids': [fileId],
        'filename': filename,
      },
      onProgress,
    );

    return response.data!;
  }

  /// Find circles in images
  static Future<Map<String, dynamic>> findCircles(
    List<int> imageData,
    Map<String, dynamic> options, {
    void Function(String)? onProgress,
  }) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileId = 'image_$taskId';

    await _sendFileInChunks(taskId, imageData, fileId);

    final response = await _sendCommand(
      WebsocketMessageCommand.findCircles,
      taskId,
      {
        'file_ids': [fileId],
        ...options,
      },
      onProgress,
    );

    return response.data!;
  }

  /// Check server connection with ping
  static Future<bool> ping() async {
    if (!_isConnected) return false;

    try {
      final taskId = DateTime.now().millisecondsSinceEpoch.toString();
      await _sendCommand(
        WebsocketMessageCommand.ping,
        taskId,
        {},
        null,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Disconnect from the WebSocket server
  static Future<void> disconnect() async {
    _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _taskCompleters.clear();
    _progressCallbacks.clear();
    log.info('Disconnected from WebSocket server');
  }

  // Private constructor to prevent instantiation
  OpenCVService._();
}
