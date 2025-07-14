import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../../cache/shared_preferences_helper.dart';
import '../../../../environment.dart';
import '../../data/generated_template_model.dart';

final log = Environment.getLogger('[printable_templates_page]');

class PrintableTemplatesPage extends StatefulWidget {
  const PrintableTemplatesPage({super.key});

  @override
  State<PrintableTemplatesPage> createState() => _PrintableTemplatesPageState();
}

class _PrintableTemplatesPageState extends State<PrintableTemplatesPage> {
  List<GeneratedTemplateModel> templates = [];
  GeneratedTemplateModel? selectedTemplate;
  bool isLoading = true;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => isLoading = true);

    final result = await SharedPreferencesHelper.loadGeneratedTemplates();
    result.fold(
      (error) {
        log.severe('[loadTemplates] Error loading templates: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar templates: $error')),
        );
      },
      (loadedTemplates) {
        setState(() {
          templates = loadedTemplates;
          isLoading = false;
        });
      },
    );
  }

  Future<void> _saveTemplates() async {
    await SharedPreferencesHelper.saveGeneratedTemplates(templates);
  }

  void _createNewTemplate() {
    final newTemplate = GeneratedTemplateModel(
      name: 'Novo Template',
      fields: [],
    );

    setState(() {
      templates.add(newTemplate);
      selectedTemplate = newTemplate;
      isEditing = true;
    });

    _saveTemplates();
  }

  void _editTemplate(GeneratedTemplateModel template) {
    setState(() {
      selectedTemplate = template;
      isEditing = true;
    });
  }

  void _deleteTemplate(GeneratedTemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
            'Tem certeza que deseja excluir o template "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                templates.remove(template);
                if (selectedTemplate == template) {
                  selectedTemplate = null;
                  isEditing = false;
                }
              });
              _saveTemplates();
              Navigator.pop(context);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isEditing && selectedTemplate != null) {
      return _buildEditView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates Imprimíveis'),
        actions: [
          IconButton(
            onPressed: _createNewTemplate,
            icon: const Icon(Icons.add),
            tooltip: 'Criar novo template',
          ),
        ],
      ),
      body: templates.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum template encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Clique no botão + para criar um novo template',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return Card(
                  child: ListTile(
                    title: Text(template.name),
                    subtitle: Text('${template.fields.length} campos'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _editTemplate(template),
                          icon: const Icon(Icons.edit),
                          tooltip: 'Editar template',
                        ),
                        IconButton(
                          onPressed: () => _deleteTemplate(template),
                          icon: const Icon(Icons.delete),
                          tooltip: 'Excluir template',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEditView() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editando: ${selectedTemplate!.name}'),
        actions: [
          IconButton(
            onPressed: _saveTemplate,
            icon: const Icon(Icons.save),
            tooltip: 'Salvar template',
          ),
          IconButton(
            onPressed: _previewTemplate,
            icon: const Icon(Icons.preview),
            tooltip: 'Visualizar template',
          ),
          IconButton(
            onPressed: () => setState(() => isEditing = false),
            icon: const Icon(Icons.close),
            tooltip: 'Fechar edição',
          ),
        ],
      ),
      body: Row(
        children: [
          // Toolbox with available fields
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nome do Template',
                      border: OutlineInputBorder(),
                    ),
                    controller:
                        TextEditingController(text: selectedTemplate!.name),
                    onChanged: (value) {
                      setState(() {
                        selectedTemplate =
                            selectedTemplate!.copyWith(name: value);
                      });
                    },
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Campos Disponíveis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDraggableField(
                        'Matrícula',
                        MatriculaField(
                          id: 'matricula_${DateTime.now().millisecondsSinceEpoch}',
                          position: Offset.zero,
                          size: const Size(100, 30),
                        ),
                        Icons.badge,
                      ),
                      _buildDraggableField(
                        'Nome do Aluno',
                        NomeAlunoField(
                          id: 'nome_aluno_${DateTime.now().millisecondsSinceEpoch}',
                          position: Offset.zero,
                          size: const Size(150, 30),
                        ),
                        Icons.person,
                      ),
                      _buildDraggableField(
                        'Questões AC/ENEM',
                        QuestoesACOuEnemField(
                          id: 'questoes_ac_enem_${DateTime.now().millisecondsSinceEpoch}',
                          position: Offset.zero,
                          size: const Size(200, 100),
                        ),
                        Icons.quiz,
                      ),
                      _buildDraggableField(
                        'Questão Tipo B',
                        QuestaoTipoBField(
                          id: 'questao_tipo_b_${DateTime.now().millisecondsSinceEpoch}',
                          position: Offset.zero,
                          size: const Size(200, 80),
                        ),
                        Icons.assignment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Canvas area
          Expanded(
            child: _TemplateCanvas(
              template: selectedTemplate!,
              onTemplateChanged: (template) {
                setState(() {
                  selectedTemplate = template;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableField(
      String label, GeneratedTemplateField field, IconData icon) {
    return Draggable<GeneratedTemplateField>(
      data: field,
      feedback: Material(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _saveTemplate() {
    final index = templates.indexWhere((t) => t.name == selectedTemplate!.name);
    if (index != -1) {
      templates[index] = selectedTemplate!;
    }
    _saveTemplates();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template salvo com sucesso!')),
    );
  }

  void _previewTemplate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _TemplatePreviewPage(template: selectedTemplate!),
      ),
    );
  }
}

class _TemplateCanvas extends StatefulWidget {
  final GeneratedTemplateModel template;
  final Function(GeneratedTemplateModel) onTemplateChanged;

  const _TemplateCanvas({
    required this.template,
    required this.onTemplateChanged,
  });

  @override
  State<_TemplateCanvas> createState() => _TemplateCanvasState();
}

class _TemplateCanvasState extends State<_TemplateCanvas> {
  GeneratedTemplateField? selectedField;

  @override
  Widget build(BuildContext context) {
    return DragTarget<GeneratedTemplateField>(
      onWillAccept: (data) => data != null,
      onAccept: (field) {
        final newField = field.copyWith(
          position: const Offset(50, 50), // Default position
        );
        final updatedFields = [...widget.template.fields, newField];
        widget.onTemplateChanged(
          widget.template.copyWith(fields: updatedFields),
        );
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              // A4 paper background (approximate ratio)
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height - 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: const Center(
                  child: Text(
                    'Área do Template',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              // Template fields
              ...widget.template.fields
                  .map((field) => _buildFieldWidget(field)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFieldWidget(GeneratedTemplateField field) {
    return Positioned(
      left: field.position.dx,
      top: field.position.dy,
      child: GestureDetector(
        onTap: () => setState(() => selectedField = field),
        onPanUpdate: (details) {
          final newPosition = field.position + details.delta;
          _updateFieldPosition(field, newPosition);
        },
        child: Container(
          width: field.size.width,
          height: field.size.height,
          decoration: BoxDecoration(
            border: Border.all(
              color: selectedField == field ? Colors.blue : Colors.grey,
              width: selectedField == field ? 2 : 1,
            ),
            color: Colors.white.withOpacity(0.9),
          ),
          child: _buildFieldContent(field),
        ),
      ),
    );
  }

  Widget _buildFieldContent(GeneratedTemplateField field) {
    switch (field.runtimeType) {
      case MatriculaField:
        final matriculaField = field as MatriculaField;
        return Center(
          child: Text(
            matriculaField.label,
            style: const TextStyle(fontSize: 12),
          ),
        );
      case NomeAlunoField:
        return const Center(
          child: Text(
            'Nome do Aluno',
            style: TextStyle(fontSize: 12),
          ),
        );
      case QuestoesACOuEnemField:
        final questoesField = field as QuestoesACOuEnemField;
        return Center(
          child: Text(
            '${questoesField.totalQuestoes} questões',
            style: const TextStyle(fontSize: 12),
          ),
        );
      case QuestaoTipoBField:
        final questaoField = field as QuestaoTipoBField;
        return Center(
          child: Text(
            questaoField.descricao.isEmpty
                ? 'Questão Tipo B'
                : questaoField.descricao,
            style: const TextStyle(fontSize: 12),
          ),
        );
      default:
        return const Center(child: Text('Campo'));
    }
  }

  void _updateFieldPosition(GeneratedTemplateField field, Offset newPosition) {
    final updatedFields = widget.template.fields.map((f) {
      if (f.id == field.id) {
        return f.copyWith(position: newPosition);
      }
      return f;
    }).toList();

    widget.onTemplateChanged(
      widget.template.copyWith(fields: updatedFields),
    );
  }
}

class _TemplatePreviewPage extends StatelessWidget {
  final GeneratedTemplateModel template;

  const _TemplatePreviewPage({required this.template});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: ${template.name}'),
        actions: [
          IconButton(
            onPressed: () => _exportToPdf(context),
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar para PDF',
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Stack(
          children: template.fields
              .map((field) => _buildPreviewField(field))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPreviewField(GeneratedTemplateField field) {
    return Positioned(
      left: field.position.dx,
      top: field.position.dy,
      child: Container(
        width: field.size.width,
        height: field.size.height,
        child: _buildFieldContent(field),
      ),
    );
  }

  Widget _buildFieldContent(GeneratedTemplateField field) {
    switch (field.runtimeType) {
      case MatriculaField:
        final matriculaField = field as MatriculaField;
        return Center(
          child: Text(
            matriculaField.label,
            style: const TextStyle(fontSize: 14),
          ),
        );
      case NomeAlunoField:
        final nomeField = field as NomeAlunoField;
        return Center(
          child: Text(
            'Nome do Aluno',
            style: TextStyle(
              fontSize: double.tryParse(nomeField.fontSize) ?? 14,
              fontWeight: nomeField.fontWeight == 'bold'
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        );
      case QuestoesACOuEnemField:
        final questoesField = field as QuestoesACOuEnemField;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Questões AC/ENEM', style: TextStyle(fontSize: 12)),
              Text(
                '${questoesField.totalQuestoes} questões',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      case QuestaoTipoBField:
        final questaoField = field as QuestaoTipoBField;
        return Center(
          child: Text(
            questaoField.descricao.isEmpty
                ? 'Questão Tipo B'
                : questaoField.descricao,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        );
      default:
        return const Center(child: Text('Campo'));
    }
  }

  void _exportToPdf(BuildContext context) {
    // TODO: Implement PDF export using widget_to_pdf
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportação para PDF em desenvolvimento')),
    );
  }
}
