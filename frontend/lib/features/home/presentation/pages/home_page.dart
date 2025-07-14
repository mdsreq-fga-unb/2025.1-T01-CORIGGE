import 'package:corigge/config/size_config.dart';
import 'package:corigge/widgets/app_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:corigge/config/theme.dart';
import 'package:corigge/widgets/default_button_widget.dart';
import 'package:corigge/widgets/overlay_info_card_widget.dart';
import 'package:corigge/widgets/logo_background_widget.dart';
import 'package:corigge/cache/shared_preferences_helper.dart';
import 'package:corigge/features/templates/data/answer_sheet_template_model.dart';
import 'package:corigge/features/templates/data/answer_sheet_card_model.dart';
import 'package:corigge/features/templates/data/answer_sheet_identifiable_box.dart';
import 'package:corigge/features/home/services/home_service.dart';
import 'package:corigge/utils/utils.dart';
import 'package:corigge/utils/image_bounding_box/data/box_details.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AnswerSheetTemplateModel? selectedTemplate;
  List<AnswerSheetCardModel> analyzedCards = [];
  bool isLoading = true;
  File? gabaritoFile;
  List<Map<String, dynamic>> gabaritoData = [];
  String? gabaritoError;
  bool isValidatingGabarito = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load available templates
      final templatesResult = await SharedPreferencesHelper.loadTemplates();
      final templates = templatesResult.fold(
          (error) => <AnswerSheetTemplateModel>[], (templates) => templates);

      // Load selected template and verify it still exists
      final selectedTemplateId =
          await SharedPreferencesHelper.getSelectedTemplate();
      AnswerSheetTemplateModel? validTemplate;

      if (selectedTemplateId != null) {
        // Check if the selected template still exists in the templates list
        try {
          validTemplate = templates.firstWhere(
            (template) => template.id == selectedTemplateId.id,
          );
        } catch (e) {
          // Template not found, keep validTemplate as null
          validTemplate = null;
        }

        // If template no longer exists, clear the selection
        if (validTemplate == null) {
          await SharedPreferencesHelper.saveSelectedTemplate(null);
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
          selectedTemplate = validTemplate;
          analyzedCards = cards;
          gabaritoData = gabarito;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _pickGabaritoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          gabaritoFile = File(result.files.single.path!);
          gabaritoError = null;
          isValidatingGabarito = true;
        });

        await _validateGabarito();
      }
    } catch (e) {
      setState(() {
        gabaritoError = 'Erro ao selecionar arquivo: $e';
        isValidatingGabarito = false;
      });
    }
  }

  Future<void> _validateGabarito() async {
    if (gabaritoFile == null || selectedTemplate == null) {
      setState(() {
        gabaritoError = 'Template ou arquivo não selecionado';
        isValidatingGabarito = false;
      });
      return;
    }

    try {
      final contents = await gabaritoFile!.readAsString();
      final lines =
          contents.split('\n').where((line) => line.trim().isNotEmpty).toList();

      if (lines.isEmpty) {
        setState(() {
          gabaritoError = 'Arquivo CSV vazio';
          isValidatingGabarito = false;
        });
        return;
      }

      // Parse CSV with improved handling
      List<Map<String, dynamic>> parsedData = [];

      // Try different delimiters
      String delimiter = ',';
      if (lines[0].contains(';')) {
        delimiter = ';';
      } else if (lines[0].contains('\t')) {
        delimiter = '\t';
      }

      final headers = _parseCSVLine(lines[0], delimiter);

      // Clean headers
      final cleanHeaders = headers.map((h) => h.trim().toLowerCase()).toList();

      for (int i = 1; i < lines.length; i++) {
        final values = _parseCSVLine(lines[i], delimiter);
        if (values.length == headers.length) {
          Map<String, dynamic> row = {};
          for (int j = 0; j < headers.length; j++) {
            row[cleanHeaders[j]] = values[j].trim();
          }
          parsedData.add(row);
        }
      }

      // Validate against template
      final validationResult = _validateGabaritoAgainstTemplate(parsedData);

      setState(() {
        if (validationResult == null) {
          gabaritoData = parsedData;
          gabaritoError = null;
        } else {
          gabaritoError = validationResult;
        }
        isValidatingGabarito = false;
      });

      // Save gabarito data if validation passed
      if (validationResult == null) {
        await SharedPreferencesHelper.saveGabarito(parsedData);
      }
    } catch (e) {
      setState(() {
        gabaritoError = 'Erro ao processar arquivo CSV: $e';
        isValidatingGabarito = false;
      });
    }
  }

  List<String> _parseCSVLine(String line, String delimiter) {
    List<String> result = [];
    bool inQuotes = false;
    String current = '';

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == delimiter && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }

    result.add(current);
    return result;
  }

  String? _validateGabaritoAgainstTemplate(List<Map<String, dynamic>> data) {
    if (selectedTemplate == null) return 'Template não selecionado';

    // Get question boxes from template
    final questionBoxes = selectedTemplate!.boxes
        .where((box) =>
            box.box.label == BoxDetailsType.colunaDeQuestoes ||
            box.box.label == BoxDetailsType.typeB)
        .toList();

    if (questionBoxes.isEmpty) {
      return 'Template não possui caixas de questões';
    }

    // Get template questions using service
    final templateQuestions = HomeService.getTemplateQuestions(questionBoxes);

    if (templateQuestions.isEmpty) {
      return 'Template não possui questões calculadas (verifique se os círculos foram detectados)';
    }

    // Check if gabarito has required columns
    if (data.isEmpty) return 'Gabarito vazio';

    final gabaritoKeys = data.first.keys.toList();

    // Check for question column (flexible naming)
    String? questionColumn;
    for (final key in gabaritoKeys) {
      if (key.contains('questao') ||
          key.contains('question') ||
          key.contains('numero')) {
        questionColumn = key;
        break;
      }
    }

    // Check for answer column (flexible naming)
    String? answerColumn;
    for (final key in gabaritoKeys) {
      if (key.contains('resposta') ||
          key.contains('answer') ||
          key.contains('gabarito')) {
        answerColumn = key;
        break;
      }
    }

    if (questionColumn == null || answerColumn == null) {
      return 'Gabarito deve conter colunas de questão e resposta (ex: "questao" e "resposta")';
    }

    // Extract question numbers from gabarito
    List<int> gabaritoQuestions = [];
    for (final row in data) {
      final questionValue = row[questionColumn];
      final questionNum = int.tryParse(questionValue.toString());
      if (questionNum != null) {
        gabaritoQuestions.add(questionNum);
      }
    }

    if (gabaritoQuestions.isEmpty) {
      return 'Não foi possível extrair números das questões do gabarito';
    }

    gabaritoQuestions.sort();

    // Compare questions - show detailed information about ranges
    if (gabaritoQuestions.length != templateQuestions.length) {
      final templateRanges =
          HomeService.buildQuestionRangesDescription(questionBoxes);
      return 'Número de questões não corresponde:\n'
          'Template: ${templateQuestions.length} questões $templateRanges\n'
          'Gabarito: ${gabaritoQuestions.length} questões';
    }

    // Check if all template questions are in gabarito
    final missingQuestions = <int>[];
    for (final templateQuestion in templateQuestions) {
      if (!gabaritoQuestions.contains(templateQuestion)) {
        missingQuestions.add(templateQuestion);
      }
    }

    if (missingQuestions.isNotEmpty) {
      return 'Questões do template não encontradas no gabarito: ${missingQuestions.join(', ')}';
    }

    // Check for extra questions in gabarito
    final extraQuestions = <int>[];
    for (final gabaritoQuestion in gabaritoQuestions) {
      if (!templateQuestions.contains(gabaritoQuestion)) {
        extraQuestions.add(gabaritoQuestion);
      }
    }

    if (extraQuestions.isNotEmpty) {
      return 'Questões no gabarito não encontradas no template: ${extraQuestions.join(', ')}';
    }

    // Validate answers are valid (A, B, C, D, E)
    final validAnswers = {'A', 'B', 'C', 'D', 'E', 'a', 'b', 'c', 'd', 'e'};
    final invalidAnswers = <String>[];

    for (final row in data) {
      final answer = row[answerColumn].toString().trim();
      if (answer.isNotEmpty && !validAnswers.contains(answer)) {
        if (!invalidAnswers.contains(answer)) {
          invalidAnswers.add(answer);
        }
      }
    }

    if (invalidAnswers.isNotEmpty) {
      return 'Respostas inválidas encontradas: ${invalidAnswers.join(', ')}. Use apenas A, B, C, D ou E';
    }

    return null; // Validation passed
  }

  Widget _buildGabaritoSummary() {
    if (gabaritoData.isEmpty) return const SizedBox.shrink();

    // Find question and answer columns
    String? questionColumn;
    String? answerColumn;
    final keys = gabaritoData.first.keys.toList();

    for (final key in keys) {
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

    if (questionColumn == null || answerColumn == null) {
      return const SizedBox.shrink();
    }

    // Sort gabarito by question number
    final sortedGabarito = List<Map<String, dynamic>>.from(gabaritoData);
    sortedGabarito.sort((a, b) {
      final aQuestion = int.tryParse(a[questionColumn].toString()) ?? 0;
      final bQuestion = int.tryParse(b[questionColumn].toString()) ?? 0;
      return aQuestion.compareTo(bQuestion);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: getProportionateScreenHeight(12)),
        Text(
          'Resumo do Gabarito:',
          style: TextStyle(
            fontSize: getProportionateFontSize(14),
            fontWeight: FontWeight.bold,
            color: kOnSurface,
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(8)),
        Container(
          height: getProportionateScreenHeight(150),
          decoration: BoxDecoration(
            border: Border.all(color: kSecondary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(getProportionateScreenWidth(8)),
            child: Wrap(
              spacing: getProportionateScreenWidth(8),
              runSpacing: getProportionateScreenHeight(4),
              children: sortedGabarito.map((row) {
                final question = row[questionColumn].toString();
                final answer = row[answerColumn].toString().toUpperCase();
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(8),
                    vertical: getProportionateScreenHeight(4),
                  ),
                  decoration: BoxDecoration(
                    color: kSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$question: $answer',
                    style: TextStyle(
                      fontSize: getProportionateFontSize(12),
                      color: kOnSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoxTypesList() {
    if (selectedTemplate == null) return const SizedBox.shrink();

    final organizationResult =
        HomeService.organizeTemplateBoxes(selectedTemplate!.boxes);
    final questionBoxes = organizationResult.questionBoxes;
    final otherBoxes = organizationResult.otherBoxes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display question boxes with detailed information
        ...questionBoxes.map((boxInfo) {
          final box = boxInfo['box'] as AnswerSheetIdentifiableBox;
          final startingQuestion = boxInfo['startingQuestion'] as int;
          final questionCount = boxInfo['questionCount'] as int;
          final typeName = boxInfo['typeName'] as String;

          final endQuestion = startingQuestion + questionCount - 1;

          return Padding(
            padding:
                EdgeInsets.symmetric(vertical: getProportionateScreenHeight(2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      typeName,
                      style: TextStyle(
                        fontSize: getProportionateFontSize(14),
                        color: kOnSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '1 coluna',
                      style: TextStyle(
                        fontSize: getProportionateFontSize(14),
                        color: kOnSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: getProportionateScreenHeight(2)),
                Padding(
                  padding:
                      EdgeInsets.only(left: getProportionateScreenWidth(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        questionCount > 0
                            ? 'Questões $startingQuestion-$endQuestion'
                            : 'Questão $startingQuestion (sem círculos)',
                        style: TextStyle(
                          fontSize: getProportionateFontSize(12),
                          color: kOnSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '$questionCount ${questionCount == 1 ? 'questão' : 'questões'}',
                        style: TextStyle(
                          fontSize: getProportionateFontSize(12),
                          color: kOnSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (box.circles.isNotEmpty) ...[
                  SizedBox(height: getProportionateScreenHeight(2)),
                  Padding(
                    padding:
                        EdgeInsets.only(left: getProportionateScreenWidth(8)),
                    child: Text(
                      '${box.circles.length} círculos detectados',
                      style: TextStyle(
                        fontSize: getProportionateFontSize(11),
                        color: kOnSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),

        // Display other box types
        ...otherBoxes.entries.map((entry) {
          final typeName = entry.key;
          final boxInfo = entry.value;

          if (typeName == "Matrícula" && boxInfo['matriculaInfo'] != null) {
            final matriculaInfo = boxInfo['matriculaInfo'] as MatriculaInfo;

            return Padding(
              padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        typeName,
                        style: TextStyle(
                          fontSize: getProportionateFontSize(14),
                          color: kOnSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${boxInfo['count']}',
                        style: TextStyle(
                          fontSize: getProportionateFontSize(14),
                          color: kOnSurface.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (matriculaInfo.totalCircles > 0) ...[
                    SizedBox(height: getProportionateScreenHeight(2)),
                    Padding(
                      padding:
                          EdgeInsets.only(left: getProportionateScreenWidth(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grade ${matriculaInfo.rows}x${matriculaInfo.columns}',
                            style: TextStyle(
                              fontSize: getProportionateFontSize(12),
                              color: kOnSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '${matriculaInfo.totalCircles} círculos',
                            style: TextStyle(
                              fontSize: getProportionateFontSize(12),
                              color: kOnSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: getProportionateScreenHeight(2)),
                    Padding(
                      padding:
                          EdgeInsets.only(left: getProportionateScreenWidth(8)),
                      child: Text(
                        'Sem círculos detectados',
                        style: TextStyle(
                          fontSize: getProportionateFontSize(12),
                          color: kOnSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          } else {
            return Padding(
              padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(2)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    typeName,
                    style: TextStyle(
                      fontSize: getProportionateFontSize(14),
                      color: kOnSurface,
                    ),
                  ),
                  Text(
                    '${boxInfo['count'] ?? boxInfo}',
                    style: TextStyle(
                      fontSize: getProportionateFontSize(14),
                      color: kOnSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom.appBarWithLogo(),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(32)),
          child: Row(
            children: [
              // Left side with logo and information
              Expanded(
                child: Builder(builder: (context) {
                  return Stack(
                    children: [
                      // Logo background layer (rendered first, behind everything)
                      const LogoBackgroundWidget(),

                      // Blur effect over the logos (only show if there's content to display)
                      if (selectedTemplate != null || analyzedCards.isNotEmpty)
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),

                      // Overlaid information cards (only show if there's content)
                      if (selectedTemplate != null || analyzedCards.isNotEmpty)
                        Positioned(
                          top: getProportionateScreenHeight(20),
                          left: getProportionateScreenWidth(16),
                          right: getProportionateScreenWidth(16),
                          child: Column(
                            children: [
                              // Template information section (only show if template is selected)
                              if (selectedTemplate != null)
                                OverlayInfoCardWidget(
                                  title: 'TEMPLATE SELECIONADO',
                                  child: isLoading
                                      ? const CircularProgressIndicator()
                                      : Column(
                                          children: [
                                            Text(
                                              selectedTemplate!.name,
                                              style: TextStyle(
                                                fontSize:
                                                    getProportionateFontSize(
                                                        14),
                                                color: kOnSurface,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(
                                                height:
                                                    getProportionateScreenHeight(
                                                        4)),
                                            Text(
                                              '${selectedTemplate!.boxes.length} caixas de resposta',
                                              style: TextStyle(
                                                fontSize:
                                                    getProportionateFontSize(
                                                        12),
                                                color:
                                                    kOnSurface.withOpacity(0.7),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(
                                                height:
                                                    getProportionateScreenHeight(
                                                        8)),
                                            Divider(
                                                color: kSecondary
                                                    .withOpacity(0.3)),
                                            SizedBox(
                                                height:
                                                    getProportionateScreenHeight(
                                                        8)),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Tipos de Caixas:',
                                                style: TextStyle(
                                                  fontSize:
                                                      getProportionateFontSize(
                                                          12),
                                                  fontWeight: FontWeight.bold,
                                                  color: kOnSurface,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                                height:
                                                    getProportionateScreenHeight(
                                                        4)),
                                            _buildBoxTypesList(),
                                          ],
                                        ),
                                ),
                              SizedBox(
                                  height: getProportionateScreenHeight(16)),

                              // Cards analyzed information (only show if there are cards or loading)
                              if (analyzedCards.isNotEmpty || isLoading)
                                OverlayInfoCardWidget(
                                  title: 'CARTÕES ANALISADOS',
                                  child: isLoading
                                      ? const CircularProgressIndicator()
                                      : Text(
                                          '${analyzedCards.length} ${analyzedCards.length == 1 ? 'cartão' : 'cartões'}',
                                          style: TextStyle(
                                            fontSize:
                                                getProportionateFontSize(14),
                                            color: kOnSurface,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                }),
              ),
              // Right side with buttons
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'ESCOLHA UM TEMPLATE DE CARTÃO-RESPOSTA',
                        style: TextStyle(
                          fontSize: getProportionateFontSize(24),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: getProportionateScreenHeight(20)),
                      DefaultButtonWidget(
                        onPressed: () {
                          context.go('/templates');
                        },
                        color: kSecondaryVariant,
                        child: Text(
                          'CRIAR GABARITO',
                          style: TextStyle(
                            fontSize: getProportionateFontSize(18),
                            color: kSurface,
                          ),
                        ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(40)),
                      Text(
                        'INSIRA OS CARTÕES-RESPOSTA',
                        style: TextStyle(
                          fontSize: getProportionateFontSize(24),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: getProportionateScreenHeight(20)),
                      Tooltip(
                        message: selectedTemplate == null
                            ? 'Selecione um template primeiro'
                            : '',
                        child: DefaultButtonWidget(
                          onPressed: selectedTemplate != null
                              ? () {
                                  context.go('/analyze-cards');
                                }
                              : null,
                          color: selectedTemplate != null
                              ? kSecondaryVariant
                              : kSecondaryVariant.withOpacity(0.5),
                          child: Text(
                            'CORRIGIR CARTÕES',
                            style: TextStyle(
                              fontSize: getProportionateFontSize(18),
                              color: selectedTemplate != null
                                  ? kSurface
                                  : kSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(40)),

                      // Gabarito section
                      Container(
                        padding:
                            EdgeInsets.all(getProportionateScreenWidth(16)),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: kSecondary.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'GABARITO DAS QUESTÕES',
                              style: TextStyle(
                                fontSize: getProportionateFontSize(20),
                                fontWeight: FontWeight.bold,
                                color: kOnSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            Text(
                              'Envie um arquivo CSV com as colunas "questao" e "resposta"',
                              style: TextStyle(
                                fontSize: getProportionateFontSize(14),
                                color: kOnSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: getProportionateScreenHeight(16)),
                            if (gabaritoFile != null) ...[
                              Container(
                                padding: EdgeInsets.all(
                                    getProportionateScreenWidth(12)),
                                decoration: BoxDecoration(
                                  color: gabaritoError != null
                                      ? kError.withOpacity(0.1)
                                      : kSuccess.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: gabaritoError != null
                                          ? kError.withOpacity(0.3)
                                          : kSuccess.withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          gabaritoError != null
                                              ? Icons.error
                                              : Icons.check_circle,
                                          color: gabaritoError != null
                                              ? kError
                                              : kSuccess,
                                          size: getProportionateScreenWidth(20),
                                        ),
                                        SizedBox(
                                            width:
                                                getProportionateScreenWidth(8)),
                                        Expanded(
                                          child: Text(
                                            gabaritoFile!.path.split('/').last,
                                            style: TextStyle(
                                              fontSize:
                                                  getProportionateFontSize(14),
                                              color: kOnSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (gabaritoError != null) ...[
                                      SizedBox(
                                          height:
                                              getProportionateScreenHeight(8)),
                                      Text(
                                        gabaritoError!,
                                        style: TextStyle(
                                          fontSize:
                                              getProportionateFontSize(12),
                                          color: kError,
                                        ),
                                      ),
                                    ] else if (gabaritoData.isNotEmpty) ...[
                                      SizedBox(
                                          height:
                                              getProportionateScreenHeight(8)),
                                      Text(
                                        'Gabarito válido com ${gabaritoData.length} questões',
                                        style: TextStyle(
                                          fontSize:
                                              getProportionateFontSize(12),
                                          color: kSuccess,
                                        ),
                                      ),
                                      _buildGabaritoSummary(),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(12)),
                            ],
                            if (isValidatingGabarito) ...[
                              const CircularProgressIndicator(),
                              SizedBox(height: getProportionateScreenHeight(8)),
                              Text(
                                'Validando gabarito...',
                                style: TextStyle(
                                  fontSize: getProportionateFontSize(14),
                                  color: kOnSurface.withOpacity(0.7),
                                ),
                              ),
                            ] else ...[
                              Tooltip(
                                message: selectedTemplate == null
                                    ? 'Selecione um template primeiro'
                                    : analyzedCards.isEmpty
                                        ? 'Analise os cartões primeiro'
                                        : '',
                                child: DefaultButtonWidget(
                                  onPressed: selectedTemplate != null &&
                                          analyzedCards.isNotEmpty
                                      ? _pickGabaritoFile
                                      : null,
                                  color: selectedTemplate != null &&
                                          analyzedCards.isNotEmpty
                                      ? kSecondaryVariant
                                      : kSecondaryVariant.withOpacity(0.5),
                                  child: Text(
                                    gabaritoFile != null
                                        ? 'ALTERAR GABARITO'
                                        : 'SELECIONAR GABARITO',
                                    style: TextStyle(
                                      fontSize: getProportionateFontSize(16),
                                      color: selectedTemplate != null &&
                                              analyzedCards.isNotEmpty
                                          ? kSurface
                                          : kSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                              if (selectedTemplate == null) ...[
                                SizedBox(
                                    height: getProportionateScreenHeight(8)),
                                Text(
                                  'Selecione um template primeiro',
                                  style: TextStyle(
                                    fontSize: getProportionateFontSize(12),
                                    color: kOnSurface.withOpacity(0.7),
                                  ),
                                ),
                              ] else if (analyzedCards.isEmpty) ...[
                                SizedBox(
                                    height: getProportionateScreenHeight(8)),
                                Text(
                                  'Analise os cartões primeiro',
                                  style: TextStyle(
                                    fontSize: getProportionateFontSize(12),
                                    color: kOnSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ],
                          ],
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
