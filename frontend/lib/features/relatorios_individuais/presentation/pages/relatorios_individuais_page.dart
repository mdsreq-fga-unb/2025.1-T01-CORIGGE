import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:convert';

import '../../../../config/size_config.dart';
import '../../../../config/theme.dart';
import '../../../../widgets/app_bar_custom.dart';
import '../../../../widgets/default_button_widget.dart';
import '../../../../widgets/relatorio_preview_widget.dart';
import '../../../../widgets/alunos_status_widget.dart';
import '../../../../widgets/csv_upload_widget.dart';
import '../../../../widgets/logo_upload_widget.dart';
import '../../../../utils/utils.dart';
import '../../../../cache/shared_preferences_helper.dart';
import '../../../../features/templates/data/answer_sheet_template_model.dart';
import '../../../../features/templates/data/answer_sheet_card_model.dart';
import '../../../../features/templates/data/answer_sheet_identifiable_box.dart';
import '../../../../features/home/services/home_service.dart';
import '../../../../utils/image_bounding_box/data/box_details.dart';
import '../../../../services/pdf_report_generator.dart';

class RelatoriosIndividuaisPage extends StatefulWidget {
  const RelatoriosIndividuaisPage({super.key});

  @override
  State<RelatoriosIndividuaisPage> createState() =>
      _RelatoriosIndividuaisPageState();
}

class _RelatoriosIndividuaisPageState extends State<RelatoriosIndividuaisPage> {
  File? csvFile;
  File? logoFile;
  List<Map<String, dynamic>> csvData = [];
  bool isLoading = false;
  String? csvError;
  String? logoError;

  // Data from home page
  AnswerSheetTemplateModel? selectedTemplate;
  List<AnswerSheetCardModel> analyzedCards = [];
  List<Map<String, dynamic>> gabaritoData = [];
  List<String> existingMatriculas = [];
  List<Map<String, dynamic>> matchingAlunos = [];
  List<Map<String, dynamic>> missingAlunos = [];

  // Preview state
  Map<String, dynamic>? previewAluno;
  Map<String, dynamic>? previewResults;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load selected template
      final selectedTemplateId =
          await SharedPreferencesHelper.getSelectedTemplate();
      if (selectedTemplateId != null) {
        final templatesResult = await SharedPreferencesHelper.loadTemplates();
        final templates = templatesResult.fold(
            (error) => <AnswerSheetTemplateModel>[], (templates) => templates);

        try {
          selectedTemplate = templates.firstWhere(
            (template) => template.id == selectedTemplateId.id,
          );
        } catch (e) {
          selectedTemplate = null;
        }
      }

      // Load analyzed cards
      final cardsResult = await SharedPreferencesHelper.loadCards();
      final cards = cardsResult.fold(
          (error) => <AnswerSheetCardModel>[], (cards) => cards);

      // Load gabarito data
      final gabaritoResult = await SharedPreferencesHelper.loadGabarito();
      final gabarito = gabaritoResult.fold(
          (error) => <Map<String, dynamic>>[], (gabarito) => gabarito);

