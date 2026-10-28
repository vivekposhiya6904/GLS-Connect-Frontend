class UserModel {
  final int? id;
  final String name;
  final String email;
  final String role;
  final String? profilePictureUrl;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profilePictureUrl,
  });

  // Convert JSON → UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? json['roleName'] ?? 'USER',
      profilePictureUrl: json['profilePictureUrl']?.toString(),
    );
  }

  // Convert UserModel → JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "role": role,
      "profilePictureUrl": profilePictureUrl,
    };
  }
}
