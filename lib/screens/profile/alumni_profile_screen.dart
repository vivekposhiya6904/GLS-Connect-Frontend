import 'package:flutter/material.dart';
import '../../services/alumni_profile_service.dart';
import '../../models/alumni_profile_model.dart';
import '../../utils/storage_service.dart';
import '../auth/login_screen.dart';
import '../../utils/image_picker_helper.dart';
import '../../models/profile_view_model.dart';
import '../../services/profile_view_service.dart';
import '../../config/api_config.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/offline_indicator.dart';
import '../../utils/academic_options.dart';

class AlumniProfileScreen extends StatefulWidget {
  const AlumniProfileScreen({super.key});

  @override
  State<AlumniProfileScreen> createState() => _AlumniProfileScreenState();
}

class _AlumniProfileScreenState extends State<AlumniProfileScreen> {
  bool isEditing = false;
  bool isLoading = true;
  bool _isOffline = false;
  bool _isFromCache = false;
  String? _cacheTimeAgo;
  AlumniProfileModel? _savedProfile;

  String username = "";
  String? profilePictureUrl;
  Future<List<ProfileViewModel>>? _profileViewsFuture;

  final batchController = TextEditingController();
  final degreeController = TextEditingController();
  final departmentController = TextEditingController();
  final customDegreeController = TextEditingController();
  final customDepartmentController = TextEditingController();
  String? selectedDegreeDropdown;
  String? selectedDepartmentDropdown;

