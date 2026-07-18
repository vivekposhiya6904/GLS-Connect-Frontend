import 'package:flutter/material.dart';
import '../../models/alumni_profile_model.dart';
import '../../models/faculty_profile_model.dart';
import '../../services/alumni_profile_service.dart';
import '../../services/faculty_profile_service.dart';

class ProfileDetailScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userRole; // ALUMNI or FACULTY

  const ProfileDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool _isLoading = true;
  AlumniProfileModel? _alumniProfile;
  FacultyProfileModel? _facultyProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.userRole == 'ALUMNI') {
      final profile = await AlumniProfileService.getProfileByUserId(widget.userId);
      setState(() {
        _alumniProfile = profile;
        _isLoading = false;
      });
    } else if (widget.userRole == 'FACULTY') {
      final profile = await FacultyProfileService.getProfileByUserId(widget.userId);
      setState(() {
        _facultyProfile = profile;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  backgroundColor: const Color(0xFF1A3A8F),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1A3A8F), Color(0xFF152E7A)],
                        ),
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: Text(
                            widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A8F),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: widget.userRole == 'ALUMNI'
                        ? _buildAlumniDetails()
                        : widget.userRole == 'FACULTY'
                            ? _buildFacultyDetails()
                            : _buildFallbackDetails(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAlumniDetails() {
    if (_alumniProfile == null) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("No details provided yet."),
      ));
    }
    final p = _alumniProfile!;
    return Column(
      children: [
        _buildSectionCard("Academic Information", Icons.school_outlined, [
          _buildDetailRow("Degree", p.degree),
          _buildDetailRow("Department", p.department),
          _buildDetailRow("Batch Year", p.batchYear?.toString()),
        ]),
        const SizedBox(height: 16),
        _buildSectionCard("Professional Information", Icons.work_outline, [
          _buildDetailRow("Designation", p.designation),
          _buildDetailRow("Company", p.companyName),
          _buildDetailRow("Industry", p.industry),
          _buildDetailRow("Experience", p.workExperience != null ? "${p.workExperience} years" : null),
          _buildDetailRow("Skills", p.skills),
        ]),
        const SizedBox(height: 16),
        _buildSectionCard("Contact & Socials", Icons.alternate_email, [
          _buildDetailRow("Contact Number", p.contactNumber),
          _buildDetailRow("Current City", p.currentCity),
          _buildDetailRow("LinkedIn", p.linkedInUrl, isLink: true),
          _buildDetailRow("GitHub", p.githubUrl, isLink: true),
        ]),
      ],
    );
  }

  Widget _buildFacultyDetails() {
    if (_facultyProfile == null) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("No details provided yet."),
      ));
    }
    final p = _facultyProfile!;
    return Column(
      children: [
        _buildSectionCard("Academic Information", Icons.school_outlined, [
          _buildDetailRow("Department", p.department),
          _buildDetailRow("Designation", p.designation),
          _buildDetailRow("Qualification", p.qualification),
          _buildDetailRow("Specialization", p.specialization),
          _buildDetailRow("Teaching Experience", p.teachingExperience),
          _buildDetailRow("Research Interests", p.researchInterests),
        ]),
        const SizedBox(height: 16),
        _buildSectionCard("Professional Profile", Icons.psychology_outlined, [
          _buildDetailRow("Industry Experience", p.industryExperience),
          _buildDetailRow("Total Experience", p.experienceYears != null ? "${p.experienceYears} years" : null),
          _buildDetailRow("Skills", p.skills),
          _buildDetailRow("Publications", p.publicationsCount),
          _buildDetailRow("Projects Supervised", p.projectsSupervised),
          _buildDetailRow("Students Guided", p.studentsGuided),
        ]),
        const SizedBox(height: 16),
        _buildSectionCard("Biography & Achievements", Icons.emoji_events_outlined, [
          _buildDetailRow("Bio", p.bio),
          _buildDetailRow("Certifications", p.certifications),
          _buildDetailRow("Achievements", p.achievements),
        ]),
        const SizedBox(height: 16),
        _buildSectionCard("Contact & Links", Icons.contact_mail_outlined, [
          _buildDetailRow("Email Address", p.email),
          _buildDetailRow("Contact Number", p.contactNumber),
          _buildDetailRow("LinkedIn", p.linkedInUrl, isLink: true),
        ]),
      ],
    );
  }

  Widget _buildFallbackDetails() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text("Profile details for ${widget.userRole} is not supported."),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> rows) {
    // Filter out rows that evaluate to empty / null (represented by SizedBox.shrink)
    final visibleRows = rows.where((w) => w is! SizedBox).toList();
    if (visibleRows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1A3A8F), size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A8F),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleRows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) => visibleRows[index],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {bool isLink = false}) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isLink ? const Color(0xFF1A3A8F) : Colors.black87,
            decoration: isLink ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
