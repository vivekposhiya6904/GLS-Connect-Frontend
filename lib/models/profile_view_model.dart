class ProfileViewModel {
  final int id;
  final String viewerEmail;
  final String viewerName;
  final String ownerEmail;
  final String timestamp;

  ProfileViewModel({
    required this.id,
    required this.viewerEmail,
    required this.viewerName,
    required this.ownerEmail,
    required this.timestamp,
  });

  factory ProfileViewModel.fromJson(Map<String, dynamic> json) {
    return ProfileViewModel(
      id: json['id'] ?? 0,
      viewerEmail: json['viewerEmail'] ?? '',
      viewerName: json['viewerName'] ?? '',
      ownerEmail: json['ownerEmail'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}
