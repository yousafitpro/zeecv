class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? token;
  final String? loginToken;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.token,
    this.loginToken,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['fullName'] ?? '',
      token: json['token'] ?? json['access_token'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      loginToken: json['loginToken'] ?? json['access_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'token': token,
      'createdAt': createdAt?.toIso8601String(),
      'loginToken': loginToken,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? token,
    DateTime? createdAt,
    String? loginToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      loginToken: loginToken ?? this.loginToken,
    );
  }
}