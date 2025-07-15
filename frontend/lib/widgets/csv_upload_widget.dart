import 'package:flutter/material.dart';
import 'dart:io';

import '../config/size_config.dart';
import '../config/theme.dart';
import '../widgets/default_button_widget.dart';

class CsvUploadWidget extends StatelessWidget {
  final File? csvFile;
  final String? csvError;
  final List<Map<String, dynamic>> csvData;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  const CsvUploadWidget({
    super.key,
    required this.csvFile,
    required this.csvError,
    required this.csvData,
    required this.onPickFile,
    required this.onClearFile,
  });

  @override
  Widget build(BuildContext context) {
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
                    onPressed: onClearFile,
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
              onPressed: onPickFile,
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
}
