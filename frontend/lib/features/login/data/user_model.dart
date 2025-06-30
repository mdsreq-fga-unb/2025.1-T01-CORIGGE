class UserModel {
  int? id;
  String? name;
  String email;
  String? phoneNumber;
  int? idEscola;

  UserModel({
    this.id,
    this.name,
    required this.email,
    this.phoneNumber,
    this.idEscola,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id_user'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      idEscola: json['id_escola'] as int?,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    if (includeId) {
      return {
        'id_user': id,
        'name': name,
        'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (idEscola != null) 'id_escola': idEscola,
      };
    }
    return {
      'name': name,
      'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (idEscola != null) 'id_escola': idEscola,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    int? idEscola,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phone ?? this.phoneNumber,
      idEscola: idEscola ?? this.idEscola,
    );
  }
}