  final designationController = TextEditingController();
  final companyController = TextEditingController();
  final industryController = TextEditingController();
  final skillsController = TextEditingController();
  final expController = TextEditingController();
  final linkedInController = TextEditingController();
  final githubController = TextEditingController();
  final contactController = TextEditingController();
  final cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profileViewsFuture = ProfileViewService.getProfileViews();
    loadAllData();
  }

  @override
  void dispose() {
    batchController.dispose();
    degreeController.dispose();
    departmentController.dispose();
    customDegreeController.dispose();
    customDepartmentController.dispose();
    designationController.dispose();
    companyController.dispose();
    industryController.dispose();
    skillsController.dispose();
    expController.dispose();
    linkedInController.dispose();
    githubController.dispose();
    contactController.dispose();
    cityController.dispose();
    super.dispose();
  }

  void _applyProfileData(AlumniProfileModel profile) {
    _savedProfile = profile;
    profilePictureUrl = profile.profilePictureUrl;
    batchController.text = profile.batchYear?.toString() ?? "";

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

    designationController.text = profile.designation ?? "";
    companyController.text = profile.companyName ?? "";
    industryController.text = profile.industry ?? "";
    skillsController.text = profile.skills ?? "";
    expController.text = profile.workExperience?.toString() ?? "";
    linkedInController.text = profile.linkedInUrl ?? "";
    githubController.text = profile.githubUrl ?? "";
    contactController.text = profile.contactNumber ?? "";
    cityController.text = profile.currentCity ?? "";
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
    username = name ?? "";

    // 1. Check local encrypted cache first
    AlumniProfileModel? profileData;
    try {
      final cached = await AlumniProfileService.getCachedProfile();
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

    // 2. Fetch fresh from network
    try {
      final profile = await AlumniProfileService.getProfile();
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

  Future<void> loadUserName() async {
    final name = await StorageService.getUserName();
    username = name ?? "";
  }

  Future<void> loadProfile() async {
    await loadAllData();
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

    degreeController.text = finalDegree;
    departmentController.text = finalDept;

    final updatedProfile = AlumniProfileModel(
      batchYear: batchInt,
      degree: finalDegree,
      department: finalDept,
      designation: designationController.text,
      companyName: companyController.text,
      industry: industryController.text,
      skills: skillsController.text,
      workExperience: double.tryParse(expController.text),
      linkedInUrl: linkedInController.text,
      githubUrl: githubController.text,
      contactNumber: contactController.text,
      currentCity: cityController.text,
      profilePictureUrl: profilePictureUrl,
    );

    final success = await AlumniProfileService.updateProfile(updatedProfile);

    if (success) {
      _savedProfile = updatedProfile;
      setState(() {
        isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated Successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update profile. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1A3A8F),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (isLoading)
                  const LinearProgressIndicator(color: Color(0xFF1A3A8F)),
                if (_isOffline && _isFromCache)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: OfflineIndicatorBanner(
                      timeAgo: _cacheTimeAgo,
                      onRetry: loadAllData,
                    ),
                  ),
                _buildStatsRow(),
                const SizedBox(height: 20),
                _buildAcademicSection(),
                const SizedBox(height: 16),
                _buildProfessionalSection(),
                const SizedBox(height: 16),
                _buildContactSection(),
                const SizedBox(height: 16),
                _buildProfileViewsSection(),
                const SizedBox(height: 24),
                _buildEditProfileButton(),
                if (!isEditing) ...[
                  const SizedBox(height: 12),
                  _buildLogoutButton(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3A8F), Color(0xFF152E7A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ProfileAvatar(
                      imageUrl: profilePictureUrl,
                      name: username,
                      radius: 60,
                      enableCacheBust: true,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A3A8F),
                      fallbackIcon: Icons.person_outline_rounded,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A3A8F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              username.isEmpty ? "Alumni Member" : username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            if (designationController.text.isNotEmpty ||
                companyController.text.isNotEmpty)
              Text(
                [designationController.text, companyController.text]
                    .where((t) => t.isNotEmpty)
                    .join(' at '),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final batchYear = int.tryParse(batchController.text);
    final workExp = double.tryParse(expController.text);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            value: batchYear?.toString() ?? "—",
            label: "Batch Year",
            icon: Icons.school_outlined,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[200],
          ),
          _buildStatItem(
            value: workExp != null ? "${workExp.toStringAsFixed(1)} yrs" : "—",
            label: "Experience",
            icon: Icons.work_outline,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[200],
          ),
          _buildStatItem(
            value: degreeController.text.isNotEmpty
                ? degreeController.text.split(' ').first
                : "—",
            label: "Degree",
            icon: Icons.verified_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      {required String value, required String label, required IconData icon}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF1A3A8F)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicSection() {
    return _buildInfoCard(
      title: "Academic Information",
      icon: Icons.school_outlined,
      children: [
        _buildInfoRow("Batch Year", batchController.text),
        const SizedBox(height: 12),
        _buildInfoRow("Degree", degreeController.text),
        const SizedBox(height: 12),
        _buildInfoRow("Department", departmentController.text),
      ],
    );
  }

  Widget _buildProfessionalSection() {
    return _buildInfoCard(
      title: "Professional Information",
      icon: Icons.work_outlined,
      children: [
        _buildInfoRow("Designation", designationController.text),
        const SizedBox(height: 12),
        _buildInfoRow("Company", companyController.text),
        const SizedBox(height: 12),
        _buildInfoRow("Industry", industryController.text),
        const SizedBox(height: 12),
        _buildInfoRow("Skills", skillsController.text, isMultiline: true),
        const SizedBox(height: 12),
        _buildInfoRow("Experience", "${expController.text} years"),
      ],
    );
  }

  Widget _buildContactSection() {
    return _buildInfoCard(
      title: "Contact & Links",
      icon: Icons.link_outlined,
      children: [
        _buildLinkRow(Icons.link, "LinkedIn", linkedInController.text),
        const SizedBox(height: 12),
        _buildLinkRow(Icons.code, "GitHub", githubController.text),
        const SizedBox(height: 12),
        _buildInfoRow("Contact Number", contactController.text),
        const SizedBox(height: 12),
        _buildInfoRow("Current City", cityController.text),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF1A3A8F)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiline = false}) {
    if (isEditing) {
      return _buildEditableField(label, value, isMultiline);
    }

    if (value.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            height: isMultiline ? 1.4 : 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkRow(IconData icon, String label, String url) {
    if (isEditing) {
      return _buildEditableField(label, url, false);
    }

    if (url.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            // Optional: Add URL launching functionality
          },
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1A3A8F)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  url,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A3A8F),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatchYearDropdown() {
    final currentVal = int.tryParse(batchController.text.trim());
    final years = AcademicOptions.getBatchYears(customYear: currentVal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Batch Year",
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: const Key('alumni_batch_year_dropdown'),
          value: (currentVal != null && years.contains(currentVal)) ? currentVal : null,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: "Select Batch Year",
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
          ),
          items: years.map((y) {
            return DropdownMenuItem<int>(
              value: y,
              child: Text(y.toString(), style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                batchController.text = val.toString();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDegreeDropdown() {
    final degrees = AcademicOptions.getDegrees();
    final isOtherSelected = selectedDegreeDropdown == AcademicOptions.otherOption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Degree",
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const Key('alumni_degree_dropdown'),
          value: (selectedDegreeDropdown != null && degrees.contains(selectedDegreeDropdown))
              ? selectedDegreeDropdown
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: "Select Degree",
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
          ),
          items: degrees.map((d) {
            return DropdownMenuItem<String>(
              value: d,
              child: Text(d, style: const TextStyle(fontSize: 14)),
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

                // Check if currently selected department is still valid for this degree
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
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('alumni_custom_degree_field'),
            controller: customDegreeController,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: "Enter Degree Name",
              hintText: "e.g. B.Arch, M.Phil, Ph.D",
              counterText: "",
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
            ),
            onChanged: (val) {
              degreeController.text = val.trim();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    final depts = AcademicOptions.getDepartmentsForDegree(
      degree: (selectedDegreeDropdown != null && selectedDegreeDropdown != AcademicOptions.otherOption)
          ? selectedDegreeDropdown
          : null,
    );
    final isOtherSelected = selectedDepartmentDropdown == AcademicOptions.otherOption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Department",
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const Key('alumni_department_dropdown'),
          value: (selectedDepartmentDropdown != null && depts.contains(selectedDepartmentDropdown))
              ? selectedDepartmentDropdown
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: "Select Department",
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
          ),
          items: depts.map((d) {
            return DropdownMenuItem<String>(
              value: d,
              child: Text(d, style: const TextStyle(fontSize: 14)),
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
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('alumni_custom_department_field'),
            controller: customDepartmentController,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: "Enter Department Name",
              hintText: "e.g. Artificial Intelligence, Data Science",
              counterText: "",
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
            ),
            onChanged: (val) {
              departmentController.text = val.trim();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEditableField(String label, String value, bool isMultiline) {
    if (label == "Batch Year") {
      return _buildBatchYearDropdown();
    }
    if (label == "Degree") {
      return _buildDegreeDropdown();
    }
    if (label == "Department") {
      return _buildDepartmentDropdown();
    }

    TextEditingController? controller;

    // Match the correct controller
    switch (label) {
      case "Designation":
        controller = designationController;
        break;
      case "Company":
        controller = companyController;
        break;
      case "Industry":
        controller = industryController;
        break;
      case "Skills":
        controller = skillsController;
        break;
      case "Experience":
        controller = expController;
        break;
      case "LinkedIn":
        controller = linkedInController;
        break;
      case "GitHub":
        controller = githubController;
        break;
      case "Contact Number":
        controller = contactController;
        break;
      case "Current City":
        controller = cityController;
        break;
      default:
        return const SizedBox.shrink();
    }

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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: isMultiline ? 3 : 1,
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditProfileButton() {
    if (isEditing) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cancelEditing,
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                label: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: saveProfile,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text(
                  "Save",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            isEditing = true;
          });
        },
        icon: const Icon(Icons.edit_outlined, color: Colors.white),
        label: const Text(
          "Edit Profile",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A3A8F),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout_outlined, color: Colors.white),
        label: const Text(
          "Sign Out",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A3A8F),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePickerHelper.pickImageWithSourceDialog(
      context,
      title: "Update Profile Photo",
      imageQuality: 80,
    );
    if (picked != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploading profile picture...")),
      );
      final url = await AlumniProfileService.uploadProfileImage(picked);
      if (url != null) {
        if (!mounted) return;
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        await StorageService.saveUserProfilePicture(url);
        setState(() {
          profilePictureUrl = url;
        });
        if (_savedProfile != null) {
          final updated = AlumniProfileModel(
            batchYear: _savedProfile!.batchYear,
            degree: _savedProfile!.degree,
            department: _savedProfile!.department,
            designation: _savedProfile!.designation,
            companyName: _savedProfile!.companyName,
            industry: _savedProfile!.industry,
            skills: _savedProfile!.skills,
            workExperience: _savedProfile!.workExperience,
            linkedInUrl: _savedProfile!.linkedInUrl,
            githubUrl: _savedProfile!.githubUrl,
            contactNumber: _savedProfile!.contactNumber,
            currentCity: _savedProfile!.currentCity,
            profilePictureUrl: url,
          );
          _savedProfile = updated;
          await AlumniProfileService.updateProfile(updated);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile picture updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to upload profile picture. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileViewsSection() {
    return FutureBuilder<List<ProfileViewModel>>(
      future: _profileViewsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final list = snapshot.data!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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