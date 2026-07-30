class FacultyProfileModel {
  int? userId;
  String? userName;
  String? department;
  String? designation;
  String? qualification;
  String? specialization;
  int? experienceYears;
  String? email;
  String? contactNumber;
  String? researchInterests;
  String? bio;
  String? linkedInUrl;
  String? profilePictureUrl;

  // New fields matching the UI
  String? teachingExperience;
  String? industryExperience;
  String? publicationsCount;
  String? certifications;
  String? achievements;
  String? skills;
  String? studentsGuided;
  String? projectsSupervised;

  FacultyProfileModel({
    this.userId,
    this.userName,
    this.department,
    this.designation,
    this.qualification,
    this.specialization,
    this.experienceYears,
    this.email,
    this.contactNumber,
    this.researchInterests,
    this.bio,
    this.linkedInUrl,
    this.profilePictureUrl,
    this.teachingExperience,
    this.industryExperience,
    this.publicationsCount,
    this.certifications,
    this.achievements,
    this.skills,
    this.studentsGuided,
    this.projectsSupervised,
  });

  factory FacultyProfileModel.fromJson(Map<String, dynamic> json) {
    return FacultyProfileModel(
      userId: json['userId'],
      userName: json['userName'],
      department: json['department'],
      designation: json['designation'],
      qualification: json['qualification'],
      specialization: json['specialization'],
      experienceYears: json['experienceYears'],
      email: json['email'],
      contactNumber: json['contactNumber'],
      researchInterests: json['researchInterests'],
      bio: json['bio'],
      linkedInUrl: json['linkedInUrl'],
      profilePictureUrl: json['profilePictureUrl'],
      teachingExperience: json['teachingExperience'],
      industryExperience: json['industryExperience'],
      publicationsCount: json['publicationsCount'],
      certifications: json['certifications'],
      achievements: json['achievements'],
      skills: json['skills'],
      studentsGuided: json['studentsGuided'],
      projectsSupervised: json['projectsSupervised'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'department': department,
      'designation': designation,
      'qualification': qualification,
      'specialization': specialization,
      'experienceYears': experienceYears,
      'email': email,
      'contactNumber': contactNumber,
      'researchInterests': researchInterests,
      'bio': bio,
      'linkedInUrl': linkedInUrl,
      'profilePictureUrl': profilePictureUrl,
      'teachingExperience': teachingExperience,
      'industryExperience': industryExperience,
      'publicationsCount': publicationsCount,
      'certifications': certifications,
      'achievements': achievements,
      'skills': skills,
      'studentsGuided': studentsGuided,
      'projectsSupervised': projectsSupervised,
    };
  }
}