      if (mounted) {
        setState(() {
          selectedTemplate = selectedTemplate;
          analyzedCards = cards;
          gabaritoData = gabarito;
        });

        // Extract existing matriculas from analyzed cards
        _extractExistingMatriculas();
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  void _extractExistingMatriculas() {
    if (selectedTemplate == null || analyzedCards.isEmpty) return;

    final matriculas = <String>{};

    // Get matricula box from template
    AnswerSheetIdentifiableBox? matriculaBox;
    try {
      matriculaBox = selectedTemplate!.boxes.firstWhere(
        (box) => box.box.label == BoxDetailsType.matricula,
      );
    } catch (e) {
      matriculaBox = null;
    }

    if (matriculaBox == null) return;

    for (final card in analyzedCards) {
      final circlesPerBox = card.circlesPerBox[matriculaBox.name];
      if (circlesPerBox != null && circlesPerBox.isNotEmpty) {
        final matriculaResult = Utils.getAnswerFromCardBox(
          box: matriculaBox,
          circlesPerBox: circlesPerBox,
          headersToGetSorted: [
            {'Matricula': 'matricula'}
          ],
          tolerance: 0.002,
        );

        final matricula = matriculaResult['Matricula'];
        if (matricula != null &&
            matricula.isNotEmpty &&
            matricula != '00000000') {
          matriculas.add(matricula);
        }
      }
    }

    setState(() {
      existingMatriculas = matriculas.toList()..sort();
    });

    // Check matching if CSV data is already loaded
    if (csvData.isNotEmpty) {
      _checkAlunosMatching();
    }
  }

  void _generatePreviewForAluno(Map<String, dynamic> aluno) {
    if (selectedTemplate == null || gabaritoData.isEmpty) return;

    final matricula = aluno['matricula']?.toString() ?? '';

    // Find the card for this matricula
    AnswerSheetCardModel? card;
    try {
      card = analyzedCards.firstWhere(
        (card) {
          final matriculaBox = selectedTemplate!.boxes.firstWhere(
            (box) => box.box.label == BoxDetailsType.matricula,
          );

          final circlesPerBox = card.circlesPerBox[matriculaBox.name];
          if (circlesPerBox == null || circlesPerBox.isEmpty) return false;

          final matriculaResult = Utils.getAnswerFromCardBox(
            box: matriculaBox,
            circlesPerBox: circlesPerBox,
            headersToGetSorted: [
              {'Matricula': 'matricula'}
            ],
            tolerance: 0.002,
          );

          return matriculaResult['Matricula'] == matricula;
        },
      );
    } catch (e) {
      card = null;
    }

    if (card == null) return;

    // Generate results for this specific student
    final results = HomeService.exportAlunosResults(
      cards: [card],
      template: selectedTemplate!,
      gabarito: gabaritoData,
    );

    if (results.isNotEmpty) {
      setState(() {
        previewAluno = aluno;
        previewResults = results.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom.appBarWithLogo(
        context: context,
        onWantsToGoBack: () => context.go('/home'),
      ),
      body: Padding(
        padding: EdgeInsets.all(getProportionateScreenWidth(32)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Preview
            Expanded(
              flex: 1,
              child: RelatorioPreviewWidget(
                previewAluno: previewAluno,
                previewResults: previewResults,
                logoFile: logoFile,
              ),
            ),
            SizedBox(width: getProportionateScreenWidth(32)),

            // Right side - Settings
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Relatórios Individuais',
                      style: TextStyle(
                        fontSize: getProportionateFontSize(28),
                        fontWeight: FontWeight.bold,
                        color: kOnSurface,
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(8)),
                    Text(
                      'Envie um arquivo CSV com os nomes dos alunos e uma imagem do logo da escola para gerar relatórios individuais.',
                      style: TextStyle(
                        fontSize: getProportionateFontSize(16),
                        color: kOnSurface.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(32)),

                    // CSV File Upload Section
                    CsvUploadWidget(
                      csvFile: csvFile,
                      csvError: csvError,
                      csvData: csvData,
                      onPickFile: _pickCsvFile,
                      onClearFile: _clearCsvFile,
                    ),
                    SizedBox(height: getProportionateScreenHeight(24)),

                    // Existing Matriculas Section
                    if (existingMatriculas.isNotEmpty) ...[
                      AlunosStatusWidget(
                        matchingAlunos: matchingAlunos,
                        missingAlunos: missingAlunos,
                        csvData: csvData,
                        existingMatriculas: existingMatriculas,
                        onHoverAluno: _generatePreviewForAluno,
                      ),
                      SizedBox(height: getProportionateScreenHeight(24)),
                    ],

                    // Logo Upload Section
                    LogoUploadWidget(
                      logoFile: logoFile,
                      logoError: logoError,
                      onPickFile: _pickLogoFile,
                      onClearFile: _clearLogoFile,
                    ),
                    SizedBox(height: getProportionateScreenHeight(32)),

                    // Generate Reports Button
                    _buildGenerateButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    final canGenerate = csvFile != null &&
        logoFile != null &&
        csvData.isNotEmpty &&
        csvError == null &&
        logoError == null &&
        matchingAlunos.isNotEmpty;

    return Center(
      child: DefaultButtonWidget(
        onPressed: canGenerate ? _generateReports : null,
        color: canGenerate ? kPrimary : kPrimary.withOpacity(0.5),
        child: isLoading
            ? SizedBox(
                width: getProportionateScreenWidth(20),
                height: getProportionateScreenHeight(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kSurface),
                ),
              )
            : Text(
                'GERAR ${matchingAlunos.length} RELATÓRIOS EM PDF',
                style: TextStyle(
                  fontSize: getProportionateFontSize(18),
                  color: canGenerate ? kSurface : kSurface.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        setState(() {
          csvFile = file;
          csvError = null;
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
      matchingAlunos.clear();
      missingAlunos.clear();
      previewAluno = null;
      previewResults = null;
    });
  }

  Future<void> _pickLogoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        setState(() {
          logoFile = file;
          logoError = null;
        });
      }
    } catch (e) {
      setState(() {
        logoError = 'Erro ao selecionar imagem: $e';
      });
    }
  }

  void _clearLogoFile() {
    setState(() {
      logoFile = null;
      logoError = null;
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
      });

      // Check which alunos match existing matriculas
      _checkAlunosMatching();
    } catch (e) {
      setState(() {
        csvError = 'Erro ao processar arquivo CSV: $e';
      });
    }
  }

  void _checkAlunosMatching() {
    if (existingMatriculas.isEmpty) {
      setState(() {
        matchingAlunos = [];
        missingAlunos = [];
      });
      return;
    }

    final matching = <Map<String, dynamic>>[];
    final missing = <Map<String, dynamic>>[];

    if (csvData.isNotEmpty) {
      // Find CSV alunos that match existing matriculas
      for (final aluno in csvData) {
        final matricula = aluno['matricula']?.toString() ?? '';
        if (existingMatriculas.contains(matricula)) {
          matching.add(aluno);
        }
      }
    }

    // Find existing matriculas that are NOT in the CSV
    final csvMatriculas =
        csvData.map((aluno) => aluno['matricula']?.toString() ?? '').toSet();
    for (final matricula in existingMatriculas) {
      if (!csvMatriculas.contains(matricula)) {
        missing
            .add({'matricula': matricula, 'nome': 'Nome não informado no CSV'});
      }
    }

    setState(() {
      matchingAlunos = matching;
      missingAlunos = missing;
    });
  }

  Future<void> _generateReports() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Let user select output directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        if (mounted) {
          Utils.showTopSnackBar(
            context,
            'Nenhuma pasta selecionada',
            color: kWarning,
          );
        }
        return;
      }

      if (selectedTemplate == null || gabaritoData.isEmpty) {
        if (mounted) {
          Utils.showTopSnackBar(
            context,
            'Dados do template ou gabarito não encontrados',
            color: kError,
          );
        }
        return;
      }

      int successCount = 0;
      int totalCount = matchingAlunos.length;

      // Generate PDF for each matching student
      for (int i = 0; i < matchingAlunos.length; i++) {
        final aluno = matchingAlunos[i];
        final matricula = aluno['matricula']?.toString() ?? '';
        final nome = aluno['nome']?.toString() ?? '';

        try {
          // Find the card for this matricula
          AnswerSheetCardModel? card;
          try {
            card = analyzedCards.firstWhere(
              (card) {
                final matriculaBox = selectedTemplate!.boxes.firstWhere(
                  (box) => box.box.label == BoxDetailsType.matricula,
                );

                final circlesPerBox = card.circlesPerBox[matriculaBox.name];
                if (circlesPerBox == null || circlesPerBox.isEmpty)
                  return false;

                final matriculaResult = Utils.getAnswerFromCardBox(
                  box: matriculaBox,
                  circlesPerBox: circlesPerBox,
                  headersToGetSorted: [
                    {'Matricula': 'matricula'}
                  ],
                  tolerance: 0.002,
                );

                return matriculaResult['Matricula'] == matricula;
              },
            );
          } catch (e) {
            card = null;
          }

          if (card == null) {
            print('Card not found for matricula: $matricula');
            continue;
          }

          // Generate results for this specific student
          final results = HomeService.exportAlunosResults(
            cards: [card],
            template: selectedTemplate!,
            gabarito: gabaritoData,
          );

          if (results.isNotEmpty) {
            // Update preview to show current student being processed
            setState(() {
              previewAluno = aluno;
              previewResults = results.first;
            });

            // Generate PDF
            final pdfBytes = await PdfReportGenerator.generateStudentReport(
              student: aluno,
              results: results.first,
              logoFile: logoFile,
            );

            // Save PDF to selected directory
            final fileName =
                '${matricula}_${nome.replaceAll(' ', '_')}_relatorio.pdf';
            final filePath = '$selectedDirectory/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(pdfBytes);

            successCount++;
            print('Generated report for: $nome ($matricula)');
          }
        } catch (e) {
          print('Error generating report for $nome ($matricula): $e');
        }
      }

      if (mounted) {
        if (successCount == totalCount) {
          Utils.showTopSnackBar(
            context,
            'Todos os $successCount relatórios foram gerados com sucesso!',
            color: kSuccess,
          );
        } else {
          Utils.showTopSnackBar(
            context,
            '$successCount de $totalCount relatórios gerados com sucesso',
            color: kWarning,
          );
        }

        // Navigate back to home
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        Utils.showTopSnackBar(
          context,
          'Erro ao gerar relatórios: $e',
          color: kError,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
