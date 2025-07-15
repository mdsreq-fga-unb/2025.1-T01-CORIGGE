import 'package:flutter/material.dart';
import '../../data/generated_template_model.dart';

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
  late TextEditingController _questionsController;
  late bool nomeAlunoAutomatico;
  late int numeroQuestoes;
  late List<TypeQuestion> tiposQuestoes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    nomeAlunoAutomatico = widget.template.nomeAlunoAutomatico;
    numeroQuestoes = widget.template.questions.length > 0
        ? widget.template.questions.length
        : 10;
    tiposQuestoes = widget.template.questions.isNotEmpty
        ? widget.template.questions.map((q) => q.type).toList()
        : [TypeQuestion.A];
    _questionsController =
        TextEditingController(text: numeroQuestoes.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _questionsController.dispose();
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
          const SizedBox(height: 16),
          _buildQuestionsNumberField(),
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

  Widget _buildQuestionsNumberField() {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Número de questões',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      controller: _questionsController,
      onChanged: (value) {
        final number = int.tryParse(value) ?? 10;
        if (number > 0 && number <= 156) {
          // Max 150 A/C + 6 B
          setState(() {
            numeroQuestoes = number;
            _adjustQuestionTypes();
          });
        }
      },
    );
  }

  Widget _buildQuestionTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipos de questões',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Máximo: 150 questões A/C e 6 questões B',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _buildQuestionTypesList(),
      ],
    );
  }

  Widget _buildQuestionTypesList() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: numeroQuestoes,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Questão ${index + 1}'),
            trailing: DropdownButton<TypeQuestion>(
              value: index < tiposQuestoes.length
                  ? tiposQuestoes[index]
                  : TypeQuestion.A,
              items: const [
                DropdownMenuItem(value: TypeQuestion.A, child: Text('Tipo A')),
                DropdownMenuItem(value: TypeQuestion.B, child: Text('Tipo B')),
                DropdownMenuItem(value: TypeQuestion.C, child: Text('Tipo C')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    if (index < tiposQuestoes.length) {
                      // Check if changing to B would exceed the limit
                      if (value == TypeQuestion.B) {
                        final currentBCount = tiposQuestoes
                            .where((t) => t == TypeQuestion.B)
                            .length;
                        if (tiposQuestoes[index] != TypeQuestion.B &&
                            currentBCount >= 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Máximo de 6 questões tipo B permitidas')),
                          );
                          return;
                        }
                      }
                      tiposQuestoes[index] = value;
                    }
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenerateTemplateButton() {
    return ElevatedButton.icon(
      onPressed: _generateTemplate,
      icon: const Icon(Icons.auto_awesome),
      label: const Text('Gerar Template'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  void _adjustQuestionTypes() {
    if (tiposQuestoes.length < numeroQuestoes) {
      // Add more questions with type A
      while (tiposQuestoes.length < numeroQuestoes) {
        tiposQuestoes.add(TypeQuestion.A);
      }
    } else if (tiposQuestoes.length > numeroQuestoes) {
      // Remove excess questions
      tiposQuestoes = tiposQuestoes.take(numeroQuestoes).toList();
    }
  }

  void _generateTemplate() {
    // Generate questions based on types
    final questions = <GeneratedTemplateQuestion>[];
    for (int i = 0; i < tiposQuestoes.length; i++) {
      questions.add(GeneratedTemplateQuestion(
        type: tiposQuestoes[i],
        numero: i + 1,
      ));
    }

    final updatedTemplate = widget.template.copyWith(
      questions: questions,
      nomeAlunoAutomatico: nomeAlunoAutomatico,
    );

    widget.onTemplateChanged(updatedTemplate);
    widget.onGenerateTemplate();
  }
}
