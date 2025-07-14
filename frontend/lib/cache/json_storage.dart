import 'dart:convert';
import 'dart:io';
import 'package:corigge/features/login/data/user_model.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:corigge/environment.dart';

/// A class to handle persistent JSON storage for user data
/// Each user gets their own JSON file in the app's directory
class JsonStorage {
  static final _log = Environment.getLogger('[json_storage]');
  static const _userDataFolder = 'user_data';

  /// Returns the directory where user data is stored
  static Future<Directory> get _baseDir async {
    // Get the directory where the app executable is located
    final exePath = Platform.resolvedExecutable;
    final appDir = Directory(path.dirname(exePath));
    final userDataDir = Directory(path.join(appDir.path, _userDataFolder));

    if (!await userDataDir.exists()) {
      await userDataDir.create(recursive: true);
    }

    return userDataDir;
  }

  /// Returns the path to a user's JSON file
  static Future<String> _getUserFilePath(String userId) async {
    final dir = await _baseDir;
    return path.join(dir.path, '$userId.json');
  }

  /// Saves data for a specific user
  /// [userId] - The unique identifier for the user
  /// [key] - The key under which to store the data
  /// [data] - The data to store (must be JSON serializable)
  static Future<void> saveUserData(
      String userId, String key, dynamic data) async {
    try {
      final filePath = await _getUserFilePath(userId);
      final file = File(filePath);

      Map<String, dynamic> jsonData = {};

      // Read existing data if file exists
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          jsonData = json.decode(content) as Map<String, dynamic>;
        }
      }

      // Update data
      jsonData[key] = data;

      // Write back to file
      await file.writeAsString(json.encode(jsonData), flush: true);
      _log.info('Saved data for user $userId with key $key');
    } catch (e) {
      _log.severe('Error saving data for user $userId: $e');
      rethrow;
    }
  }

  /// Retrieves data for a specific user
  /// [userId] - The unique identifier for the user
  /// [key] - The key of the data to retrieve
  /// Returns null if the key doesn't exist
  static Future<T?> getUserData<T>(String userId, String key) async {
    try {
      final filePath = await _getUserFilePath(userId);
      final file = File(filePath);

      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return null;
      }

      final jsonData = json.decode(content) as Map<String, dynamic>;
      return jsonData[key] as T?;
    } catch (e) {
      _log.severe('Error reading data for user $userId: $e');
      rethrow;
    }
  }

  /// Removes data for a specific user
  /// [userId] - The unique identifier for the user
  /// [key] - The key of the data to remove
  /// If key is null, removes all data for the user
  static Future<void> removeUserData(String userId, [String? key]) async {
    try {
      final filePath = await _getUserFilePath(userId);
      final file = File(filePath);

      if (!await file.exists()) {
        return;
      }

      if (key == null) {
        // Remove entire file
        await file.delete();
        _log.info('Removed all data for user $userId');
        return;
      }

      // Remove specific key
      final content = await file.readAsString();
      if (content.isEmpty) {
        return;
      }

      final jsonData = json.decode(content) as Map<String, dynamic>;
      jsonData.remove(key);

      // Write back to file
      await file.writeAsString(json.encode(jsonData), flush: true);
      _log.info('Removed data for user $userId with key $key');
    } catch (e) {
      _log.severe('Error removing data for user $userId: $e');
      rethrow;
    }
  }

  /// Lists all stored keys for a user
  /// [userId] - The unique identifier for the user
  static Future<List<String>> listUserKeys(String userId) async {
    try {
      final filePath = await _getUserFilePath(userId);
      final file = File(filePath);

      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return [];
      }

      final jsonData = json.decode(content) as Map<String, dynamic>;
      return jsonData.keys.toList();
    } catch (e) {
      _log.severe('Error listing keys for user $userId: $e');
      rethrow;
    }
  }

  /// Checks if data exists for a user
  /// [userId] - The unique identifier for the user
  /// [key] - Optional key to check for specific data
  static Future<bool> hasUserData(String userId, [String? key]) async {
    try {
      final filePath = await _getUserFilePath(userId);
      final file = File(filePath);

      if (!await file.exists()) {
        return false;
      }

      if (key == null) {
        return true;
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return false;
      }

      final jsonData = json.decode(content) as Map<String, dynamic>;
      return jsonData.containsKey(key);
    } catch (e) {
      _log.severe('Error checking data for user $userId: $e');
      rethrow;
    }
  }

  /// Gets the size of stored data for a user in bytes
  /// [userId] - The unique identifier for the user
  static Future<int> getUserDataSize(String userId) async {
    try {
      final filePath = await _getUserFilePath(userId);
      final file = File(filePath);

      if (!await file.exists()) {
        return 0;
      }

      return await file.length();
    } catch (e) {
      _log.severe('Error getting data size for user $userId: $e');
      rethrow;
    }
  }

  /// Gets the absolute path to the user data directory
  /// Useful for backup/restore operations
  static Future<String> getUserDataDirectory() async {
    final dir = await _baseDir;
    return dir.path;
  }

  /// Lists all user IDs that have stored data
  static Future<List<String>> listAllUsers() async {
    try {
      final dir = await _baseDir;
      if (!await dir.exists()) {
        return [];
      }

      final List<String> users = [];
      await for (final entity in dir.list()) {
        if (entity is File && path.extension(entity.path) == '.json') {
          final fileName = path.basenameWithoutExtension(entity.path);
          users.add(fileName);
        }
      }
      return users;
    } catch (e) {
      _log.severe('Error listing users: $e');
      rethrow;
    }
  }

  static Future<void> updateUserData(
      UserModel user, Function(Map<String, dynamic>) updateFunction) async {
    var userData = await getUserData(user.id!.toString(), 'userData') ?? {};
    updateFunction(userData);
    await saveUserData(user.id!.toString(), 'userData', userData);
  }
}
