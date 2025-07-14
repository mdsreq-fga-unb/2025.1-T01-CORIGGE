import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:convert';

import '../../../../config/size_config.dart';
import '../../../../config/theme.dart';
import '../../../../widgets/app_bar_custom.dart';
import '../../../../widgets/default_button_widget.dart';
import '../../../../utils/utils.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom.appBarWithLogo(
        onWantsToGoBack: () => context.go('/home'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(32)),
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
              _buildCsvUploadSection(),
              SizedBox(height: getProportionateScreenHeight(24)),

              // Logo Upload Section
              _buildLogoUploadSection(),
              SizedBox(height: getProportionateScreenHeight(32)),

              // Generate Reports Button
              _buildGenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCsvUploadSection() {
    return Container(
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
                Icons.table_chart,
                color: kPrimary,
                size: getProportionateScreenWidth(24),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Text(
                'Arquivo CSV dos Alunos',
                style: TextStyle(
                  fontSize: getProportionateFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: kOnSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Text(
            'O arquivo deve conter as colunas "matricula" e "nome" para cada aluno.',
            style: TextStyle(
              fontSize: getProportionateFontSize(14),
              color: kOnSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          if (csvFile != null) ...[
            Container(
              padding: EdgeInsets.all(getProportionateScreenWidth(12)),
              decoration: BoxDecoration(
                color: csvError != null
                    ? kError.withOpacity(0.1)
                    : kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: csvError != null ? kError : kPrimary,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.file_present,
                    color: csvError != null ? kError : kPrimary,
                    size: getProportionateScreenWidth(20),
                  ),
                  SizedBox(width: getProportionateScreenWidth(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          csvFile!.path.split('/').last,
                          style: TextStyle(
                            fontSize: getProportionateFontSize(14),
                            fontWeight: FontWeight.w500,
                            color: csvError != null ? kError : kOnSurface,
                          ),
                        ),
                        if (csvError != null)
                          Text(
                            csvError!,
                            style: TextStyle(
                              fontSize: getProportionateFontSize(12),
                              color: kError,
                            ),
                          ),
                        if (csvData.isNotEmpty)
                          Text(
                            '${csvData.length} alunos encontrados',
                            style: TextStyle(
                              fontSize: getProportionateFontSize(12),
                              color: kOnSurface.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        csvFile = null;
                        csvData.clear();
                        csvError = null;
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      color: csvError != null ? kError : kOnSurface,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            DefaultButtonWidget(
              onPressed: _pickCsvFile,
              color: kSecondaryVariant,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upload_file,
                    color: kSurface,
                    size: getProportionateScreenWidth(20),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8)),
                  Text(
                    'SELECIONAR ARQUIVO CSV',
                    style: TextStyle(
                      fontSize: getProportionateFontSize(16),
                      color: kSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoUploadSection() {
    return Container(
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
                Icons.image,
                color: kPrimary,
                size: getProportionateScreenWidth(24),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Text(
                'Logo da Escola',
                style: TextStyle(
                  fontSize: getProportionateFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: kOnSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Text(
            'Selecione uma imagem do logo da escola para incluir nos relatórios.',
            style: TextStyle(
              fontSize: getProportionateFontSize(14),
              color: kOnSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          if (logoFile != null) ...[
            Container(
              padding: EdgeInsets.all(getProportionateScreenWidth(12)),
              decoration: BoxDecoration(
                color: logoError != null
                    ? kError.withOpacity(0.1)
                    : kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: logoError != null ? kError : kPrimary,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: getProportionateScreenWidth(40),
                    height: getProportionateScreenHeight(40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: FileImage(logoFile!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          logoFile!.path.split('/').last,
                          style: TextStyle(
                            fontSize: getProportionateFontSize(14),
                            fontWeight: FontWeight.w500,
                            color: logoError != null ? kError : kOnSurface,
                          ),
                        ),
                        if (logoError != null)
                          Text(
                            logoError!,
                            style: TextStyle(
                              fontSize: getProportionateFontSize(12),
                              color: kError,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        logoFile = null;
                        logoError = null;
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      color: logoError != null ? kError : kOnSurface,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            DefaultButtonWidget(
              onPressed: _pickLogoFile,
              color: kSecondaryVariant,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image,
                    color: kSurface,
                    size: getProportionateScreenWidth(20),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8)),
                  Text(
                    'SELECIONAR LOGO',
                    style: TextStyle(
                      fontSize: getProportionateFontSize(16),
                      color: kSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    final canGenerate = csvFile != null &&
        logoFile != null &&
        csvData.isNotEmpty &&
        csvError == null &&
        logoError == null;

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
                'GERAR RELATÓRIOS INDIVIDUAIS',
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
    } catch (e) {
      setState(() {
        csvError = 'Erro ao processar arquivo CSV: $e';
      });
    }
  }

  Future<void> _generateReports() async {
    setState(() {
      isLoading = true;
    });

    try {
      // TODO: Implement the actual report generation logic
      // This would typically involve:
      // 1. Sending the CSV data and logo to the backend
      // 2. Processing the data with the analyzed cards
      // 3. Generating individual reports for each student

      await Future.delayed(Duration(seconds: 2)); // Simulate processing

      if (mounted) {
        Utils.showTopSnackBar(
          context,
          'Relatórios individuais gerados com sucesso!',
          color: kSuccess,
        );

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
