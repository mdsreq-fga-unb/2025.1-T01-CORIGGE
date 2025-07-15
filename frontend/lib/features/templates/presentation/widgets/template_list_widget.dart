import 'package:flutter/material.dart';
import '../../data/generated_template_model.dart';

class TemplateListWidget extends StatelessWidget {
  final List<GeneratedTemplateModel> templates;
  final Function(GeneratedTemplateModel) onEditTemplate;
  final Function(GeneratedTemplateModel) onDeleteTemplate;
  final VoidCallback onCreateTemplate;

  const TemplateListWidget({
    super.key,
    required this.templates,
    required this.onEditTemplate,
    required this.onDeleteTemplate,
    required this.onCreateTemplate,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return Card(
            child: ListTile(
              title: Text(template.name),
              subtitle: Text('${template.questions.length} questões'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => onEditTemplate(template),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar template',
                  ),
                  IconButton(
                    onPressed: () => _showDeleteDialog(context, template),
                    icon: const Icon(Icons.delete),
                    tooltip: 'Excluir template',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onCreateTemplate,
        tooltip: 'Criar novo template',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onCreateTemplate,
        tooltip: 'Criar novo template',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, GeneratedTemplateModel template) {
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
              Navigator.pop(context);
              onDeleteTemplate(template);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
