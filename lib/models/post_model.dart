class PostModel {
  final int? id;
  final String content;
  final String? imageUrl;
  final String? createdAt;
  final int userId;
  final String userName;
  final String userEmail;
  final String userRole;
  final String posterDepartment;
  final String posterDesignation;

  PostModel({
    this.id,
    required this.content,
    this.imageUrl,
    this.createdAt,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.posterDepartment,
    required this.posterDesignation,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'],
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userRole: json['userRole'] ?? '',
      posterDepartment: json['posterDepartment'] ?? 'N/A',
      posterDesignation: json['posterDesignation'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRole': userRole,
      'posterDepartment': posterDepartment,
      'posterDesignation': posterDesignation,
    };
  }
}
