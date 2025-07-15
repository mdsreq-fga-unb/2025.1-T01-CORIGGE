import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../cache/shared_preferences_helper.dart';
import '../../../../environment.dart';
import '../../../../widgets/app_bar_custom.dart';
import '../../data/generated_template_model.dart';
import '../widgets/template_list_widget.dart';
import '../widgets/template_editor_widget.dart';

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
      nomeAlunoAutomatico: true,
      questions: [],
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
    setState(() {
      templates.remove(template);
      if (selectedTemplate == template) {
        selectedTemplate = null;
        isEditing = false;
      }
    });
    _saveTemplates();
  }

  void _saveTemplate() {
    if (selectedTemplate != null) {
      final index =
          templates.indexWhere((t) => t.name == selectedTemplate!.name);
      if (index != -1) {
        templates[index] = selectedTemplate!;
      }
      _saveTemplates();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template salvo com sucesso!')),
      );
    }
  }

  void _closeEditor() {
    setState(() {
      isEditing = false;
      selectedTemplate = null;
    });
  }

  void _handleTemplateChanged(GeneratedTemplateModel template) {
    setState(() {
      selectedTemplate = template;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isEditing && selectedTemplate != null) {
      return TemplateEditorWidget(
        template: selectedTemplate!,
        onTemplateChanged: _handleTemplateChanged,
        onSave: _saveTemplate,
        onClose: _closeEditor,
      );
    }

    return Scaffold(
      appBar: AppBarCustom.appBarWithLogo(
          context: context,
          onWantsToGoBack: () {
            context.go("/home");
          }),
      body: TemplateListWidget(
        templates: templates,
        onEditTemplate: _editTemplate,
        onDeleteTemplate: _deleteTemplate,
        onCreateTemplate: _createNewTemplate,
      ),
    );
  }
}
