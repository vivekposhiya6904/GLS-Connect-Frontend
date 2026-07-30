class AlumniProfileModel {
  final int? userId;
  final String? userName;
  final int? batchYear;
  final String? degree;
  final String? department;
  final String? designation;
  final String? companyName;
  final String? industry;
  final String? skills;
  final double? workExperience;
  final String? linkedInUrl;
  final String? githubUrl;
  final String? contactNumber;
  final String? currentCity;
  final String? profilePictureUrl;
  final String? email;

  AlumniProfileModel({
    this.userId,
    this.userName,
    this.batchYear,
    this.degree,
    this.department,
    this.designation,
    this.companyName,
    this.industry,
    this.skills,
    this.workExperience,
    this.linkedInUrl,
    this.githubUrl,
    this.contactNumber,
    this.currentCity,
    this.profilePictureUrl,
    this.email,
  });

  factory AlumniProfileModel.fromJson(Map<String, dynamic> json) {
    return AlumniProfileModel(
      userId: json['userId'],
      userName: json['userName'],
      batchYear: json['batchYear'],
      degree: json['degree'],
      department: json['department'],
      designation: json['designation'],
      companyName: json['companyName'],
      industry: json['industry'],
      skills: json['skills'],
      workExperience: json['workExperience']?.toDouble(),
      linkedInUrl: json['linkedInUrl'],
      githubUrl: json['githubUrl'],
      contactNumber: json['contactNumber'],
      currentCity: json['currentCity'],
      profilePictureUrl: json['profilePictureUrl'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "userName": userName,
      "batchYear": batchYear,
      "degree": degree,
      "department": department,
      "designation": designation,
      "companyName": companyName,
      "industry": industry,
      "skills": skills,
      "workExperience": workExperience,
      "linkedInUrl": linkedInUrl,
      "githubUrl": githubUrl,
      "contactNumber": contactNumber,
      "currentCity": currentCity,
      "profilePictureUrl": profilePictureUrl,
      "email": email,
    };
  }
}