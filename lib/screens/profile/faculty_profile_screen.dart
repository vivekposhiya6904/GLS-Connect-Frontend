import 'package:flutter/material.dart';
import '../../utils/storage_service.dart';
import '../auth/login_screen.dart';
import '../../models/faculty_profile_model.dart';
import '../../services/faculty_profile_service.dart';
import '../../utils/theme_manager.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/alumni_profile_service.dart';
import '../../config/api_config.dart';
import '../../models/profile_view_model.dart';
import '../../services/profile_view_service.dart';

class FacultyProfileScreen extends StatefulWidget {
  const FacultyProfileScreen({super.key});

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen> {
  bool isEditing = false;
  bool isLoading = true;
  String username = "";
  String? profilePictureUrl;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController qualificationController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();
  final TextEditingController teachingExperienceController = TextEditingController();
  final TextEditingController industryExperienceController = TextEditingController();
  final TextEditingController researchAreasController = TextEditingController();
  final TextEditingController publicationsCountController = TextEditingController();
  final TextEditingController certificationsController = TextEditingController();
  final TextEditingController achievementsController = TextEditingController();
  final TextEditingController biographyController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController studentsGuidedController = TextEditingController();
  final TextEditingController projectsSupervisedController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController linkedInController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  @override
  void dispose() {
    nameController.dispose();
    departmentController.dispose();
    designationController.dispose();
    experienceController.dispose();
    contactController.dispose();
    qualificationController.dispose();
    specializationController.dispose();
    teachingExperienceController.dispose();
    industryExperienceController.dispose();
    researchAreasController.dispose();
    publicationsCountController.dispose();
    certificationsController.dispose();
    achievementsController.dispose();
    biographyController.dispose();
    skillsController.dispose();
    studentsGuidedController.dispose();
    projectsSupervisedController.dispose();
    emailController.dispose();
    linkedInController.dispose();
    super.dispose();
  }

  Future<void> loadAllData() async {
    await loadUserName();
    await loadProfile();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadUserName() async {
    final name = await StorageService.getUserName();
    username = name ?? "";
    nameController.text = username;
  }

  Future<void> loadProfile() async {
    final profile = await FacultyProfileService.getProfile();

    if (profile != null) {
      setState(() {
        profilePictureUrl = profile.profilePictureUrl;
      });
      departmentController.text = profile.department ?? "";
      designationController.text = profile.designation ?? "";
      experienceController.text = profile.experienceYears?.toString() ?? "";
      contactController.text = profile.contactNumber ?? "";
      qualificationController.text = profile.qualification ?? "";
      specializationController.text = profile.specialization ?? "";
      teachingExperienceController.text = profile.teachingExperience ?? "";
      industryExperienceController.text = profile.industryExperience ?? "";
      researchAreasController.text = profile.researchInterests ?? "";
      publicationsCountController.text = profile.publicationsCount ?? "";
      certificationsController.text = profile.certifications ?? "";
      achievementsController.text = profile.achievements ?? "";
      biographyController.text = profile.bio ?? "";
      skillsController.text = profile.skills ?? "";
      studentsGuidedController.text = profile.studentsGuided ?? "";
      projectsSupervisedController.text = profile.projectsSupervised ?? "";
      emailController.text = profile.email ?? "";
      linkedInController.text = profile.linkedInUrl ?? "";
    }
  }

  Future<void> saveProfile() async {
    setState(() {
      isLoading = true;
    });

    final updatedProfile = FacultyProfileModel(
      department: departmentController.text,
      designation: designationController.text,
      qualification: qualificationController.text,
      specialization: specializationController.text,
      experienceYears: int.tryParse(experienceController.text),
      contactNumber: contactController.text,
      teachingExperience: teachingExperienceController.text,
      industryExperience: industryExperienceController.text,
      researchInterests: researchAreasController.text,
      publicationsCount: publicationsCountController.text,
      certifications: certificationsController.text,
      achievements: achievementsController.text,
      bio: biographyController.text,
      skills: skillsController.text,
      studentsGuided: studentsGuidedController.text,
      projectsSupervised: projectsSupervisedController.text,
      email: emailController.text,
      linkedInUrl: linkedInController.text,
      profilePictureUrl: profilePictureUrl,
    );

    // Backend PUT updates/creates the profile
    final success = await FacultyProfileService.updateProfile(updatedProfile, isCreate: false);

    if (mounted) {
      setState(() {
        isLoading = false;
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Profile Updated Successfully" : "Failed to update profile"),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        loadProfile();
      }
    }
  }

  // ================= LOGOUT FUNCTION =================
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
                            GestureDetector(
                              onTap: isEditing ? _pickAndUploadImage : null,
                              child: Stack(
                                children: [
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
                                    child: CircleAvatar(
                                      radius: 55,
                                      backgroundColor: Colors.white,
                                      backgroundImage: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                                          ? NetworkImage("${ApiConfig.baseUrl}$profilePictureUrl")
                                          : null,
                                      child: profilePictureUrl == null || profilePictureUrl!.isEmpty
                                          ? const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Color(0xFF1A3A8F),
                                            )
                                          : null,
                                    ),
                                  ),
                                  if (isEditing)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1A3A8F),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Name
                            Text(
                              username.isNotEmpty ? username : "Faculty Member",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Designation
                            Text(
                              designationController.text.isNotEmpty
                                  ? designationController.text
                                  : "Associate Professor",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Department
                            Text(
                              departmentController.text.isNotEmpty
                                  ? departmentController.text
                                  : "Computer Science",
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
                    // EDIT BUTTON
                    IconButton(
                      icon: Icon(isEditing ? Icons.close : Icons.edit, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          isEditing = !isEditing;
                          if (!isEditing) {
                            loadProfile(); // Reset fields if cancelled
                          }
                        });
                      },
                    ),
                    // LOGOUT BUTTON
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
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
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
                              publicationsCountController.text.isNotEmpty
                                  ? publicationsCountController.text
                                  : "0",
                              "Publications",
                              Icons.article_outlined,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                            _buildStatItem(
                              experienceController.text.isNotEmpty
                                  ? experienceController.text
                                  : "0",
                              "Experience (Yrs)",
                              Icons.work_outline,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                            _buildStatItem(
                              studentsGuidedController.text.isNotEmpty
                                  ? studentsGuidedController.text
                                  : "0",
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

                      // Contact Information Section
                      _buildProfileSection(
                        title: "Contact & Links",
                        icon: Icons.contact_mail_outlined,
                        content: Column(
                          children: [
                            _buildInfoRow("Email Address", emailController, Icons.email_outlined),
                            _buildInfoRow("Contact Number", contactController, Icons.phone_android),
                            _buildInfoRow("LinkedIn Profile URL", linkedInController, Icons.link),
                          ],
                        ),
                      ),

                      // Experience Section
                      _buildProfileSection(
                        title: "Experience details",
                        icon: Icons.work_history_outlined,
                        content: Column(
                          children: [
                            _buildInfoRow("Total Experience (Years)", experienceController, Icons.star_border),
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
                      _buildSettingsSection(),
                      const SizedBox(height: 16),
                      _buildProfileViewsSection(),
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
                            onPressed: saveProfile,
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
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
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

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.settings_outlined, color: Color(0xFF1A3A8F), size: 22),
              SizedBox(width: 10),
              Text(
                "App Settings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    ThemeManager().isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Dark Mode",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Switch(
                value: ThemeManager().isDarkMode,
                onChanged: (val) {
                  ThemeManager().toggleTheme(val);
                },
                activeColor: const Color(0xFF1A3A8F),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploading profile image...")),
      );
      final url = await AlumniProfileService.uploadProfileImage(picked);
      if (url != null) {
        setState(() {
          profilePictureUrl = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile image uploaded successfully. Please save profile to commit.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload profile image.")),
        );
      }
    }
  }

  Widget _buildProfileViewsSection() {
    return FutureBuilder<List<ProfileViewModel>>(
      future: ProfileViewService.getProfileViews(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final list = snapshot.data!;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_outlined, color: Color(0xFF1A3A8F), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    "Who Viewed My Profile (${list.length})",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length > 5 ? 5 : list.length,
                itemBuilder: (context, index) {
                  final view = list[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          view.viewerName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          view.timestamp.split('T').first,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}