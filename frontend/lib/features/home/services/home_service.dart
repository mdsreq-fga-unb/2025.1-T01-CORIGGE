import 'package:corigge/features/templates/data/answer_sheet_identifiable_box.dart';
import 'package:corigge/utils/image_bounding_box/data/box_details.dart';
import 'package:corigge/utils/utils.dart';
import 'dart:math';

class HomeService {
  /// Extracts the starting question number from a box name
  static int extractStartingQuestionNumber(String boxName) {
    // Extract question number from box names like "column_ac_1", "type_b_21", etc.
    if (boxName.contains('_')) {
      final parts = boxName.split('_');
      if (parts.length >= 2) {
        final questionNum = int.tryParse(parts.last);
        if (questionNum != null) {
          return questionNum;
        }
      }
    }
    return 1; // Default to 1 if parsing fails
  }

  /// Calculates the number of questions in a question box based on circles
  static int calculateQuestionCount(AnswerSheetIdentifiableBox box) {
    // Each question typically has 5 answer options (A, B, C, D, E)
    // So the number of questions = total circles / 5
    if (box.circles.isEmpty) {
      return 0;
    }

    // Assuming 5 answer options per question
    const int answersPerQuestion = 5;
    return (box.circles.length / answersPerQuestion).floor();
  }

  /// Calculates the number of rows and columns for a matricula box
  static MatriculaInfo calculateMatriculaInfo(AnswerSheetIdentifiableBox box) {
    if (box.circles.isEmpty) {
      return MatriculaInfo(rows: 0, columns: 0, totalCircles: 0);
    }

    // Sort circles by position to determine grid layout
    final sortedCircles = List.from(box.circles)
      ..sort((a, b) {
        // Sort by Y position first (rows), then X position (columns)
        final yDiff = a.center.dy.compareTo(b.center.dy);
        if (yDiff != 0) return yDiff;
        return a.center.dx.compareTo(b.center.dx);
      });

    // Calculate rows by finding unique Y positions (with tolerance for alignment)
    final rows = _calculateRows(sortedCircles);

    // Calculate columns by finding unique X positions (with tolerance for alignment)
    final columns = _calculateColumns(sortedCircles);

    return MatriculaInfo(
      rows: rows,
      columns: columns,
      totalCircles: box.circles.length,
    );
  }

  /// Builds a description of question ranges for all question boxes
  static String buildQuestionRangesDescription(
      List<AnswerSheetIdentifiableBox> questionBoxes) {
    final ranges = <String>[];

    for (final box in questionBoxes) {
      final startingQuestion = extractStartingQuestionNumber(box.name);
      final questionCount = calculateQuestionCount(box);

      if (questionCount > 0) {
        final endQuestion = startingQuestion + questionCount - 1;
        if (questionCount == 1) {
          ranges.add('($startingQuestion)');
        } else {
          ranges.add('($startingQuestion-$endQuestion)');
        }
      }
    }

    return ranges.join(', ');
  }

  /// Gets all template questions from question boxes
  static List<int> getTemplateQuestions(
      List<AnswerSheetIdentifiableBox> questionBoxes) {
    List<int> templateQuestions = [];

    for (final box in questionBoxes) {
      final startingQuestion = extractStartingQuestionNumber(box.name);
      final questionCount = calculateQuestionCount(box);

      // Add all questions in this box's range
      for (int i = 0; i < questionCount; i++) {
        templateQuestions.add(startingQuestion + i);
      }
    }

    return templateQuestions..sort();
  }

  /// Organizes template boxes into question boxes and other boxes
  static BoxOrganizationResult organizeTemplateBoxes(
      List<AnswerSheetIdentifiableBox> boxes) {
    final questionBoxes = <Map<String, dynamic>>[];
    final otherBoxes = <String, dynamic>{};

    for (final box in boxes) {
      if (box.box.label == BoxDetailsType.colunaDeQuestoes ||
          box.box.label == BoxDetailsType.typeB) {
        // Parse question box details
        final startingQuestion = extractStartingQuestionNumber(box.name);
        final questionCount = calculateQuestionCount(box);

        questionBoxes.add({
          'box': box,
          'startingQuestion': startingQuestion,
          'questionCount': questionCount,
          'typeName': Utils.getBoxNameByLabel(box),
        });
      } else if (box.box.label == BoxDetailsType.matricula) {
        // Calculate matricula info
        final matriculaInfo = calculateMatriculaInfo(box);
        final typeName = Utils.getBoxNameByLabel(box);

        otherBoxes[typeName] = {
          'count': (otherBoxes[typeName]?['count'] ?? 0) + 1,
          'matriculaInfo': matriculaInfo,
        };
      } else {
        // Count other box types
        final typeName = Utils.getBoxNameByLabel(box);
        otherBoxes[typeName] = {
          'count': (otherBoxes[typeName]?['count'] ?? 0) + 1,
        };
      }
    }

    // Sort question boxes by starting question number
    questionBoxes
        .sort((a, b) => a['startingQuestion'].compareTo(b['startingQuestion']));

    return BoxOrganizationResult(
      questionBoxes: questionBoxes,
      otherBoxes: otherBoxes,
    );
  }

  /// Calculates the number of rows in a grid of circles
  static int _calculateRows(List<dynamic> sortedCircles) {
    if (sortedCircles.isEmpty) return 0;

    final uniqueYPositions = <double>[];
    const double tolerance = 0.02; // 2% tolerance for alignment

    for (final circle in sortedCircles) {
      final y = circle.center.dy;
      bool foundSimilar = false;

      for (final existingY in uniqueYPositions) {
        if ((y - existingY).abs() < tolerance) {
          foundSimilar = true;
          break;
        }
      }

      if (!foundSimilar) {
        uniqueYPositions.add(y);
      }
    }

    return uniqueYPositions.length;
  }

  /// Calculates the number of columns in a grid of circles
  static int _calculateColumns(List<dynamic> sortedCircles) {
    if (sortedCircles.isEmpty) return 0;

    final uniqueXPositions = <double>[];
    const double tolerance = 0.02; // 2% tolerance for alignment

    for (final circle in sortedCircles) {
      final x = circle.center.dx;
      bool foundSimilar = false;

      for (final existingX in uniqueXPositions) {
        if ((x - existingX).abs() < tolerance) {
          foundSimilar = true;
          break;
        }
      }

      if (!foundSimilar) {
        uniqueXPositions.add(x);
      }
    }

    return uniqueXPositions.length;
  }
}

/// Data class for matricula information
class MatriculaInfo {
  final int rows;
  final int columns;
  final int totalCircles;

  MatriculaInfo({
    required this.rows,
    required this.columns,
    required this.totalCircles,
  });
}

/// Data class for organized box information
class BoxOrganizationResult {
  final List<Map<String, dynamic>> questionBoxes;
  final Map<String, dynamic> otherBoxes;

  BoxOrganizationResult({
    required this.questionBoxes,
    required this.otherBoxes,
  });
}
