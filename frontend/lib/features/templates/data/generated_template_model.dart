import 'package:flutter/material.dart';

class GeneratedTemplateModel {
  final String name;
  final bool nomeAlunoAutomatico;
  final List<GeneratedTemplateQuestion> questions;

  GeneratedTemplateModel({
    required this.name,
    required this.nomeAlunoAutomatico,
    required this.questions,
  });

  GeneratedTemplateModel copyWith({
    String? name,
    bool? nomeAlunoAutomatico,
    List<GeneratedTemplateQuestion>? questions,
  }) {
    return GeneratedTemplateModel(
      name: name ?? this.name,
      nomeAlunoAutomatico: nomeAlunoAutomatico ?? this.nomeAlunoAutomatico,
      questions: questions ?? this.questions,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'nomeAlunoAutomatico': nomeAlunoAutomatico,
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory GeneratedTemplateModel.fromJson(Map<String, dynamic> json) =>
      GeneratedTemplateModel(
        name: json['name'],
        nomeAlunoAutomatico: json['nomeAlunoAutomatico'],
        questions: List<GeneratedTemplateQuestion>.from(json['questions']
            .map((q) => GeneratedTemplateQuestion.fromJson(q))),
      );
}

class GeneratedTemplateQuestion {
  final TypeQuestion type;
  final int numero;

  GeneratedTemplateQuestion({
    required this.type,
    required this.numero,
  });

  GeneratedTemplateQuestion copyWith({
    TypeQuestion? type,
    int? numero,
  }) =>
      GeneratedTemplateQuestion(
        type: type ?? this.type,
        numero: numero ?? this.numero,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'numero': numero,
      };

  factory GeneratedTemplateQuestion.fromJson(Map<String, dynamic> json) =>
      GeneratedTemplateQuestion(
        type: TypeQuestion.values.byName(json['type']),
        numero: json['numero'],
      );
}

enum TypeQuestion {
  A,
  B,
  C,
}
