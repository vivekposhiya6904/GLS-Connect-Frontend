import 'package:flutter/material.dart';
import '../../utils/storage_service.dart';
import '../auth/login_screen.dart';

class FacultyProfileScreen extends StatefulWidget {
  const FacultyProfileScreen({super.key});

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen> {
  bool isEditing = false;

  // Existing controllers (preserved)
  final TextEditingController nameController = TextEditingController(text: "Dr. Rajesh Mehta");
  final TextEditingController departmentController = TextEditingController(text: "Computer Science");
  final TextEditingController designationController = TextEditingController(text: "Associate Professor");
  final TextEditingController experienceController = TextEditingController(text: "12");
  final TextEditingController contactController = TextEditingController(text: "+91 9876543210");

  // New controllers for additional fields
  final TextEditingController qualificationController = TextEditingController(text: "Ph.D. in Computer Science");
  final TextEditingController specializationController = TextEditingController(text: "Machine Learning, AI");
  final TextEditingController teachingExperienceController = TextEditingController(text: "10 years");
  final TextEditingController industryExperienceController = TextEditingController(text: "2 years");
  final TextEditingController researchAreasController = TextEditingController(text: "Deep Learning, NLP, Computer Vision");
  final TextEditingController publicationsCountController = TextEditingController(text: "35");
  final TextEditingController certificationsController = TextEditingController(text: "AWS Certified, Google TensorFlow Developer");
  final TextEditingController achievementsController = TextEditingController(text: "Best Researcher Award 2023, Excellence in Teaching Award");
  final TextEditingController biographyController = TextEditingController(text: "Passionate educator and researcher with over a decade of experience in computer science education. Published 35+ research papers in top-tier journals and guided 20+ graduate students.");
  final TextEditingController skillsController = TextEditingController(text: "Python, Java, C++, Machine Learning, Data Science, Flutter");
  final TextEditingController studentsGuidedController = TextEditingController(text: "25");
  final TextEditingController projectsSupervisedController = TextEditingController(text: "40");

  // ================= LOGOUT FUNCTION (UNCHANGED) =================
  Future<void> logout() async {
    await StorageService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Premium Blue Profile Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1A3A8F),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A3A8F),
                      Color(0xFF2E4DB0),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Profile Photo
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 55,
                          backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=12"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Name
                      Text(
                        nameController.text,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Designation
                      Text(
                        designationController.text,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Department
                      Text(
                        departmentController.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // EDIT BUTTON (preserved functionality)
              IconButton(
                icon: Icon(isEditing ? Icons.check : Icons.edit, color: Colors.white),
                onPressed: () {
                  setState(() {
                    isEditing = !isEditing;
                  });
                },
              ),
              // LOGOUT BUTTON (preserved)
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70),
                onPressed: logout,
              ),
            ],
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Instagram-style Statistics Row
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        isEditing ? publicationsCountController.text : "35",
                        "Publications",
                        Icons.article_outlined,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      _buildStatItem(
                        isEditing ? experienceController.text : "12",
                        "Experience",
                        Icons.work_outline,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      _buildStatItem(
                        isEditing ? studentsGuidedController.text : "25",
                        "Students\nGuided",
                        Icons.people_outline,
                      ),
                    ],
                  ),
                ),

                // About Me Section
                _buildProfileSection(
                  title: "About Me",
                  icon: Icons.person_outline,
                  content: isEditing
                      ? _buildEditableField(biographyController, "Tell us about yourself", maxLines: 4)
                      : _buildDisplayText(biographyController.text),
                ),

                // Academic Information Section
                _buildProfileSection(
                  title: "Academic Information",
                  icon: Icons.school_outlined,
                  content: Column(
                    children: [
                      _buildInfoRow("Qualification", qualificationController, Icons.workspace_premium),
                      _buildInfoRow("Specialization", specializationController, Icons.science),
                      _buildInfoRow("Research Areas", researchAreasController, Icons.biotech),
                    ],
                  ),
                ),

                // Education Section
                _buildProfileSection(
                  title: "Education",
                  icon: Icons.menu_book_outlined,
                  content: _buildInfoRow("Highest Qualification", qualificationController, Icons.school),
                ),

                // Experience Section
                _buildProfileSection(
                  title: "Experience",
                  icon: Icons.work_history_outlined,
                  content: Column(
                    children: [
                      _buildInfoRow("Teaching Experience", teachingExperienceController, Icons.cast_for_education),
                      _buildInfoRow("Industry Experience", industryExperienceController, Icons.business_center),
                    ],
                  ),
                ),

                // Research & Publications
                _buildProfileSection(
                  title: "Research & Publications",
                  icon: Icons.analytics_outlined,
                  content: Column(
                    children: [
                      _buildInfoRow("Publications Count", publicationsCountController, Icons.description),
                      _buildInfoRow("Projects Supervised", projectsSupervisedController, Icons.assignment),
                    ],
                  ),
                ),

                // Skills Section
                _buildProfileSection(
                  title: "Skills",
                  icon: Icons.code_outlined,
                  content: _buildInfoRow("Technical Skills", skillsController, Icons.computer),
                ),

                // Certifications Section
                _buildProfileSection(
                  title: "Certifications",
                  icon: Icons.verified_outlined,
                  content: _buildInfoRow("Professional Certifications", certificationsController, Icons.assignment_turned_in),
                ),

                // Achievements Section
                _buildProfileSection(
                  title: "Achievements & Awards",
                  icon: Icons.emoji_events_outlined,
                  content: _buildInfoRow("Recognitions", achievementsController, Icons.star),
                ),

                const SizedBox(height: 16),

                // Premium Blue Edit Profile Button (when not editing)
                if (!isEditing)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3A8F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Edit Profile",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                // Save Changes Button when editing
                if (isEditing)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3A8F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                // Logout Button at Bottom
                if (!isEditing)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 32),
                    child: OutlinedButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.redAccent, fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1A3A8F), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1A3A8F), size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1A3A8F), size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          isEditing
              ? _buildEditableField(controller, "Enter $label")
              : _buildDisplayText(controller.text),
        ],
      ),
    );
  }

  Widget _buildEditableField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A3A8F), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDisplayText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        text.isNotEmpty ? text : "Not specified",
        style: TextStyle(
          fontSize: 14,
          color: text.isNotEmpty ? Colors.black87 : Colors.grey,
        ),
      ),
    );
  }
}