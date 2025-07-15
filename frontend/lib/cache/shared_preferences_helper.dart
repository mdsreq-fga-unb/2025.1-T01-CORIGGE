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
import '../features/templates/data/generated_template_model.dart';

final log = Environment.getLogger('[shared_preferences]');

class SharedPreferencesHelper {
  static const String _keyUserData = 'user_data';
  static const String _keyTemplates = 'templates';
  static const String _keySelectedTemplate = 'selected_template';
  static const String _keyAnswerSheetCards = 'answer_sheet_cards';
  static const String _keyGabaritoData = 'gabarito_data';
  static const String _keyRelatorioDefinitions = 'relatorio_definitions';
  static const String _keySelectedRelatorioDefinition =
      'selected_relatorio_definition';

  static UserModel? currentUser;

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<Either<String, List<AnswerSheetTemplateModel>>>
      loadTemplates() async {
    try {
      final templatesJson = _prefs?.getString(_keyTemplates) ?? '[]';
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
    await _prefs?.setString(_keyTemplates, templatesJson);
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
    await _prefs?.setString(_keyUserData, userJson);
  }

  static Future<UserModel?> getUserData() async {
    final userJson = _prefs?.getString(_keyUserData);
    if (userJson == null) return null;
    final userData = json.decode(userJson);
    return UserModel.fromJson(userData);
  }

  static Future<void> clearUserData() async {
    currentUser = null;
    await _prefs?.remove(_keyUserData);
  }

  static Future<void> saveSelectedTemplate(
      AnswerSheetTemplateModel? template) async {
    if (template == null) {
      await _prefs?.remove(_keySelectedTemplate);
    } else {
      final templateJson = json.encode(template.toJson());
      await _prefs?.setString(_keySelectedTemplate, templateJson);
    }
  }

  static Future<AnswerSheetTemplateModel?> getSelectedTemplate() async {
    final templateJson = _prefs?.getString(_keySelectedTemplate);
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
      final cardsJson = _prefs?.getString(_keyAnswerSheetCards) ?? '[]';
      final List<dynamic> cardsData = json.decode(cardsJson);
      return Right(
          cardsData.map((e) => AnswerSheetCardModel.fromJson(e)).toList());
    } catch (e) {
      return Left(e.toString());
    }
  }

  static Future<void> saveCards(List<AnswerSheetCardModel> cards) async {
    final cardsJson = json.encode(cards.map((e) => e.toJson()).toList());
    await _prefs?.setString(_keyAnswerSheetCards, cardsJson);
  }

  static Future<void> clearCards() async {
    await _prefs?.remove(_keyAnswerSheetCards);
  }

  static Future<void> saveGabarito(List<Map<String, dynamic>> gabarito) async {
    final gabaritoJson = json.encode(gabarito);
    await _prefs?.setString(_keyGabaritoData, gabaritoJson);
  }

  static Future<Either<String, List<Map<String, dynamic>>>>
      loadGabarito() async {
    try {
      final gabaritoJson = _prefs?.getString(_keyGabaritoData) ?? '[]';
      final List<dynamic> gabaritoData = json.decode(gabaritoJson);
      return Right(gabaritoData.cast<Map<String, dynamic>>());
    } catch (e) {
      return Left(e.toString());
    }
  }

  static Future<void> clearGabarito() async {
    await _prefs?.remove(_keyGabaritoData);
  }

  // GeneratedTemplateModel methods
  static const String _keyGeneratedTemplates = 'generated_templates';

  static Future<Either<String, List<GeneratedTemplateModel>>>
      loadGeneratedTemplates() async {
    try {
      final templatesJson = _prefs?.getString(_keyGeneratedTemplates) ?? '[]';
      final List<dynamic> templatesData = json.decode(templatesJson);
      return Right(List<GeneratedTemplateModel>.from(templatesData
          .map((e) {
            try {
              return GeneratedTemplateModel.fromJson(e);
            } catch (e) {
              log.severe('[loadGeneratedTemplates] Error loading template: $e');
              return null;
            }
          })
          .where((e) => e != null)
          .toList()));
    } catch (e) {
      return Left(e.toString());
    }
  }

  static Future<void> saveGeneratedTemplates(
      List<GeneratedTemplateModel> templates) async {
    final templatesJson =
        json.encode(templates.map((e) => e.toJson()).toList());
    await _prefs?.setString(_keyGeneratedTemplates, templatesJson);
  }

  static Future<void> clearGeneratedTemplates() async {
    await _prefs?.remove(_keyGeneratedTemplates);
  }
}
