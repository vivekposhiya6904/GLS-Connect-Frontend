class StudentProfileModel {
  final int? userId;
  final String? userName;
  final String? email;
  final String? universityNumber;
  final String? department;
  final String? degree;
  final int? batchYear;
  final String? semester;
  final String? skills;
  final String? interests;
  final String? bio;
  final String? linkedInUrl;
  final String? githubUrl;
  final String? contactNumber;
  final String? currentCity;
  final String? profilePictureUrl;

  StudentProfileModel({
    this.userId,
    this.userName,
    this.email,
    this.universityNumber,
    this.department,
    this.degree,
    this.batchYear,
    this.semester,
    this.skills,
    this.interests,
    this.bio,
    this.linkedInUrl,
    this.githubUrl,
    this.contactNumber,
    this.currentCity,
    this.profilePictureUrl,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? ""),
      userName: json['userName']?.toString(),
      email: json['email']?.toString(),
      universityNumber: json['universityNumber']?.toString(),
      department: json['department']?.toString(),
      degree: json['degree']?.toString(),
      batchYear: json['batchYear'] is int
          ? json['batchYear']
          : int.tryParse(json['batchYear']?.toString() ?? ""),
      semester: json['semester']?.toString(),
      skills: json['skills']?.toString(),
      interests: json['interests']?.toString(),
      bio: json['bio']?.toString(),
      linkedInUrl: json['linkedInUrl']?.toString(),
      githubUrl: json['githubUrl']?.toString(),
      contactNumber: json['contactNumber']?.toString(),
      currentCity: json['currentCity']?.toString(),
      profilePictureUrl: json['profilePictureUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'department': department,
      'degree': degree,
      'batchYear': batchYear,
      'semester': semester,
      'skills': skills,
      'interests': interests,
      'bio': bio,
      'linkedInUrl': linkedInUrl,
      'githubUrl': githubUrl,
      'contactNumber': contactNumber,
      'currentCity': currentCity,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}
