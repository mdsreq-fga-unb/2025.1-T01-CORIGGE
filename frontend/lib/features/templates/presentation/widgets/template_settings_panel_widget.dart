import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_to_pdf/flutter_to_pdf.dart';
import '../../data/generated_template_model.dart';
import '../widgets/template_canvas_widget.dart';

class TemplateSettingsPanelWidget extends StatefulWidget {
  final GeneratedTemplateModel template;
  final Function(GeneratedTemplateModel) onTemplateChanged;
  final VoidCallback onGenerateTemplate;

  const TemplateSettingsPanelWidget({
    super.key,
    required this.template,
    required this.onTemplateChanged,
    required this.onGenerateTemplate,
  });

  @override
  State<TemplateSettingsPanelWidget> createState() =>
      _TemplateSettingsPanelWidgetState();
}

class _TemplateSettingsPanelWidgetState
    extends State<TemplateSettingsPanelWidget> {
  late TextEditingController _nameController;
  late bool nomeAlunoAutomatico;
  late List<TypeQuestion> tiposQuestoes;

  // CSV handling variables
  File? csvFile;
  List<Map<String, dynamic>> csvData = [];
  String? csvError;
  bool isProcessing = false;

  // PDF generation key
  final GlobalKey _templateKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    nomeAlunoAutomatico = widget.template.nomeAlunoAutomatico;
    tiposQuestoes = widget.template.questions.isNotEmpty
        ? widget.template.questions.map((q) => q.type).toList()
        : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTemplateNameField(),
          const SizedBox(height: 24),
          _buildAutomaticStudentNameCheckbox(),
          const SizedBox(height: 24),
          _buildQuestionTypesSection(),
          const SizedBox(height: 24),
          _buildGenerateTemplateButton(),
        ],
      ),
    );
  }

  Widget _buildTemplateNameField() {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Nome do Template',
        border: OutlineInputBorder(),
      ),
      controller: _nameController,
      onChanged: (value) {
        final updatedTemplate = widget.template.copyWith(name: value);
        widget.onTemplateChanged(updatedTemplate);
      },
    );
  }

  Widget _buildAutomaticStudentNameCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: nomeAlunoAutomatico,
          onChanged: (value) {
            setState(() {
              nomeAlunoAutomatico = value ?? true;
            });
            final updatedTemplate = widget.template.copyWith(
              nomeAlunoAutomatico: nomeAlunoAutomatico,
            );
            widget.onTemplateChanged(updatedTemplate);
          },
        ),
        const Expanded(
          child: Text(
            'Nome do aluno automático?',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Questões',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Máximo: 150 questões A/C e 6 questões B',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _buildQuestionsList(),
      ],
    );
  }

  Widget _buildQuestionsList() {
    if (tiposQuestoes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma questão adicionada',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: tiposQuestoes.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            title: Text('Questão ${index + 1}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<TypeQuestion>(
                  value: tiposQuestoes[index],
                  items: const [
                    DropdownMenuItem(
                        value: TypeQuestion.A, child: Text('Tipo A')),
                    DropdownMenuItem(
                        value: TypeQuestion.B, child: Text('Tipo B')),
                    DropdownMenuItem(
                        value: TypeQuestion.C, child: Text('Tipo C')),
                  ],
                  onChanged: (value) => _updateQuestionType(index, value),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeQuestion(index),
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenerateTemplateButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CSV File Selection
        if (csvFile == null) ...[
          ElevatedButton.icon(
            onPressed: isProcessing ? null : _selectCsvFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Selecionar CSV'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Arquivo CSV deve conter as colunas "nome" e "matricula"',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          // CSV file info
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color:
                  csvError != null ? Colors.red.shade50 : Colors.green.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      csvError != null ? Icons.error : Icons.check_circle,
                      size: 16,
                      color: csvError != null ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        csvFile!.path.split('/').last,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: _clearCsvFile,
                      icon: const Icon(Icons.close, size: 16),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                if (csvError != null)
                  Text(
                    csvError!,
                    style: const TextStyle(fontSize: 10, color: Colors.red),
                  ),
                if (csvData.isNotEmpty)
                  Text(
                    '${csvData.length} alunos encontrados',
                    style: const TextStyle(fontSize: 10, color: Colors.green),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Generate PDFs button
        ElevatedButton.icon(
          onPressed: (csvData.isNotEmpty && csvError == null && !isProcessing)
              ? _generateTemplate
              : null,
          icon: isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.picture_as_pdf),
          label: Text(isProcessing ? 'Gerando PDFs...' : 'Gerar PDFs'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _addQuestion() {
    if (tiposQuestoes.length < 150) {
      setState(() {
        tiposQuestoes.add(TypeQuestion.A);
        _updateTemplate();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo de 150 questões permitidas')),
      );
    }
  }

  void _removeQuestion(int index) {
    setState(() {
      tiposQuestoes.removeAt(index);
      _updateTemplate();
    });
  }

  void _updateQuestionType(int index, TypeQuestion? value) {
    if (value != null) {
      // Check if changing to B would exceed the limit
      if (value == TypeQuestion.B) {
        final currentBCount =
            tiposQuestoes.where((t) => t == TypeQuestion.B).length;
        if (tiposQuestoes[index] != TypeQuestion.B && currentBCount >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Máximo de 6 questões tipo B permitidas')),
          );
          return;
        }
      }

      setState(() {
        tiposQuestoes[index] = value;
        _updateTemplate();
      });
    }
  }

  void _updateTemplate() {
    // Generate questions based on current types
    final questions = <GeneratedTemplateQuestion>[];
    for (int i = 0; i < tiposQuestoes.length; i++) {
      questions.add(GeneratedTemplateQuestion(
        type: tiposQuestoes[i],
        numero: i + 1,
      ));
    }

    final updatedTemplate = widget.template.copyWith(
      questions: questions,
    );

    widget.onTemplateChanged(updatedTemplate);
  }

  Future<void> _selectCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          csvFile = file;
          csvError = null;
          csvData.clear();
        });
        await _parseCsvFile(file);
      }
    } catch (e) {
      setState(() {
        csvError = 'Erro ao selecionar arquivo: $e';
      });
    }
  }

  void _clearCsvFile() {
    setState(() {
      csvFile = null;
      csvData.clear();
      csvError = null;
    });
  }

  Future<void> _parseCsvFile(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');

      if (lines.isEmpty) {
        setState(() {
          csvError = 'Arquivo CSV vazio';
        });
        return;
      }

      // Parse header
      final header =
          lines[0].split(',').map((e) => e.trim().replaceAll('"', '')).toList();

      // Check if required columns exist
      if (!header.contains('matricula') || !header.contains('nome')) {
        setState(() {
          csvError = 'Arquivo deve conter as colunas "matricula" e "nome"';
        });
        return;
      }

      // Parse data
      final data = <Map<String, dynamic>>[];
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;

        final values = lines[i]
            .split(',')
            .map((e) => e.trim().replaceAll('"', ''))
            .toList();
        if (values.length >= header.length) {
          final row = <String, dynamic>{};
          for (int j = 0; j < header.length; j++) {
            row[header[j]] = values[j];
          }
          data.add(row);
        }
      }

      setState(() {
        csvData = data;
        csvError = null;
      });
    } catch (e) {
      setState(() {
        csvError = 'Erro ao processar arquivo CSV: $e';
      });
    }
  }

  Future<void> _generateTemplate() async {
    if (csvData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um arquivo CSV primeiro')),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // Get the directory to save PDFs
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        setState(() {
          isProcessing = false;
        });
        return;
      }

      // Generate PDF for each student
      int generatedCount = 0;
      for (final student in csvData) {
        final nome = student['nome']?.toString() ?? '';
        final matricula = student['matricula']?.toString() ?? '';

        if (nome.isNotEmpty && matricula.isNotEmpty) {
          await _generatePdfForStudent(
            nome: nome,
            matricula: matricula,
            outputDirectory: selectedDirectory,
          );
          generatedCount++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$generatedCount PDFs gerados com sucesso em $selectedDirectory'),
          backgroundColor: Colors.green,
        ),
      );

      // Call the original callback
      widget.onGenerateTemplate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar PDFs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _generatePdfForStudent({
    required String nome,
    required String matricula,
    required String outputDirectory,
  }) async {
    try {
      // Create a modified template with student data
      final templateWithStudent = widget.template.copyWith(
        name: '${widget.template.name} - $nome',
      );

      // Create export delegate
      final exportDelegate = ExportDelegate();
      final frameId =
          'template_${matricula}_${DateTime.now().millisecondsSinceEpoch}';

      // Create a temporary widget tree for export using the actual template canvas
      final exportWidget = MaterialApp(
        home: Scaffold(
          body: ExportFrame(
            frameId: frameId,
            exportDelegate: exportDelegate,
            child: RepaintBoundary(
              child: SizedBox(
                width: 210 * 3, // A4 landscape width
                height: 297 * 3, // A4 landscape height
                child: TemplateCanvasWidget(
                  template: templateWithStudent,
                  studentName: nome,
                  studentMatricula: matricula,
                  isForPdf: true,
                ),
              ),
            ),
          ),
        ),
      );

      // We need to render the widget first, so we'll use a temporary overlay
      late OverlayEntry overlayEntry;

      // Create overlay to render the widget
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -10000, // Move offscreen
          top: -10000,
          child: SizedBox(
            width: 210 * 3,
            height: 297 * 3,
            child: exportWidget,
          ),
        ),
      );

      // Insert overlay
      if (mounted) {
        Overlay.of(context).insert(overlayEntry);

        // Wait a bit for the widget to be built
        await Future.delayed(const Duration(milliseconds: 500));

        // Export to PDF
        final pdf = await exportDelegate.exportToPdfDocument(frameId,
            overrideOptions: ExportOptions(
                pageFormatOptions: PageFormatOptions.custom(
                    width: 210 * 3, height: 297 * 3, marginAll: 0)));
        final pdfBytes = await pdf.save();

        // Remove overlay
        overlayEntry.remove();

        // Save the PDF file
        final fileName =
            '${templateWithStudent.name.replaceAll(' ', '_')}_${matricula}.pdf';
        final file = File('$outputDirectory/$fileName');
        await file.writeAsBytes(pdfBytes);
      }
    } catch (e) {
      throw Exception('Erro ao gerar PDF para $nome: $e');
    }
  }
}
