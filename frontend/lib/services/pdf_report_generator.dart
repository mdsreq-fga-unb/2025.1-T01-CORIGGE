import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportGenerator {
  static Future<Uint8List> generateStudentReport({
    required Map<String, dynamic> student,
    required Map<String, dynamic> results,
    File? logoFile,
  }) async {
    final pdf = pw.Document();

    // Load logo if provided
    pw.ImageProvider? logoImage;
    if (logoFile != null) {
      try {
        final logoBytes = await logoFile.readAsBytes();
        logoImage = pw.MemoryImage(logoBytes);
      } catch (e) {
        print('Error loading logo: $e');
      }
    }

    final answers = results['answers'] as List;
    final correctAnswers =
        answers.where((ans) => ans['is_correct'] == true).length;
    final totalQuestions = answers.length;
    final percentage = totalQuestions > 0
        ? (correctAnswers / totalQuestions * 100).toStringAsFixed(1)
        : '0.0';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                children: [
                  if (logoImage != null) ...[
                    pw.Container(
                      width: 80,
                      height: 80,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(width: 20),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RELATÓRIO INDIVIDUAL DE DESEMPENHO',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Data: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Student Information
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORMAÇÕES DO ALUNO',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Nome: ${student['nome']}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Text(
                          'Matrícula: ${student['matricula']}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Performance Summary
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RESUMO DO DESEMPENHO',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildPdfStatItem('Acertos', correctAnswers.toString(),
                            PdfColors.green600),
                        _buildPdfStatItem(
                            'Erros',
                            (totalQuestions - correctAnswers).toString(),
                            PdfColors.red600),
                        _buildPdfStatItem('Total', totalQuestions.toString(),
                            PdfColors.black),
                        _buildPdfStatItem('Aproveitamento', '$percentage%',
                            PdfColors.blue600),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Answers Details
              pw.Text(
                'RESPOSTAS DETALHADAS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              // Answers Grid
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: answers.map((answer) {
                        final isCorrect = answer['is_correct'] == true;
                        return pw.Container(
                          width: 45,
                          height: 35,
                          decoration: pw.BoxDecoration(
                            color:
                                isCorrect ? PdfColors.green50 : PdfColors.red50,
                            border: pw.Border.all(
                              color: isCorrect
                                  ? PdfColors.green400
                                  : PdfColors.red400,
                            ),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                '${answer['question']}',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                '${answer['student_answer']}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: isCorrect
                                      ? PdfColors.green700
                                      : PdfColors.red700,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Relatório gerado automaticamente pelo sistema CORIGGE',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfStatItem(
      String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }
}
