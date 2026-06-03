import 'package:flutter/material.dart';
import '../../services/alumni_profile_service.dart';
import '../../models/alumni_profile_model.dart';
import '../../utils/storage_service.dart';
import '../auth/login_screen.dart';

class AlumniProfileScreen extends StatefulWidget {
  const AlumniProfileScreen({super.key});

  @override
  State<AlumniProfileScreen> createState() => _AlumniProfileScreenState();
}

class _AlumniProfileScreenState extends State<AlumniProfileScreen> {
  bool isEditing = false;
  bool isLoading = true;

  String username = "";

  final batchController = TextEditingController();
  final degreeController = TextEditingController();
  final departmentController = TextEditingController();
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
    loadAllData();
  }

  @override
  void dispose() {
    batchController.dispose();
    degreeController.dispose();
    departmentController.dispose();
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

  Future<void> loadAllData() async {
    await loadUserName();
    await loadProfile();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadUserName() async {
    final name = await StorageService.getUserName();
    username = name ?? "";
  }

  Future<void> loadProfile() async {
    final profile = await AlumniProfileService.getProfile();

    if (profile != null) {
      batchController.text = profile.batchYear?.toString() ?? "";
      degreeController.text = profile.degree ?? "";
      departmentController.text = profile.department ?? "";
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
  }

  Future<void> saveProfile() async {
    final updatedProfile = AlumniProfileModel(
      batchYear: int.tryParse(batchController.text),
      degree: degreeController.text,
      department: departmentController.text,
      designation: designationController.text,
      companyName: companyController.text,
      industry: industryController.text,
      skills: skillsController.text,
      workExperience: double.tryParse(expController.text),
      linkedInUrl: linkedInController.text,
      githubUrl: githubController.text,
      contactNumber: contactController.text,
      currentCity: cityController.text,
    );

    final success = await AlumniProfileService.updateProfile(updatedProfile);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully")),
      );
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1A3A8F),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isEditing ? Icons.save_outlined : Icons.edit_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () async {
                  if (isEditing) {
                    await saveProfile();
                  }
                  setState(() {
                    isEditing = !isEditing;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined, color: Colors.white),
                onPressed: _handleLogout,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatsRow(),
                const SizedBox(height: 20),
                _buildAcademicSection(),
                const SizedBox(height: 16),
                _buildProfessionalSection(),
                const SizedBox(height: 16),
                _buildContactSection(),
                const SizedBox(height: 24),
                _buildLogoutButton(),
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
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 70,
                  color: Color(0xFF1A3A8F),
                ),
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

  Widget _buildEditableField(String label, String value, bool isMultiline) {
    TextEditingController? controller;

    // Match the correct controller
    switch (label) {
      case "Batch Year":
        controller = batchController;
        break;
      case "Degree":
        controller = degreeController;
        break;
      case "Department":
        controller = departmentController;
        break;
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
}