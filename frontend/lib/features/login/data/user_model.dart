class UserModel {
  int? id;
  String? name;
  String email;
  String? phoneNumber;
  String? schoolId;

  UserModel({
    this.id,
    this.name,
    required this.email,
    this.phoneNumber,
    this.schoolId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id_user'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      schoolId: json['id_escola'] as String?,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    if (includeId) {
      return {
        'id_user': id,
        'name': name,
        'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (schoolId != null) 'id_escola': schoolId,
      };
    }
    return {
      'name': name,
      'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (schoolId != null) 'id_escola': schoolId,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? schoolId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phone ?? this.phoneNumber,
      schoolId: schoolId ?? this.schoolId,
    );
  }
}
