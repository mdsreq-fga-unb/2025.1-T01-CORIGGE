import 'package:flutter/material.dart';

class GeneratedTemplateModel {
  final String name;
  final List<GeneratedTemplateField> fields;

  GeneratedTemplateModel({
    required this.name,
    required this.fields,
  });

  factory GeneratedTemplateModel.fromJson(Map<String, dynamic> json) {
    return GeneratedTemplateModel(
      name: json['name'],
      fields: (json['fields'] as List<dynamic>)
          .map((fieldJson) => GeneratedTemplateField.fromJson(fieldJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fields': fields.map((field) => field.toJson()).toList(),
    };
  }

  GeneratedTemplateModel copyWith({
    String? name,
    List<GeneratedTemplateField>? fields,
  }) {
    return GeneratedTemplateModel(
      name: name ?? this.name,
      fields: fields ?? this.fields,
    );
  }
}

abstract class GeneratedTemplateField {
  final String id;
  final Offset position;
  final Size size;
  final String type;

  GeneratedTemplateField({
    required this.id,
    required this.position,
    required this.size,
    required this.type,
  });

  factory GeneratedTemplateField.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'matricula':
        return MatriculaField.fromJson(json);
      case 'questoes_ac_ou_enem':
        return QuestoesACOuEnemField.fromJson(json);
      case 'questao_tipo_b':
        return QuestaoTipoBField.fromJson(json);
      case 'nome_aluno':
        return NomeAlunoField.fromJson(json);
      default:
        throw ArgumentError('Unknown field type: \'${json['type']}\'');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'size': {
        'width': size.width,
        'height': size.height,
      },
    };
  }

  GeneratedTemplateField copyWith({
    String? id,
    Offset? position,
    Size? size,
  });
}

class MatriculaField extends GeneratedTemplateField {
  final String label;

  MatriculaField({
    required String id,
    required Offset position,
    required Size size,
    this.label = 'Matrícula',
  }) : super(id: id, position: position, size: size, type: 'matricula');

  factory MatriculaField.fromJson(Map<String, dynamic> json) {
    return MatriculaField(
      id: json['id'],
      position: Offset(json['position']['x'], json['position']['y']),
      size: Size(json['size']['width'], json['size']['height']),
      label: json['label'] ?? 'Matrícula',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({'label': label});
    return baseJson;
  }

  @override
  MatriculaField copyWith({
    String? id,
    Offset? position,
    Size? size,
    String? label,
  }) {
    return MatriculaField(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      label: label ?? this.label,
    );
  }
}

class QuestoesACOuEnemField extends GeneratedTemplateField {
  final int totalQuestoes;

  QuestoesACOuEnemField({
    required String id,
    required Offset position,
    required Size size,
    this.totalQuestoes = 10,
  }) : super(
            id: id,
            position: position,
            size: size,
            type: 'questoes_ac_ou_enem');

  factory QuestoesACOuEnemField.fromJson(Map<String, dynamic> json) {
    return QuestoesACOuEnemField(
      id: json['id'],
      position: Offset(json['position']['x'], json['position']['y']),
      size: Size(json['size']['width'], json['size']['height']),
      totalQuestoes: json['total_questoes'] ?? 10,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({'total_questoes': totalQuestoes});
    return baseJson;
  }

  @override
  QuestoesACOuEnemField copyWith({
    String? id,
    Offset? position,
    Size? size,
    int? totalQuestoes,
  }) {
    return QuestoesACOuEnemField(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      totalQuestoes: totalQuestoes ?? this.totalQuestoes,
    );
  }
}

class QuestaoTipoBField extends GeneratedTemplateField {
  final String descricao;

  QuestaoTipoBField({
    required String id,
    required Offset position,
    required Size size,
    this.descricao = '',
  }) : super(id: id, position: position, size: size, type: 'questao_tipo_b');

  factory QuestaoTipoBField.fromJson(Map<String, dynamic> json) {
    return QuestaoTipoBField(
      id: json['id'],
      position: Offset(json['position']['x'], json['position']['y']),
      size: Size(json['size']['width'], json['size']['height']),
      descricao: json['descricao'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({'descricao': descricao});
    return baseJson;
  }

  @override
  QuestaoTipoBField copyWith({
    String? id,
    Offset? position,
    Size? size,
    String? descricao,
  }) {
    return QuestaoTipoBField(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      descricao: descricao ?? this.descricao,
    );
  }
}

class NomeAlunoField extends GeneratedTemplateField {
  final String fontSize;
  final String fontWeight;
  final String textAlign;

  NomeAlunoField({
    required String id,
    required Offset position,
    required Size size,
    this.fontSize = '16',
    this.fontWeight = 'normal',
    this.textAlign = 'left',
  }) : super(id: id, position: position, size: size, type: 'nome_aluno');

  factory NomeAlunoField.fromJson(Map<String, dynamic> json) {
    return NomeAlunoField(
      id: json['id'],
      position: Offset(json['position']['x'], json['position']['y']),
      size: Size(json['size']['width'], json['size']['height']),
      fontSize: json['font_size'] ?? '16',
      fontWeight: json['font_weight'] ?? 'normal',
      textAlign: json['text_align'] ?? 'left',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'font_size': fontSize,
      'font_weight': fontWeight,
      'text_align': textAlign,
    });
    return baseJson;
  }

  @override
  NomeAlunoField copyWith({
    String? id,
    Offset? position,
    Size? size,
    String? fontSize,
    String? fontWeight,
    String? textAlign,
  }) {
    return NomeAlunoField(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textAlign: textAlign ?? this.textAlign,
    );
  }
}
