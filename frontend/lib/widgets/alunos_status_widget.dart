import 'package:flutter/material.dart';

import '../config/size_config.dart';
import '../config/theme.dart';

class AlunosStatusWidget extends StatelessWidget {
  final List<Map<String, dynamic>> matchingAlunos;
  final List<Map<String, dynamic>> missingAlunos;
  final List<Map<String, dynamic>> csvData;
  final List<String> existingMatriculas;
  final Function(Map<String, dynamic>) onHoverAluno;

  const AlunosStatusWidget({
    super.key,
    required this.matchingAlunos,
    required this.missingAlunos,
    required this.csvData,
    required this.existingMatriculas,
    required this.onHoverAluno,
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
                Icons.people,
                color: kPrimary,
                size: getProportionateScreenWidth(24),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Text(
                'Status dos Alunos',
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
            'Comparação entre alunos do CSV e cartões-resposta analisados:',
            style: TextStyle(
              fontSize: getProportionateFontSize(14),
              color: kOnSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),

          // Matching Alunos Section
          if (matchingAlunos.isNotEmpty) ...[
            _buildAlunosSection(
              'Alunos do CSV com Cartões Analisados (${matchingAlunos.length})',
              matchingAlunos,
              kSuccess,
              Icons.check_circle,
              true, // Enable hover for matching alunos
            ),
            SizedBox(height: getProportionateScreenHeight(12)),
          ],

          // Missing Alunos Section
          if (missingAlunos.isNotEmpty) ...[
            _buildAlunosSection(
              'Cartões Analisados sem Nome no CSV (${missingAlunos.length})',
              missingAlunos,
              kWarning,
              Icons.warning,
              false, // No hover for missing alunos
            ),
          ],

          // Summary
          if (csvData.isNotEmpty) ...[
            SizedBox(height: getProportionateScreenHeight(16)),
            Container(
              padding: EdgeInsets.all(getProportionateScreenWidth(12)),
              decoration: BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kSecondary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: kOnSurface.withOpacity(0.7),
                    size: getProportionateScreenWidth(16),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8)),
                  Expanded(
                    child: Text(
                      'CSV: ${csvData.length} alunos | '
                      'Cartões analisados: ${existingMatriculas.length} | '
                      'Correspondências: ${matchingAlunos.length} | '
                      'Cartões sem nome: ${missingAlunos.length}',
                      style: TextStyle(
                        fontSize: getProportionateFontSize(12),
                        color: kOnSurface.withOpacity(0.7),
                      ),
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

  Widget _buildAlunosSection(String title, List<Map<String, dynamic>> alunos,
      Color color, IconData icon, bool enableHover) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: getProportionateScreenWidth(16),
            ),
            SizedBox(width: getProportionateScreenWidth(8)),
            Text(
              title,
              style: TextStyle(
                fontSize: getProportionateFontSize(14),
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: getProportionateScreenHeight(8)),
        Container(
          constraints: BoxConstraints(
            maxHeight: getProportionateScreenHeight(150),
          ),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: getProportionateScreenWidth(8),
              runSpacing: getProportionateScreenHeight(8),
              children: alunos.map((aluno) {
                final matricula = aluno['matricula']?.toString() ?? '';
                final nome = aluno['nome']?.toString() ?? '';

                Widget alunoWidget = Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(12),
                    vertical: getProportionateScreenHeight(6),
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matricula,
                        style: TextStyle(
                          fontSize: getProportionateFontSize(12),
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (nome.isNotEmpty)
                        Text(
                          nome,
                          style: TextStyle(
                            fontSize: getProportionateFontSize(10),
                            color: color.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                );

                if (enableHover) {
                  return MouseRegion(
                    onEnter: (_) => onHoverAluno(aluno),
                    child: alunoWidget,
                  );
                } else {
                  return alunoWidget;
                }
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
