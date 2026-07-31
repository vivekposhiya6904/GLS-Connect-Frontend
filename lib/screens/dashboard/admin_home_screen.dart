import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/event_service.dart';
import '../../services/job_service.dart';
import '../../models/event_model.dart';
import '../../models/job_model.dart';
import '../../config/api_config.dart';
import 'create_event_screen.dart';
import '../job_post/job_post_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  List<AdminUserDto> _allUsers = [];
  List<AdminUserDto> _filteredUsers = [];

  String _selectedRoleFilter = 'ALL';
  final TextEditingController _userSearchController = TextEditingController();

  List<EventModel> _pendingEvents = [];
  List<EventModel> _approvedEvents = [];
  List<JobModel> _allJobs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final users = await AdminService.getAllUsers();
      final pending = await AdminService.getPendingEvents();
      final approved = await EventService.getAllEvents() ?? [];
      final jobs = await JobService.getAllJobs() ?? [];

      setState(() {
        _allUsers = users;
        _applyUserFilters();
        _pendingEvents = pending;
        _approvedEvents = approved;
        _allJobs = jobs;
      });
    } catch (e) {
      _showMessage("Error loading admin data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyUserFilters() {
    final query = _userSearchController.text.toLowerCase().trim();
    setState(() {
      _filteredUsers = _allUsers.where((u) {
        final matchesRole = _selectedRoleFilter == 'ALL' || u.roleName.toUpperCase() == _selectedRoleFilter;
        final matchesQuery = query.isEmpty ||
            u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query);
        return matchesRole && matchesQuery;
      }).toList();
    });
  }

  void _showMessage(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper for rendering event images cleanly
  Widget _buildNetworkImage(String? relativeOrFullUrl, {double height = 180}) {
    if (relativeOrFullUrl == null || relativeOrFullUrl.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    String fullUrl = relativeOrFullUrl.trim();
    if (!fullUrl.startsWith("http")) {
      fullUrl = "${ApiConfig.baseUrl}$fullUrl";
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: height,
          width: double.infinity,
          color: Colors.grey[200],
          child: Image.network(
            fullUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: height,
                color: Colors.grey[200],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                    SizedBox(height: 4),
                    Text("Image not available", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Action: Add User Dialog
  Future<void> _showAddUserDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'ALUMNI';
    String selectedDept = 'MCA';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF1A3A8F)),
              SizedBox(width: 10),
              Text("Add New User", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Full Name", hintText: "e.g. John Doe"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email Address", hintText: "e.g. john@gls.edu.in"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password", hintText: "Minimum 6 chars"),
                ),
                const SizedBox(height: 16),
                const Text("Role", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                DropdownButton<String>(
                  value: selectedRole,
                  isExpanded: true,
                  items: ['ALUMNI', 'FACULTY', 'USER', 'ADMIN'].map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 10),
                const Text("Department", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                DropdownButton<String>(
                  value: selectedDept,
                  isExpanded: true,
                  items: ['MCA', 'BCA', 'MBA', 'IT', 'CS'].map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedDept = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A8F)),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final password = passwordCtrl.text.trim();

                if (name.isEmpty || email.isEmpty || password.isEmpty) {
                  _showMessage("Please fill all fields");
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                final success = await AdminService.createUser(
                  name: name,
                  email: email,
                  password: password,
                  roleName: selectedRole,
                  department: selectedDept,
                );

                if (success) {
                  _showMessage("User '$name' created successfully!", isError: false);
                  _loadDashboardData();
                } else {
                  _showMessage("Failed to create user");
                  setState(() => _isLoading = false);
                }
              },
              child: const Text("Create User", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Action: Delete User
  Future<void> _confirmDeleteUser(AdminUserDto user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete User"),
        content: Text("Are you sure you want to remove ${user.name} (${user.email})? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await AdminService.deleteUser(user.id);
      if (success) {
        _showMessage("User ${user.name} removed successfully", isError: false);
        _loadDashboardData();
      } else {
        _showMessage("Failed to delete user");
      }
    }
  }

  // Action: Approve Event
  Future<void> _approveEvent(int id) async {
    final success = await AdminService.approveEvent(id);
    if (success) {
      _showMessage("Event approved successfully", isError: false);
      _loadDashboardData();
    } else {
      _showMessage("Failed to approve event");
    }
  }

  // Action: Reject Event
  Future<void> _rejectEvent(int id) async {
    final success = await AdminService.rejectEvent(id);
    if (success) {
      _showMessage("Event rejected", isError: false);
      _loadDashboardData();
    } else {
      _showMessage("Failed to reject event");
    }
  }

  // Action: Delete Event
  Future<void> _confirmDeleteEvent(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Event"),
        content: Text("Are you sure you want to delete '${event.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && event.id != null) {
      final success = await AdminService.deleteEvent(event.id!);
      if (success) {
        _showMessage("Event deleted successfully", isError: false);
        _loadDashboardData();
      } else {
        _showMessage("Failed to delete event");
      }
    }
  }

  // Action: Delete Job
  Future<void> _confirmDeleteJob(JobModel job) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Job Post"),
        content: Text("Are you sure you want to delete '${job.jobTitle}' at '${job.companyName}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && job.id != null) {
      final success = await JobService.deleteJob(job.id!);
      if (success) {
        _showMessage("Job deleted successfully", isError: false);
        _loadDashboardData();
      } else {
        _showMessage("Failed to delete job");
      }
    }
  }

  // Action: Edit Job Dialog
  Future<void> _showEditJobDialog(JobModel job) async {
    if (job.id == null) return;
    final companyCtrl = TextEditingController(text: job.companyName);
    final titleCtrl = TextEditingController(text: job.jobTitle);
    final locationCtrl = TextEditingController(text: job.location);
    final salaryCtrl = TextEditingController(text: job.salary);
    final descCtrl = TextEditingController(text: job.jobDescription);
    final skillsCtrl = TextEditingController(text: job.skillsRequired);
    final expCtrl = TextEditingController(text: job.experienceRequired);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Color(0xFF1A3A8F)),
            SizedBox(width: 10),
            Text("Edit Job Post", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: "Company Name")),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Job Title")),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: "Location")),
              TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: "Salary Package")),
              TextField(controller: expCtrl, decoration: const InputDecoration(labelText: "Experience Required")),
              TextField(controller: skillsCtrl, decoration: const InputDecoration(labelText: "Skills Required")),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Job Description")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A8F)),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final success = await JobService.updateJob(
                jobId: job.id!,
                companyName: companyCtrl.text.trim(),
                jobTitle: titleCtrl.text.trim(),
                location: locationCtrl.text.trim(),
                salary: salaryCtrl.text.trim(),
                jobDescription: descCtrl.text.trim(),
                skillsRequired: skillsCtrl.text.trim(),
                experienceRequired: expCtrl.text.trim(),
                joiningType: job.joiningType,
                jobType: job.jobType,
                lastDateToApply: job.lastDateToApply,
                companyLink: job.companyLink,
                companyEmail: job.companyEmail,
              );

              if (success) {
                _showMessage("Job updated successfully!", isError: false);
                _loadDashboardData();
              } else {
                _showMessage("Failed to update job");
                setState(() => _isLoading = false);
              }
            },
            child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A8F),
        elevation: 2,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            const Text(
              "Admin Portal",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: const Text(
                "ADMIN",
                style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Overview", icon: Icon(Icons.dashboard_rounded, size: 20)),
            Tab(text: "Users", icon: Icon(Icons.people_alt_rounded, size: 20)),
            Tab(text: "Events", icon: Icon(Icons.event_rounded, size: 20)),
            Tab(text: "Jobs", icon: Icon(Icons.work_rounded, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A8F)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildEventsTab(),
                _buildJobsTab(),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 1. OVERVIEW TAB
  // ─────────────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    final totalUsers = _allUsers.length;
    final alumniCount = _allUsers.where((u) => u.roleName.toUpperCase() == 'ALUMNI').length;
    final facultyCount = _allUsers.where((u) => u.roleName.toUpperCase() == 'FACULTY').length;
    final studentCount = _allUsers.where((u) => u.roleName.toUpperCase() == 'USER').length;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Overall System Statistics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B40)),
          ),
          const SizedBox(height: 12),

          // Total Metric Cards
          Row(
            children: [
              Expanded(child: _metricCard("Total Alumni", "$alumniCount", Icons.school_rounded, Colors.indigo)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard("Total Faculty", "$facultyCount", Icons.badge_rounded, Colors.teal)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metricCard("Total Students", "$studentCount", Icons.person_rounded, Colors.blueGrey)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard("Total Users", "$totalUsers", Icons.people_alt_rounded, Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metricCard("Active Events", "${_approvedEvents.length}", Icons.event_available_rounded, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard("Total Jobs", "${_allJobs.length}", Icons.work_outline_rounded, Colors.brown)),
            ],
          ),
          const SizedBox(height: 24),

          // User Distribution Summary
          const Text(
            "User Role Breakdown",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B40)),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _userRoleRow("Alumni Members", "$alumniCount", Colors.indigo),
                  const Divider(),
                  _userRoleRow("Faculty Members", "$facultyCount", Colors.teal),
                  const Divider(),
                  _userRoleRow("Students / General Users", "$studentCount", Colors.blueGrey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Action Buttons
          const Text(
            "Admin Actions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B40)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A8F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                  label: const Text("Add User", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen())).then((_) => _loadDashboardData()),
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  label: const Text("Create Event", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _userRoleRow(String role, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 5, backgroundColor: color),
              const SizedBox(width: 10),
              Text(role, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 2. USERS TAB
  // ─────────────────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userSearchController,
                      onChanged: (_) => _applyUserFilters(),
                      decoration: InputDecoration(
                        hintText: "Search by name or email...",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _userSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _userSearchController.clear();
                                  _applyUserFilters();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF4F7FF),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3A8F),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _showAddUserDialog,
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    label: const Text("Add User", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['ALL', 'ALUMNI', 'FACULTY', 'USER', 'ADMIN'].map((role) {
                    final isSelected = _selectedRoleFilter == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(role == 'USER' ? 'STUDENT/USER' : role),
                        selectedColor: const Color(0xFF1A3A8F),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                        onSelected: (_) {
                          setState(() {
                            _selectedRoleFilter = role;
                            _applyUserFilters();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _filteredUsers.isEmpty
              ? const Center(child: Text("No users match your filters", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final u = _filteredUsers[index];
                    final isAlumni = u.roleName.toUpperCase() == 'ALUMNI';
                    final isFaculty = u.roleName.toUpperCase() == 'FACULTY';

                    final roleColor = isAlumni
                        ? Colors.indigo
                        : isFaculty
                            ? Colors.teal
                            : u.roleName.toUpperCase() == 'ADMIN'
                                ? Colors.amber.shade900
                                : Colors.blueGrey;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: roleColor.withOpacity(0.15),
                          child: Text(
                            u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                u.roleName,
                                style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                          onPressed: () => _confirmDeleteUser(u),
                          tooltip: "Remove User",
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 3. EVENTS TAB (With Image Display, Pending, Upcoming & Past Events)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildEventsTab() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcomingEvents = _approvedEvents.where((e) {
      try {
        final d = DateTime.parse(e.eventDate.split('T')[0]);
        return d.isAfter(today.subtract(const Duration(days: 1)));
      } catch (_) {
        return true;
      }
    }).toList();

    final pastEvents = _approvedEvents.where((e) {
      try {
        final d = DateTime.parse(e.eventDate.split('T')[0]);
        return d.isBefore(today);
      } catch (_) {
        return false;
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pending Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Pending Approvals (${_pendingEvents.length})",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_pendingEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("No pending events to approve.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          )
        else
          ..._pendingEvents.map((event) => _pendingEventCard(event)),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),

        // Upcoming Events Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Upcoming Events (${upcomingEvents.length})",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A8F)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1A3A8F)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen())).then((_) => _loadDashboardData()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (upcomingEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("No upcoming events found.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          )
        else
          ...upcomingEvents.map((event) => _approvedEventCard(event, isUpcoming: true)),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),

        // Past Events Section
        Text(
          "Past Events (${pastEvents.length})",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (pastEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("No past events recorded.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          )
        else
          ...pastEvents.map((event) => _approvedEventCard(event, isUpcoming: false)),
      ],
    );
  }

  Widget _pendingEventCard(EventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.orange.withOpacity(0.4))),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text("PENDING", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.black87)),

            // Image display for Pending Event
            if (event.imageUrl != null && event.imageUrl!.trim().isNotEmpty) ...[
              _buildNetworkImage(event.imageUrl, height: 180),
            ],

            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                Text(event.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                Text(event.eventDate.split('T')[0], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (event.createdByName != null) ...[
              const SizedBox(height: 4),
              Text("Organized by: ${event.createdByName}", style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: event.id == null ? null : () => _rejectEvent(event.id!),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Reject"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: event.id == null ? null : () => _approveEvent(event.id!),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Approve", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _approvedEventCard(EventModel event, {required bool isUpcoming}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isUpcoming ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isUpcoming ? "UPCOMING" : "PAST",
                              style: TextStyle(color: isUpcoming ? Colors.green : Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                  onPressed: () => _confirmDeleteEvent(event),
                  tooltip: "Delete Event",
                ),
              ],
            ),

            // Image display for Approved Event
            if (event.imageUrl != null && event.imageUrl!.trim().isNotEmpty) ...[
              _buildNetworkImage(event.imageUrl, height: 180),
            ],

            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                Text(event.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                Text(event.eventDate.split('T')[0], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (event.createdByName != null) ...[
              const SizedBox(height: 4),
              Text("Organized by: ${event.createdByName}", style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 4. JOBS TAB
  // ─────────────────────────────────────────────────────────────────
  Widget _buildJobsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Job Postings (${_allJobs.length})",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B40)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1A3A8F)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostJobScreen())).then((_) => _loadDashboardData()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_allJobs.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No job posts found", style: TextStyle(color: Colors.grey))))
        else
          ..._allJobs.map((job) => _jobCard(job)),
      ],
    );
  }

  Widget _jobCard(JobModel job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.work_rounded, color: Colors.indigo, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("${job.companyName} • ${job.location}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF1A3A8F)),
                  onPressed: () => _showEditJobDialog(job),
                  tooltip: "Edit Job",
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                  onPressed: () => _confirmDeleteJob(job),
                  tooltip: "Delete Job",
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(job.jobDescription, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (job.salary.isNotEmpty)
                  Chip(
                    label: Text("💰 ${job.salary}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    visualDensity: VisualDensity.compact,
                  ),
                if (job.experienceRequired.isNotEmpty)
                  Chip(
                    label: Text("⏳ ${job.experienceRequired}", style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    visualDensity: VisualDensity.compact,
                  ),
                if (job.jobType.isNotEmpty)
                  Chip(
                    label: Text("📌 ${job.jobType}", style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text("Posted by ${job.userName} (${job.userEmail})", style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}