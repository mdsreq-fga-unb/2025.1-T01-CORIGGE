class UserModel {
  int? id;
  String? name;
  String email;

  UserModel({
    this.id,
    this.name,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id_user'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    if (includeId) {
      return {
        'id_user': id,
        'name': name,
        'email': email,
      };
    }
    return {
      'name': name,
      'email': email,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    List<String>? vehicleIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
