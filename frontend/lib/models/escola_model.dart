class EscolaModel {
  final int id;
  final String nome;

  EscolaModel({required this.id, required this.nome});

  factory EscolaModel.fromJson(Map<String, dynamic> json) {
    return EscolaModel(
      id: json['id_escola'],
      nome: json['nome_escola'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_escola': id,
      'nome_escola': nome,
    };
  }
}
