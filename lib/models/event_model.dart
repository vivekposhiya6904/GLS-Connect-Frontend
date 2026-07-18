class EventModel {
  final int? id;
  final String title;
  final String description;
  final String location;
  final String eventDate; // yyyy-MM-dd
  final String? status;
  final String? createdAt;
  final String? imageUrl;
  final String? createdByName;
  final String? createdByEmail;
  final String? targetDepartment;
  final String? note;

  EventModel({
    this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    this.status,
    this.createdAt,
    this.imageUrl,
    this.createdByName,
    this.createdByEmail,
    this.targetDepartment,
    this.note,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      eventDate: json['eventDate'] ?? '',
      status: json['status'],
      createdAt: json['createdAt'],
      imageUrl: json['imageUrl'],
      createdByName: json['createdBy'] != null ? json['createdBy']['name'] : null,
      createdByEmail: json['createdBy'] != null ? json['createdBy']['email'] : null,
      targetDepartment: json['targetDepartment'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'eventDate': eventDate,
      'status': status,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
      'targetDepartment': targetDepartment,
      'note': note,
    };
  }
}
