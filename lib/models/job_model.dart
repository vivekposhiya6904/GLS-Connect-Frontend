class JobModel {
  final int? id;
  final int userId;
  final String userName;
  final String companyName;
  final String jobTitle;
  final String location;
  final String salary;
  final String jobDescription;
  final String skillsRequired;
  final String experienceRequired;
  final String joiningType;
  final String jobType;
  final String lastDateToApply;
  final String? photoUrl;

  JobModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.companyName,
    required this.jobTitle,
    required this.location,
    required this.salary,
    required this.jobDescription,
    required this.skillsRequired,
    required this.experienceRequired,
    required this.joiningType,
    required this.jobType,
    required this.lastDateToApply,
    this.photoUrl,
  });

  // Convert JSON → JobModel
  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'],
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? 'Unknown',
      companyName: json['companyName'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      location: json['location'] ?? '',
      salary: json['salary'] ?? '',
      jobDescription: json['jobDescription'] ?? '',
      skillsRequired: json['skillsRequired'] ?? '',
      experienceRequired: json['experienceRequired'] ?? '',
      joiningType: json['joiningType'] ?? '',
      jobType: json['jobType'] ?? '',
      lastDateToApply: json['lastDateToApply'] ?? '',
      photoUrl: json['photoUrl'],
    );
  }

  // Convert JobModel → JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "userName": userName,
      "companyName": companyName,
      "jobTitle": jobTitle,
      "location": location,
      "salary": salary,
      "jobDescription": jobDescription,
      "skillsRequired": skillsRequired,
      "experienceRequired": experienceRequired,
      "joiningType": joiningType,
      "jobType": jobType,
      "lastDateToApply": lastDateToApply,
      "photoUrl": photoUrl,
    };
  }
}

