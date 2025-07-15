import 'package:flutter/material.dart';
import '../../data/generated_template_model.dart';
import 'template_canvas_widget.dart';
import 'template_settings_panel_widget.dart';

class TemplateEditorWidget extends StatefulWidget {
  final GeneratedTemplateModel template;
  final Function(GeneratedTemplateModel) onTemplateChanged;
  final VoidCallback onSave;
  final VoidCallback onClose;

  const TemplateEditorWidget({
    super.key,
    required this.template,
    required this.onTemplateChanged,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<TemplateEditorWidget> createState() => _TemplateEditorWidgetState();
}

class _TemplateEditorWidgetState extends State<TemplateEditorWidget> {
  late GeneratedTemplateModel currentTemplate;

  @override
  void initState() {
    super.initState();
    currentTemplate = widget.template;
  }

  void _handleTemplateChanged(GeneratedTemplateModel template) {
    setState(() {
      currentTemplate = template;
    });
    widget.onTemplateChanged(template);
  }

  void _handleGenerateTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template gerado com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editando: ${currentTemplate.name}'),
        actions: [
          IconButton(
            onPressed: widget.onSave,
            icon: const Icon(Icons.save),
            tooltip: 'Salvar template',
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            tooltip: 'Fechar edição',
          ),
        ],
      ),
      body: Row(
        children: [
          // Preview area on the left
          Expanded(
            flex: 2,
            child: TemplateCanvasWidget(
              template: currentTemplate,
              onTemplateChanged: _handleTemplateChanged,
            ),
          ),
          // Settings panel on the right
          TemplateSettingsPanelWidget(
            template: currentTemplate,
            onTemplateChanged: _handleTemplateChanged,
            onGenerateTemplate: _handleGenerateTemplate,
          ),
        ],
      ),
    );
  }
}
