import 'package:corigge/features/templates/data/answer_sheet_identifiable_box.dart';
import 'package:corigge/features/templates/data/answer_sheet_card_model.dart';
import 'package:corigge/features/templates/data/answer_sheet_template_model.dart';
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
    if (box.circles.isEmpty) {
      return 0;
    }

    // Sort circles by position to determine rows and columns
    final sortedCircles = List.from(box.circles)
      ..sort((a, b) {
        // Sort by Y position first (rows), then X position (columns)
        final yDiff = a.center.dy.compareTo(b.center.dy);
        if (yDiff != 0) return yDiff;
        return a.center.dx.compareTo(b.center.dx);
      });

    // Calculate number of rows and columns
    final rows = _calculateRows(sortedCircles);
    final columns = _calculateColumns(sortedCircles);

    if (rows == 0 || columns == 0) {
      return 0;
    }

    return rows;
  }

  /// Determines the question types in a column based on circle analysis
  static String getQuestionType(AnswerSheetIdentifiableBox box) {
    if (box.circles.isEmpty) {
      return 'Sem círculos';
    }

    // Sort circles by position to determine rows and columns
    final sortedCircles = List.from(box.circles)
      ..sort((a, b) {
        // Sort by Y position first (rows), then X position (columns)
        final yDiff = a.center.dy.compareTo(b.center.dy);
        if (yDiff != 0) return yDiff;
        return a.center.dx.compareTo(b.center.dx);
      });

    final rows = _calculateRows(sortedCircles);
    final columns = _calculateColumns(sortedCircles);

    if (rows == 0 || columns == 0) {
      return 'Sem círculos';
    }

    // Analyze each row to determine question types
    final questionTypes = <int, int>{}; // number of options -> count

    // Group circles by row (Y position)
    final circlesByRow = <double, List<dynamic>>{};
    const double tolerance = 0.002;

    for (final circle in sortedCircles) {
      final y = circle.center.dy;
      bool foundRow = false;

      for (final rowY in circlesByRow.keys) {
        if ((y - rowY).abs() < tolerance) {
          circlesByRow[rowY]!.add(circle);
          foundRow = true;
          break;
        }
      }

      if (!foundRow) {
        circlesByRow[y] = [circle];
      }
    }

    // Analyze each row to count options
    for (final rowCircles in circlesByRow.values) {
      // Sort circles in this row by X position
      rowCircles.sort((a, b) => a.center.dx.compareTo(b.center.dx));

      // Count unique X positions in this row (number of options)
      final uniqueXPositions = <double>[];
      for (final circle in rowCircles) {
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

      final optionsCount = uniqueXPositions.length;
      questionTypes[optionsCount] = (questionTypes[optionsCount] ?? 0) + 1;
    }

    // Build description of mixed question types
    if (questionTypes.length == 1) {
      // All questions have the same number of options
      final options = questionTypes.keys.first;
      switch (options) {
        case 2:
          return 'Tipo A (2 opções)';
        case 4:
          return 'Tipo C (4 opções)';
        case 5:
          return 'Enem/Type B (5 opções)';
        default:
          return 'Tipo ${options} (${options} opções)';
      }
    } else {
      // Mixed question types
      final descriptions = <String>[];
      for (final entry in questionTypes.entries) {
        final options = entry.key;
        final count = entry.value;
        String typeName;

        switch (options) {
          case 2:
            typeName = 'Tipo A';
            break;
          case 4:
            typeName = 'Tipo C';
            break;
          case 5:
            typeName = 'Enem/Type B';
            break;
          default:
            typeName = 'Tipo $options';
        }

        descriptions.add('$typeName: $count');
      }
      return 'Misto (${descriptions.join(', ')})';
    }
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
    const double tolerance = 0.002; // 0.5% tolerance for normalized coordinates

    for (final circle in sortedCircles) {
      final y = circle.center.dy;
      bool foundSimilar = false;

      for (final existingY in uniqueYPositions) {
        var diff = (y - existingY).abs();
        if (diff < tolerance) {
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
    const double tolerance = 0.005; // 0.5% tolerance for normalized coordinates

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

  /// Extracts and compares answers for export
  /// Returns a list of maps: one per student/card, with their answers and comparison to gabarito
  static List<Map<String, dynamic>> exportAlunosResults({
    required List<AnswerSheetCardModel> cards,
    required AnswerSheetTemplateModel template,
    required List<Map<String, dynamic>> gabarito,
  }) {
    // Find question and answer columns in gabarito
    if (gabarito.isEmpty) return [];
    String? questionColumn;
    String? answerColumn;
    final gabaritoKeys = gabarito.first.keys.toList();
    for (final key in gabaritoKeys) {
      if (key.contains('questao') ||
          key.contains('question') ||
          key.contains('numero')) {
        questionColumn = key;
      }
      if (key.contains('resposta') ||
          key.contains('answer') ||
          key.contains('gabarito')) {
        answerColumn = key;
      }
    }
    if (questionColumn == null || answerColumn == null) return [];

    // Build gabarito map: question number -> correct answer (uppercase)
    final Map<int, String> gabaritoMap = {
      for (final row in gabarito)
        if (int.tryParse(row[questionColumn].toString()) != null)
          int.parse(row[questionColumn].toString()):
              row[answerColumn].toString().toUpperCase()
    };

    // Get question boxes from template
    final questionBoxes = template.boxes
        .where((box) =>
            box.box.label == BoxDetailsType.colunaDeQuestoes ||
            box.box.label == BoxDetailsType.typeB)
        .toList();

    // For each card, extract answers and compare
    List<Map<String, dynamic>> results = [];
    for (final card in cards) {
      Map<int, String> studentAnswers = {};

      // For each question box
      for (final box in questionBoxes) {
        final startingQuestion = extractStartingQuestionNumber(box.name);
        final questionCount = calculateQuestionCount(box);
        final circles = card.circlesPerBox[box.name] ?? [];

        if (circles.isEmpty) continue;

        // Create headers for this box's questions
        List<Map<String, String>> headersToGetSorted = [];
        for (int i = 0; i < questionCount; i++) {
          final questionNumber = startingQuestion + i;
          headersToGetSorted.add({'Q$questionNumber': 'Q$questionNumber'});
        }

        // Use Utils.getAnswerFromCardBox to extract answers properly
        final boxAnswers = Utils.getAnswerFromCardBox(
          box: box,
          circlesPerBox: circles,
          headersToGetSorted: headersToGetSorted,
          tolerance: 0.002,
        );

        // Map the answers to question numbers
        for (int i = 0; i < questionCount; i++) {
          final questionNumber = startingQuestion + i;
          final answer = boxAnswers['Q$questionNumber'] ?? '';
          studentAnswers[questionNumber] = answer;
        }
      }

      // Build result row for this card
      List<Map<String, dynamic>> answers = [];
      for (final entry in studentAnswers.entries) {
        final q = entry.key;
        final studentAnswer = entry.value;
        final correctAnswer = gabaritoMap[q] ?? '';
        answers.add({
          'question': q,
          'student_answer': studentAnswer,
          'correct_answer': correctAnswer,
          'is_correct':
              studentAnswer == correctAnswer && studentAnswer.isNotEmpty,
        });
      }
      results.add({
        'student': card.documentOriginalName,
        'answers': answers,
      });
    }
    return results;
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
