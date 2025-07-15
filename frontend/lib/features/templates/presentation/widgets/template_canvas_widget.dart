import 'package:flutter/material.dart';
import '../../data/generated_template_model.dart';

class TemplateCanvasWidget extends StatefulWidget {
  final GeneratedTemplateModel template;
  final Function(GeneratedTemplateModel)? onTemplateChanged;

  const TemplateCanvasWidget({
    super.key,
    required this.template,
    this.onTemplateChanged,
  });

  @override
  State<TemplateCanvasWidget> createState() => _TemplateCanvasWidgetState();
}

class _TemplateCanvasWidgetState extends State<TemplateCanvasWidget> {
  @override
  Widget build(BuildContext context) {
    // A4 landscape dimensions in points (1 point = 1/72 inch)
    // A4 Landscape: 297mm x 210mm = 841.89 x 595.28 points
    const double a4Width = 595.28;
    const double a4Height = 841.89;

    // Scale factor to fit in the canvas area
    final canvasWidth =
        MediaQuery.of(context).size.width - 50; // Account for settings panel
    final canvasHeight = MediaQuery.of(context).size.height -
        50; // Account for app bar and margins
    final scaleX = canvasWidth / a4Width;
    final scaleY = canvasHeight / a4Height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final scaledWidth = a4Width * scale;
    final scaledHeight = a4Height * scale;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: scaledWidth,
          height: scaledHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 3),
            color: Colors.white,
            boxShadow: [
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
                  padding: EdgeInsets.all(50 * scale),
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
                            _StudentNameField(scale: scale),
                          // Matricula field
                          _MatriculaField(
                            width: scaledWidth,
                            height: scaledHeight,
                            scale: scale,
                          ),
                        ],
                      ),
                      SizedBox(height: 30 * scale),
                      // Second row: Questions
                      Expanded(
                        child: _QuestionsSection(
                          questions: widget.template.questions,
                          scale: scale,
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

  const _MatriculaField({
    required this.width,
    required this.height,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    const double spacing = 4;
    const double circleSize = 12; // Base circle size
    const double padding = 4; // Padding inside the grid container

    // Calculate the size needed for the 7x7 grid
    final scaledCircleSize = circleSize * scale;
    final scaledSpacing = spacing * scale;
    final scaledPadding = padding * scale;

    // Grid dimensions: 7 circles + 6 spaces between them + 2 * padding
    final gridWidth =
        (7 * scaledCircleSize) + (6 * scaledSpacing) + (2 * scaledPadding);
    final gridHeight =
        (7 * scaledCircleSize) + (6 * scaledSpacing) + (2 * scaledPadding);

    // Title height
    final titleHeight =
        (8 * scale) + (2 * scaledPadding) + 10; // font size + padding

    return Container(
      width: gridWidth,
      height: titleHeight + gridHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        color: Colors.white,
      ),
      child: Column(
        children: [
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
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: scaledSpacing,
                  mainAxisSpacing: scaledSpacing,
                ),
                itemCount: 49, // 7x7 grid
                itemBuilder: (context, index) {
                  final row = index ~/ 7;
                  final col = index % 7;
                  final number = (row * 7 + col) % 10;

                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1),
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        number.toString(),
                        style: TextStyle(
                          fontSize: 6 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

  const _StudentNameField({
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200 * scale,
      height: 30 * scale,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        color: Colors.white,
      ),
      child: Center(
        child: Text(
          'NOME DO ALUNO',
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

  const _QuestionsSection({
    required this.questions,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;

          return Container(
            margin: EdgeInsets.only(bottom: 10 * scale),
            width: 300 * scale,
            height: 35 * scale,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                'Questão ${question.numero} - Tipo ${question.type.name}',
                style: TextStyle(
                  fontSize: 8 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
