import 'package:corigge/config/size_config.dart';
import 'package:flutter/material.dart';
import '../../data/generated_template_model.dart';

class TemplateCanvasWidget extends StatefulWidget {
  final GeneratedTemplateModel template;
  final Function(GeneratedTemplateModel)? onTemplateChanged;
  final String? studentName;
  final String? studentMatricula;
  final bool isForPdf;

  const TemplateCanvasWidget({
    super.key,
    required this.template,
    this.onTemplateChanged,
    this.studentName,
    this.studentMatricula,
    this.isForPdf = false,
  });

  @override
  State<TemplateCanvasWidget> createState() => _TemplateCanvasWidgetState();
}

class _TemplateCanvasWidgetState extends State<TemplateCanvasWidget> {
  @override
  Widget build(BuildContext context) {
    // A4 landscape dimensions in points (1 point = 1/72 inch)
    // A4 Landscape: 297mm x 210mm = 841.89 x 595.28 points
    const double a4Width = 210 * 3;
    const double a4Height = 297 * 3;

    // Scale factor to fit in the canvas area
    late final double scale;
    late final double scaledWidth;
    late final double scaledHeight;

    if (widget.isForPdf) {
      // For PDF, use full A4 dimensions without scaling
      scale = 1.0;
      scaledWidth = a4Width;
      scaledHeight = a4Height;
    } else {
      // For preview, scale to fit the available space
      final canvasWidth =
          MediaQuery.of(context).size.width - 50; // Account for settings panel
      final canvasHeight = MediaQuery.of(context).size.height -
          50; // Account for app bar and margins
      final scaleX = canvasWidth / a4Width;
      final scaleY = canvasHeight / a4Height;
      scale = scaleX < scaleY ? scaleX : scaleY;

      scaledWidth = a4Width * scale;
      scaledHeight = a4Height * scale;
    }

    return Container(
      margin: widget.isForPdf ? EdgeInsets.zero : const EdgeInsets.all(4),
      child: Center(
        child: Container(
          width: scaledWidth,
          height: scaledHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 3),
            color: Colors.white,
            boxShadow: widget.isForPdf
                ? []
                : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // A4 page background
              Container(
                width: scaledWidth,
                height: scaledHeight,
                color: Colors.white,
              ),
              // Corner squares
              _CornerSquares(
                width: scaledWidth,
                height: scaledHeight,
                scale: scale,
              ),
              // Main content using Column and Row layout
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(35 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First row: Name field and Matricula
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Student name field (if automatic)
                          if (widget.template.nomeAlunoAutomatico)
                            Expanded(
                                child: _StudentNameField(
                              scale: scale,
                              studentName: widget.studentName,
                            ))
                          else
                            ...[],
                          SizedBox(width: 10 * scale),
                          // Matricula field
                          _MatriculaField(
                            width: scaledWidth,
                            height: scaledHeight,
                            scale: scale,
                            studentMatricula: widget.studentMatricula,
                          ),
                        ],
                      ),
                      SizedBox(height: 30 * scale),
                      // Second row: Questions
                      Expanded(
                        child: _QuestionsSection(
                          questions: widget.template.questions,
                          scale: scale,
                          onTemplateChanged: widget.onTemplateChanged,
                          template: widget.template,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerSquares extends StatelessWidget {
  final double width;
  final double height;
  final double scale;

  const _CornerSquares({
    required this.width,
    required this.height,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    const double squareSize = 20;
    final scaledSquareSize = squareSize * scale;

    return Stack(
      children: [
        // Top-left corner
        Positioned(
          left: 10 * scale,
          top: 10 * scale,
          child: Container(
            width: scaledSquareSize,
            height: scaledSquareSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              color: Colors.black,
            ),
          ),
        ),
        // Top-right corner
        Positioned(
          right: 10 * scale,
          top: 10 * scale,
          child: Container(
            width: scaledSquareSize,
            height: scaledSquareSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              color: Colors.black,
            ),
          ),
        ),
        // Bottom-left corner
        Positioned(
          left: 10 * scale,
          bottom: 10 * scale,
          child: Container(
            width: scaledSquareSize,
            height: scaledSquareSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              color: Colors.black,
            ),
          ),
        ),
        // Bottom-right corner
        Positioned(
          right: 10 * scale,
          bottom: 10 * scale,
          child: Container(
            width: scaledSquareSize,
            height: scaledSquareSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _MatriculaField extends StatelessWidget {
  final double width;
  final double height;
  final double scale;
  final String? studentMatricula;

  const _MatriculaField({
    required this.width,
    required this.height,
    required this.scale,
    this.studentMatricula,
  });

  @override
  Widget build(BuildContext context) {
    const double spacing = 2;
    const double circleSize =
        10; // Standardized circle size to match other circles
    const double padding = 2; // Padding inside the grid container

    // Calculate the size needed for the 7x7 grid
    final scaledCircleSize = circleSize * scale;
    final scaledSpacing = spacing * scale;
    final scaledPadding = padding * scale;

    final gridWidth =
        (10 * scaledCircleSize) + (10 * scaledSpacing) + (2 * scaledPadding);
    final gridHeight =
        (10 * scaledCircleSize) + (10 * scaledSpacing) + (2 * scaledPadding);

    // Title height
    final titleHeight =
        (8 * scale) + (2 * scaledPadding) + 10; // font size + padding

    return Container(
      width: gridWidth,
      height: titleHeight +
          gridHeight +
          (studentMatricula != null ? 20 * scale : 0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Show student matricula number if provided
          if (studentMatricula != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(scaledPadding),
              decoration: BoxDecoration(
                border: const Border(
                  bottom: BorderSide(color: Colors.black, width: 1),
                ),
                color: Colors.grey.shade100,
              ),
              child: Text(
                'MATRÍCULA: $studentMatricula',
                style: TextStyle(
                  fontSize: 7 * scale,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          // Title
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(scaledPadding),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Text(
              'MATRÍCULA',
              style: TextStyle(
                fontSize: 8 * scale,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Grid of circles
          SizedBox(
            width: gridWidth,
            height: gridHeight,
            child: Padding(
              padding: EdgeInsets.all(scaledPadding),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: scaledSpacing,
                  mainAxisSpacing: scaledSpacing,
                ),
                itemCount: 100, // 10x10 grid
                itemBuilder: (context, index) {
                  final row = index ~/ 10;
                  final col = index % 10;
                  final number =
                      row; // 0s on top row, 1s on second row, ..., 9s on bottom row

                  return GenerateNumberedCircle(
                    text: number.toString(),
                    scale: scale,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentNameField extends StatelessWidget {
  final double scale;
  final String? studentName;

  const _StudentNameField({
    required this.scale,
    this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30 * scale,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        color: Colors.white,
      ),
      child: Center(
        child: Text(
          studentName != null ? 'NOME: $studentName' : 'NOME DO ALUNO',
          style: TextStyle(
            fontSize: 8 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _QuestionsSection extends StatelessWidget {
  final List<GeneratedTemplateQuestion> questions;
  final double scale;
  final Function(GeneratedTemplateModel)? onTemplateChanged;
  final GeneratedTemplateModel template;

  const _QuestionsSection({
    required this.questions,
    required this.scale,
    this.onTemplateChanged,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    // Sort questions by number
    final sortedQuestions = List<GeneratedTemplateQuestion>.from(questions)
      ..sort((a, b) => a.numero.compareTo(b.numero));

    if (questions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20 * scale),
        child: Center(
          child: Text(
            'Nenhuma questão adicionada',
            style: TextStyle(
              fontSize: 12 * scale,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    List<GeneratedTemplateQuestion> typeBQuestions =
        sortedQuestions.where((q) => q.type == TypeQuestion.B).toList();

    List<List<GeneratedTemplateQuestion>> questionsSeparatedIntoColumns = [];

    int index = 0;
    int currentColumn = 0;
    for (var question in sortedQuestions) {
      if (index % 30 == 0) {
        questionsSeparatedIntoColumns.add([]);
        currentColumn = questionsSeparatedIntoColumns.length - 1;
      }
      questionsSeparatedIntoColumns[currentColumn].add(question);
      index++;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Type A and C questions in columns. Type B should show a "Tipo B" text
        Expanded(
          flex: 4,
          child: Row(
            spacing: 5 * scale,
            children: [
              for (var columnQuestions in questionsSeparatedIntoColumns)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var question in columnQuestions)
                      if (question.type == TypeQuestion.A)
                        _buildSmallQuestion(question, 'A')
                      else if (question.type == TypeQuestion.C)
                        _buildSmallQuestion(question, 'C')
                      else if (question.type == TypeQuestion.B)
                        _buildSmallQuestion(question, 'B')
                  ],
                ),
            ],
          ),
        ),

        if (typeBQuestions.isNotEmpty) ...[
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 4 * scale,
                  runSpacing: 4 * scale,
                  children: typeBQuestions
                      .map((question) => SizedBox(
                            width: 55 *
                                scale, // Fixed width for each Type B question
                            child: _buildTypeBQuestion(question),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmallQuestion(GeneratedTemplateQuestion question, String type) {
    return Container(
      width: 60 * scale,
      height: 15 * scale,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Question number
          Container(
            width: 15 * scale,
            height: 25 * scale,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.black, width: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                '${question.numero}',
                style: TextStyle(
                  fontSize: 5 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 2 * scale),
          // Answer options
          Expanded(
            child: Builder(builder: (context) {
              List<Widget> children = [];
              if (type == 'A') {
                children.add(GenerateNumberedCircle(text: 'C', scale: scale));
                children.add(GenerateNumberedCircle(text: 'E', scale: scale));
              } else if (type == 'C') {
                children.add(GenerateNumberedCircle(text: 'A', scale: scale));
                children.add(GenerateNumberedCircle(text: 'B', scale: scale));
                children.add(GenerateNumberedCircle(text: 'C', scale: scale));
                children.add(GenerateNumberedCircle(text: 'D', scale: scale));
              } else if (type == 'B') {
                children.add(Text("TIPO B",
                    style: TextStyle(
                      fontSize: 6 * scale,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    )));
              }

              return Row(
                spacing: 0.2,
                mainAxisAlignment: MainAxisAlignment.start,
                children: children,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBQuestion(GeneratedTemplateQuestion question) {
    return Container(
      margin: EdgeInsets.only(bottom: 15 * scale),
      padding: EdgeInsets.all(3 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number header
          Center(
            child: Text(
              'Questão ${question.numero}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 0.5),
            ),
            child: Center(
              child: Text(
                "C | D | U",
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 7 * scale,
                ),
              ),
            ),
          ),
          SizedBox(height: 10 * scale),
          // Grid of circles
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 1 * scale,
              mainAxisSpacing: 1 * scale,
            ),
            itemCount: 30, // 3 columns of 10 circles
            itemBuilder: (context, index) {
              final number = index % 10;
              return GenerateNumberedCircle(
                text: number.toString(),
                scale: scale,
              );
            },
          ),
        ],
      ),
    );
  }
}

class GenerateNumberedCircle extends StatelessWidget {
  final String text;
  final double scale;
  final double circleSize;
  final double borderWidth;
  final double fontSize;

  const GenerateNumberedCircle({
    super.key,
    required this.text,
    required this.scale,
    this.circleSize = 10,
    this.borderWidth = 0.5,
    this.fontSize = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: circleSize * scale,
      height: circleSize * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: borderWidth),
        color: Colors.white,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
