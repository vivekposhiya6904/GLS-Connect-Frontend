import 'package:flutter/material.dart';
import '../../services/student_profile_service.dart';
import '../../models/student_profile_model.dart';
import '../../utils/storage_service.dart';
import '../auth/login_screen.dart';
import '../../utils/image_picker_helper.dart';
import '../../config/api_config.dart';
import '../../widgets/offline_indicator.dart';
import '../../utils/academic_options.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool isEditing = false;
  bool isLoading = true;
  bool _isOffline = false;
  bool _isFromCache = false;
  String? _cacheTimeAgo;
  StudentProfileModel? _savedProfile;

  String username = "";
  String email = "";
  String universityNumber = "";
  String? profilePictureUrl;

  final departmentController = TextEditingController();
  final degreeController = TextEditingController();
  final batchController = TextEditingController();
  final customDegreeController = TextEditingController();
  final customDepartmentController = TextEditingController();
  String? selectedDegreeDropdown;
  String? selectedDepartmentDropdown;

  final semesterController = TextEditingController();
  final skillsController = TextEditingController();
  final interestsController = TextEditingController();
  final bioController = TextEditingController();
  final contactController = TextEditingController();
  final cityController = TextEditingController();
  final linkedInController = TextEditingController();
  final githubController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  @override
  void dispose() {
    departmentController.dispose();
    degreeController.dispose();
    batchController.dispose();
    customDegreeController.dispose();
    customDepartmentController.dispose();
    semesterController.dispose();
    skillsController.dispose();
    interestsController.dispose();
    bioController.dispose();
    contactController.dispose();
    cityController.dispose();
    linkedInController.dispose();
    githubController.dispose();
    super.dispose();
  }

  void _applyProfileData(StudentProfileModel profile) {
    _savedProfile = profile;
    if (profile.userName != null && profile.userName!.isNotEmpty) {
      username = profile.userName!;
    }
    if (profile.email != null && profile.email!.isNotEmpty) {
      email = profile.email!;
    }
    if (profile.universityNumber != null) {
      universityNumber = profile.universityNumber!;
    }

    profilePictureUrl = profile.profilePictureUrl;

    final savedDegree = profile.degree?.trim() ?? "";
    if (savedDegree.isNotEmpty) {
      if (AcademicOptions.isPredefinedDegree(savedDegree)) {
        selectedDegreeDropdown = savedDegree;
        customDegreeController.text = "";
        degreeController.text = savedDegree;
      } else {
        selectedDegreeDropdown = AcademicOptions.otherOption;
        customDegreeController.text = savedDegree;
        degreeController.text = savedDegree;
      }
    } else {
      selectedDegreeDropdown = null;
      customDegreeController.text = "";
      degreeController.text = "";
    }

    final savedDept = profile.department?.trim() ?? "";
    if (savedDept.isNotEmpty) {
      final degreeContext = (selectedDegreeDropdown != null &&
              selectedDegreeDropdown != AcademicOptions.otherOption)
          ? selectedDegreeDropdown
          : null;
      if (AcademicOptions.isPredefinedDepartment(degreeContext, savedDept)) {
        selectedDepartmentDropdown = savedDept;
        customDepartmentController.text = "";
        departmentController.text = savedDept;
      } else {
        selectedDepartmentDropdown = AcademicOptions.otherOption;
        customDepartmentController.text = savedDept;
        departmentController.text = savedDept;
      }
    } else {
      selectedDepartmentDropdown = null;
      customDepartmentController.text = "";
      departmentController.text = "";
    }

    batchController.text = profile.batchYear != null ? profile.batchYear.toString() : "";
    semesterController.text = profile.semester ?? "Semester 4";
    skillsController.text = profile.skills ?? "";
    interestsController.text = profile.interests ?? "";
    bioController.text = profile.bio ?? "";
    contactController.text = profile.contactNumber ?? "";
    cityController.text = profile.currentCity ?? "";
    linkedInController.text = profile.linkedInUrl ?? "";
    githubController.text = profile.githubUrl ?? "";
  }

  void _cancelEditing() {
    if (_savedProfile != null) {
      _applyProfileData(_savedProfile!);
    }
    setState(() {
      isEditing = false;
    });
  }

  Future<void> loadAllData() async {
    final name = await StorageService.getUserName();
    final userEmail = await StorageService.getUserEmail();
    username = name ?? "Student";
    email = userEmail ?? "";

    // 1. Try local encrypted cache first
    StudentProfileModel? profileData;
    try {
      final cached = await StudentProfileService.getCachedProfile();
      if (cached != null) {
        profileData = cached.data;
        _isFromCache = true;
        _cacheTimeAgo = cached.timeAgoFormatted;
      }
    } catch (_) {}

    if (profileData != null) {
      _applyProfileData(profileData);
      isLoading = false;
      if (mounted) setState(() {});
    }

    // 2. Fetch fresh profile from network
    try {
      final profile = await StudentProfileService.getProfile();
      if (profile != null) {
        _applyProfileData(profile);
        _isFromCache = false;
        _isOffline = false;
        _cacheTimeAgo = null;
      } else if (_isFromCache) {
        _isOffline = true;
      }
    } catch (_) {
      if (_isFromCache) {
        _isOffline = true;
      }
    } finally {
      isLoading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> handlePickImage() async {
    final image = await ImagePickerHelper.pickImageWithSourceDialog(context);
    if (image == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Uploading profile picture...")),
    );

    final uploadedUrl = await StudentProfileService.uploadProfileImage(image);

    if (uploadedUrl != null && mounted) {
      setState(() {
        profilePictureUrl = uploadedUrl;
      });

      // Auto-save picture URL to profile
      final updatedProfile = StudentProfileModel(
        department: departmentController.text.trim(),
        degree: degreeController.text.trim(),
        batchYear: int.tryParse(batchController.text.trim()),
        semester: semesterController.text.trim(),
        skills: skillsController.text.trim(),
        interests: interestsController.text.trim(),
        bio: bioController.text.trim(),
        contactNumber: contactController.text.trim(),
        currentCity: cityController.text.trim(),
        linkedInUrl: linkedInController.text.trim(),
        githubUrl: githubController.text.trim(),
        profilePictureUrl: uploadedUrl,
      );
      await StudentProfileService.saveProfile(updatedProfile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated successfully!")),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload image. Please try again.")),
      );
    }
  }

  Future<void> saveProfile() async {
    final batchInt = int.tryParse(batchController.text.trim());

    String finalDegree = "";
    if (selectedDegreeDropdown == AcademicOptions.otherOption) {
      finalDegree = customDegreeController.text.trim();
      if (finalDegree.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter your custom degree name."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (finalDegree.toLowerCase() == "other") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter a specific degree name, not 'Other'."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (finalDegree.length > 100) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Degree name must be 100 characters or less."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else if (selectedDegreeDropdown != null && selectedDegreeDropdown!.isNotEmpty) {
      finalDegree = selectedDegreeDropdown!;
    } else {
      finalDegree = degreeController.text.trim();
    }

    String finalDept = "";
    if (selectedDepartmentDropdown == AcademicOptions.otherOption) {
      finalDept = customDepartmentController.text.trim();
      if (finalDept.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter your custom department name."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (finalDept.toLowerCase() == "other") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter a specific department name, not 'Other'."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (finalDept.length > 100) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Department name must be 100 characters or less."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else if (selectedDepartmentDropdown != null && selectedDepartmentDropdown!.isNotEmpty) {
      finalDept = selectedDepartmentDropdown!;
    } else {
      finalDept = departmentController.text.trim();
    }

    if (batchInt == null || finalDegree.isEmpty || finalDept.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select or enter a valid Batch Year, Degree, and Department."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => isLoading = true);

    degreeController.text = finalDegree;
    departmentController.text = finalDept;

    final profile = StudentProfileModel(
      department: finalDept,
      degree: finalDegree,
      batchYear: batchInt,
      semester: semesterController.text.trim(),
      skills: skillsController.text.trim(),
      interests: interestsController.text.trim(),
      bio: bioController.text.trim(),
      contactNumber: contactController.text.trim(),
      currentCity: cityController.text.trim(),
      linkedInUrl: linkedInController.text.trim(),
      githubUrl: githubController.text.trim(),
      profilePictureUrl: profilePictureUrl,
    );

    final success = await StudentProfileService.saveProfile(profile);

    if (!mounted) return;
    setState(() {
      isLoading = false;
      if (success) {
        _savedProfile = profile;
        isEditing = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? "Profile saved successfully!" : "Failed to save profile."),
        backgroundColor: success ? const Color(0xFF15803D) : Colors.red,
      ),
    );
  }

  void logout() async {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B40);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7FF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1A3A8F),
        elevation: 0,
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close_rounded : Icons.edit_rounded, color: Colors.white),
            tooltip: isEditing ? "Cancel" : "Edit Profile",
            onPressed: () {
              if (isEditing) {
                _cancelEditing();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: "Logout",
            onPressed: logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadAllData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    if (_isOffline && _isFromCache)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OfflineIndicatorBanner(
                          timeAgo: _cacheTimeAgo,
                          onRetry: loadAllData,
                        ),
                      ),
                    // Avatar & Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: const Color(0xFF1A3A8F).withValues(alpha: 0.15),
                                backgroundImage: (profilePictureUrl != null &&
                                        profilePictureUrl!.isNotEmpty)
                                    ? NetworkImage(
                                        profilePictureUrl!.startsWith('http')
                                            ? profilePictureUrl!
                                            : "${ApiConfig.baseUrl}$profilePictureUrl",
                                      )
                                    : null,
                                child: (profilePictureUrl == null || profilePictureUrl!.isEmpty)
                                    ? const Icon(Icons.person, size: 50, color: Color(0xFF1A3A8F))
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: handlePickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1A3A8F),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            username.isNotEmpty ? username : "Student User",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade700),
                            ),
                            child: Text(
                              "STUDENT",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.amber[300] : Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Academic Details Section
                    _buildSectionCard(
                      title: "Academic Information",
                      icon: Icons.school_rounded,
                      cardBg: cardBg,
                      isDark: isDark,
                      children: [
                        _buildDegreeDropdown(isDark: isDark),
                        _buildDepartmentDropdown(isDark: isDark),
                        _buildBatchYearDropdown(isDark: isDark),
                        _buildField(
                          label: "Current Semester",
                          controller: semesterController,
                          hint: "e.g. Semester 4",
                          isEditing: isEditing,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Skills & Interests Section
                    _buildSectionCard(
                      title: "Skills & Interests",
                      icon: Icons.psychology_rounded,
                      cardBg: cardBg,
                      isDark: isDark,
                      children: [
                        _buildField(
                          label: "Technical Skills",
                          controller: skillsController,
                          hint: "e.g. Flutter, Dart, Java, Spring Boot, SQL",
                          isEditing: isEditing,
                          isDark: isDark,
                        ),
                        _buildField(
                          label: "Areas of Interest",
                          controller: interestsController,
                          hint: "e.g. Mobile Development, Cloud, AI/ML",
                          isEditing: isEditing,
                          isDark: isDark,
                        ),
                        _buildField(
                          label: "Bio / About Me",
                          controller: bioController,
                          hint: "Tell mentors and alumni about yourself...",
                          maxLines: 3,
                          isEditing: isEditing,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contact & Links Section
                    _buildSectionCard(
                      title: "Contact & Profiles",
                      icon: Icons.link_rounded,
                      cardBg: cardBg,
                      isDark: isDark,
                      children: [
                        _buildField(
                          label: "Contact Phone",
                          controller: contactController,
                          hint: "e.g. +91 98765 43210",
                          keyboardType: TextInputType.phone,
                          isEditing: isEditing,
                          isDark: isDark,
                        ),
                        _buildField(
                          label: "Current City",
                          controller: cityController,
                          hint: "e.g. Ahmedabad, Gujarat",
                          isEditing: isEditing,
                          isDark: isDark,
                        ),
                        _buildField(
                          label: "LinkedIn Profile",
                          controller: linkedInController,
                          hint: "e.g. linkedin.com/in/username",
                          isEditing: isEditing,
                          isDark: isDark,
                        ),
                        _buildField(
                          label: "GitHub Profile",
                          controller: githubController,
                          hint: "e.g. github.com/username",
                          isEditing: isEditing,
                          isDark: isDark,
                        ),
                      ],
                    ),

                    if (isEditing) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: _cancelEditing,
                                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                                label: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: saveProfile,
                                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                                label: const Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A3A8F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color cardBg,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1A3A8F)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0D1B40),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isEditing,
    required bool isDark,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 5),
          if (isEditing)
            TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : const Color(0xFFD8E3F8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1A3A8F), width: 1.5),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                controller.text.trim().isNotEmpty ? controller.text.trim() : "Not specified",
                style: TextStyle(
                  fontSize: 14,
                  color: controller.text.trim().isNotEmpty
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : Colors.grey,
                  fontStyle:
                      controller.text.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDegreeDropdown({required bool isDark}) {
    final degrees = AcademicOptions.getDegrees();
    final isOtherSelected = selectedDegreeDropdown == AcademicOptions.otherOption;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Degree / Course",
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 5),
          if (isEditing) ...[
            DropdownButtonFormField<String>(
              key: const Key('student_degree_dropdown'),
              value: (selectedDegreeDropdown != null && degrees.contains(selectedDegreeDropdown))
                  ? selectedDegreeDropdown
                  : null,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF262626) : Colors.white,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: "Select Degree",
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : const Color(0xFFD8E3F8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1A3A8F), width: 1.5),
                ),
              ),
              items: degrees.map((d) {
                return DropdownMenuItem<String>(
                  value: d,
                  child: Text(d),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedDegreeDropdown = val;
                    if (val == AcademicOptions.otherOption) {
                      degreeController.text = customDegreeController.text.trim();
                    } else {
                      degreeController.text = val;
                    }

                    // Preserve department if still valid for newly selected degree, otherwise reset safely
                    final validDepts = AcademicOptions.getDepartmentsForDegree(
                      degree: val == AcademicOptions.otherOption ? null : val,
                    );
                    if (selectedDepartmentDropdown != null &&
                        selectedDepartmentDropdown != AcademicOptions.otherOption &&
                        !validDepts.contains(selectedDepartmentDropdown)) {
                      selectedDepartmentDropdown = null;
                      departmentController.text = "";
                    }
                  });
                }
              },
            ),
            if (isOtherSelected) ...[
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('student_custom_degree_field'),
                controller: customDegreeController,
                maxLength: 100,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: "Enter Degree Name",
                  hintText: "e.g. B.Arch, M.Phil, Ph.D",
                  counterText: "",
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                  ),
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade700 : const Color(0xFFD8E3F8),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1A3A8F), width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  degreeController.text = val.trim();
                },
              ),
            ],
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                degreeController.text.trim().isNotEmpty ? degreeController.text.trim() : "Not specified",
                style: TextStyle(
                  fontSize: 14,
                  color: degreeController.text.trim().isNotEmpty
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : Colors.grey,
                  fontStyle: degreeController.text.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDropdown({required bool isDark}) {
    final depts = AcademicOptions.getDepartmentsForDegree(
      degree: (selectedDegreeDropdown != null && selectedDegreeDropdown != AcademicOptions.otherOption)
          ? selectedDegreeDropdown
          : null,
    );
    final isOtherSelected = selectedDepartmentDropdown == AcademicOptions.otherOption;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Department",
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 5),
          if (isEditing) ...[
            DropdownButtonFormField<String>(
              key: const Key('student_department_dropdown'),
              value: (selectedDepartmentDropdown != null && depts.contains(selectedDepartmentDropdown))
                  ? selectedDepartmentDropdown
                  : null,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF262626) : Colors.white,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: "Select Department",
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : const Color(0xFFD8E3F8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1A3A8F), width: 1.5),
                ),
              ),
              items: depts.map((d) {
                return DropdownMenuItem<String>(
                  value: d,
                  child: Text(d),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedDepartmentDropdown = val;
                    if (val == AcademicOptions.otherOption) {
                      departmentController.text = customDepartmentController.text.trim();
                    } else {
                      departmentController.text = val;
                    }
                  });
                }
              },
            ),
            if (isOtherSelected) ...[
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('student_custom_department_field'),
                controller: customDepartmentController,
                maxLength: 100,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: "Enter Department Name",
                  hintText: "e.g. Artificial Intelligence, Data Science",
                  counterText: "",
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                  ),
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade700 : const Color(0xFFD8E3F8),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1A3A8F), width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  departmentController.text = val.trim();
                },
              ),
            ],
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                departmentController.text.trim().isNotEmpty ? departmentController.text.trim() : "Not specified",
                style: TextStyle(
                  fontSize: 14,
                  color: departmentController.text.trim().isNotEmpty
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : Colors.grey,
                  fontStyle: departmentController.text.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBatchYearDropdown({required bool isDark}) {
    final currentVal = int.tryParse(batchController.text.trim());
    final years = AcademicOptions.getBatchYears(customYear: currentVal);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Graduation / Batch Year",
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 5),
          if (isEditing)
            DropdownButtonFormField<int>(
              key: const Key('student_batch_year_dropdown'),
              value: (currentVal != null && years.contains(currentVal)) ? currentVal : null,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF262626) : Colors.white,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: "Select Batch Year",
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : const Color(0xFFD8E3F8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1A3A8F), width: 1.5),
                ),
              ),
              items: years.map((y) {
                return DropdownMenuItem<int>(
                  value: y,
                  child: Text(y.toString()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    batchController.text = val.toString();
                  });
                }
              },
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                currentVal != null ? currentVal.toString() : "Not specified",
                style: TextStyle(
                  fontSize: 14,
                  color: currentVal != null
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : Colors.grey,
                  fontStyle: currentVal == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
