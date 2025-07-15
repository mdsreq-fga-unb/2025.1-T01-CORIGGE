import 'package:flutter/material.dart';
import 'dart:io';

import '../config/size_config.dart';
import '../config/theme.dart';

class RelatorioPreviewWidget extends StatelessWidget {
  final Map<String, dynamic>? previewAluno;
  final Map<String, dynamic>? previewResults;
  final File? logoFile;

  const RelatorioPreviewWidget({
    super.key,
    this.previewAluno,
    this.previewResults,
    this.logoFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height -
          getProportionateScreenHeight(200),
      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSecondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: kPrimary,
                size: getProportionateScreenWidth(24),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Text(
                'Pré-visualização do Relatório',
                style: TextStyle(
                  fontSize: getProportionateFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: kOnSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          if (previewAluno == null) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mouse,
                      size: getProportionateScreenWidth(48),
                      color: kOnSurface.withOpacity(0.3),
                    ),
                    SizedBox(height: getProportionateScreenHeight(16)),
                    Text(
                      'Passe o mouse sobre o nome\nde um aluno para ver\no relatório individual',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: getProportionateFontSize(16),
                        color: kOnSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // A4 Preview content
            Expanded(
              child: Center(
                child: _buildA4Preview(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildA4Preview() {
    if (previewAluno == null || previewResults == null)
      return SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // A4 aspect ratio (210mm x 297mm = 1:1.414)
        final double a4AspectRatio = 297 / 210;

        // Calculate dimensions to fit the available space
        double width = constraints.maxWidth;
        double height = width * a4AspectRatio;

        // If height exceeds available space, scale down based on height
        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height / a4AspectRatio;
        }

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(
                width * 0.067), // Proportional margins (40/600 = 0.067)
            child: _buildReportContent(width),
          ),
        );
      },
    );
  }

  Widget _buildReportContent(double containerWidth) {
    final student = previewResults!['student'];
    final answers = previewResults!['answers'] as List;
    final correctAnswers =
        answers.where((ans) => ans['is_correct'] == true).length;
    final totalQuestions = answers.length;
    final percentage = totalQuestions > 0
        ? (correctAnswers / totalQuestions * 100).toStringAsFixed(1)
        : '0.0';

    // Scale factor based on container width
    final double scaleFactor = containerWidth / 600.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with school logo
        Row(
          children: [
            if (logoFile != null) ...[
              Container(
                width: 80 * scaleFactor,
                height: 80 * scaleFactor,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(logoFile!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: 20 * scaleFactor),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RELATÓRIO INDIVIDUAL DE DESEMPENHO',
                    style: TextStyle(
                      fontSize: 18 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8 * scaleFactor),
                  Text(
                    'Data: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                    style: TextStyle(
                      fontSize: 12 * scaleFactor,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 30 * scaleFactor),

        // Student Information
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16 * scaleFactor),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INFORMAÇÕES DO ALUNO',
                style: TextStyle(
                  fontSize: 14 * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8 * scaleFactor),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nome: ${previewAluno!['nome']}',
                      style: TextStyle(
                        fontSize: 12 * scaleFactor,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(width: 20 * scaleFactor),
                  Text(
                    'Matrícula: ${previewAluno!['matricula']}',
                    style: TextStyle(
                      fontSize: 12 * scaleFactor,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 24 * scaleFactor),

        // Performance Summary
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16 * scaleFactor),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RESUMO DO DESEMPENHO',
                style: TextStyle(
                  fontSize: 14 * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12 * scaleFactor),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildA4StatItem('Acertos', correctAnswers.toString(),
                      Colors.green[600]!, scaleFactor),
                  _buildA4StatItem(
                      'Erros',
                      (totalQuestions - correctAnswers).toString(),
                      Colors.red[600]!,
                      scaleFactor),
                  _buildA4StatItem('Total', totalQuestions.toString(),
                      Colors.black87, scaleFactor),
                  _buildA4StatItem('Aproveitamento', '$percentage%',
                      Colors.blue[600]!, scaleFactor),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 24 * scaleFactor),

        // Answers Details
        Text(
          'RESPOSTAS DETALHADAS',
          style: TextStyle(
            fontSize: 14 * scaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12 * scaleFactor),

        // Answers Grid
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.all(12 * scaleFactor),
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10, // More columns for A4 layout
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 6 * scaleFactor,
                  mainAxisSpacing: 6 * scaleFactor,
                ),
                itemCount: answers.length,
                itemBuilder: (context, index) {
                  final answer = answers[index];
                  final isCorrect = answer['is_correct'] == true;
                  return Container(
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green[50] : Colors.red[50],
                      border: Border.all(
                        color:
                            isCorrect ? Colors.green[400]! : Colors.red[400]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${answer['question']}',
                          style: TextStyle(
                            fontSize: 8 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${answer['student_answer']}',
                          style: TextStyle(
                            fontSize: 10 * scaleFactor,
                            color:
                                isCorrect ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        SizedBox(height: 16 * scaleFactor),

        // Footer
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8 * scaleFactor),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Text(
            'Relatório gerado automaticamente pelo sistema CORIGGE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10 * scaleFactor,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildA4StatItem(
      String label, String value, Color color, double scaleFactor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16 * scaleFactor,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4 * scaleFactor),
        Text(
          label,
          style: TextStyle(
            fontSize: 10 * scaleFactor,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
