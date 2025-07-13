import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';
import 'package:corigge/environment.dart';
import 'package:path_provider/path_provider.dart';

import '../features/login/data/user_model.dart';
import '../features/templates/data/answer_sheet_template_model.dart';
import '../features/templates/data/answer_sheet_card_model.dart';

final log = Environment.getLogger('[shared_preferences]');

class SharedPreferencesHelper {
  static final String _keyUserData = 'user_data';

  static UserModel? currentUser;

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<Either<String, List<AnswerSheetTemplateModel>>>
      loadTemplates() async {
    try {
      final templatesJson = _prefs?.getString('templates') ?? '[]';
      final List<dynamic> templatesData = json.decode(templatesJson);
      return Right(templatesData
          .map((e) => AnswerSheetTemplateModel.fromJson(e))
          .toList());
    } catch (e) {
      return Left(e.toString());
    }
  }

  static Future<void> saveTemplates(
      List<AnswerSheetTemplateModel> templates) async {
    final templatesJson =
        json.encode(templates.map((e) => e.toJson()).toList());
    await _prefs?.setString('templates', templatesJson);
  }

  static Future<Directory> _getImageDirectory() async {
    if (Platform.isMacOS) {
      // For macOS, use the app bundle's Resources directory
      final executablePath = Platform.resolvedExecutable;
      final appBundle = Directory(path.dirname(path.dirname(executablePath)));
      final resourcesDir = Directory(
          path.join(appBundle.path, 'Contents', 'Resources', 'images'));

      if (!await resourcesDir.exists()) {
        await resourcesDir.create(recursive: true);
      }

      return resourcesDir;
    } else {
      // For other platforms, use the executable directory as before
      final executablePath = Platform.resolvedExecutable;
      final executableDir = Directory(path.dirname(executablePath));
      final imagesDir = Directory(path.join(executableDir.path, 'images'));

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      return imagesDir;
    }
  }

  static Future<void> saveImage(dynamic bytes, String key) async {
    log.info("[saveImage] Saving image $key");
    final imagesDir = await _getImageDirectory();
    final file = File(path.join(imagesDir.path, key));
    if (bytes is Uint8List) {
      await file.writeAsBytes(bytes);
    } else {
      await file.writeAsBytes(Uint8List.fromList(List<int>.from(bytes)));
    }
  }

  static Future<Uint8List?> getImage(String key) async {
    log.info("[getImage] Getting image $key");
    final imagesDir = await _getImageDirectory();
    final file = File(path.join(imagesDir.path, key));
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  }

  static Future<bool> imageExists(String key) async {
    log.info("[imageExists] Checking if image $key exists");
    final imagesDir = await _getImageDirectory();
    final file = File(path.join(imagesDir.path, key));
    return await file.exists();
  }

  static Future<void> saveOrUpdateUserData(UserModel user) async {
    currentUser = user;
    final userJson = json.encode(user.toJson());
    await _prefs?.setString('user_data', userJson);
  }

  static Future<UserModel?> getUserData() async {
    final userJson = _prefs?.getString('user_data');
    if (userJson == null) return null;
    final userData = json.decode(userJson);
    return UserModel.fromJson(userData);
  }

  static Future<void> clearUserData() async {
    currentUser = null;
    await _prefs?.remove('user_data');
  }

  static Future<void> saveSelectedTemplate(
      AnswerSheetTemplateModel? template) async {
    if (template == null) {
      await _prefs?.remove('selected_template');
    } else {
      final templateJson = json.encode(template.toJson());
      await _prefs?.setString('selected_template', templateJson);
    }
  }

  static Future<AnswerSheetTemplateModel?> getSelectedTemplate() async {
    final templateJson = _prefs?.getString('selected_template');
    if (templateJson == null) return null;
    final templateData = json.decode(templateJson);
    return AnswerSheetTemplateModel.fromJson(templateData);
  }

  static Future<String> getFilePath(String fileName) async {
    final executablePath = Platform.resolvedExecutable;
    final executableDir = Directory(path.dirname(executablePath));
    final filePath = path.join(executableDir.path, fileName);
    return filePath;
  }

  static Future<Uint8List> readFileAsBytes(String filePath) async {
    return File(filePath).readAsBytes();
  }

  static Future<Either<String, List<AnswerSheetCardModel>>> loadCards() async {
    try {
      final cardsJson = _prefs?.getString('answer_sheet_cards') ?? '[]';
      final List<dynamic> cardsData = json.decode(cardsJson);
      return Right(
          cardsData.map((e) => AnswerSheetCardModel.fromJson(e)).toList());
    } catch (e) {
      return Left(e.toString());
    }
  }

  static Future<void> saveCards(List<AnswerSheetCardModel> cards) async {
    final cardsJson = json.encode(cards.map((e) => e.toJson()).toList());
    await _prefs?.setString('answer_sheet_cards', cardsJson);
  }

  static Future<void> clearCards() async {
    await _prefs?.remove('answer_sheet_cards');
  }
}
