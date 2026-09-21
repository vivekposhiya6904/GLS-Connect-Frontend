import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/event_service.dart';
import '../../services/job_service.dart';
import '../../models/event_model.dart';
import '../../models/job_model.dart';
import '../../config/api_config.dart';
import '../../utils/salary_helper.dart';
import '../../utils/date_helper.dart';
import '../../utils/storage_service.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';
import '../job_post/job_post_screen.dart';
import '../job_post/job_detail_screen.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  AdminStatsModel? _stats;
  List<AdminUserDto> _allUsers = [];
  List<AdminUserDto> _filteredUsers = [];
  final TextEditingController _userSearchController = TextEditingController();
  String _userRoleFilter = 'ALL'; // ALL, ALUMNI, FACULTY, STUDENT

  List<EventModel> _allEvents = [];
  String _eventFilter = 'UPCOMING'; // UPCOMING, PAST, ALL

  List<JobModel> _allJobs = [];
  String _jobFilter = 'ACTIVE'; // ACTIVE, PAST, ALL

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
      final stats = await AdminService.getAdminStats();
      final users = await AdminService.getAllUsers();
      final events = await EventService.getAllEvents() ?? [];
      final jobs = await JobService.getAllJobs() ?? [];

      setState(() {
        _stats = stats;
        _allUsers = users;
        _applyUserSearch();
        _allEvents = events;
        _allJobs = jobs;
      });
    } catch (e) {
      _showMessage("Error loading admin data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyUserSearch() {
    final query = _userSearchController.text.toLowerCase().trim();
    setState(() {
      _filteredUsers = _allUsers.where((u) {
        final role = u.roleName.toUpperCase();
        final matchesRole = _userRoleFilter == 'ALL' ||
            role == _userRoleFilter ||
            (_userRoleFilter == 'STUDENT' && (role == 'STUDENT' || role == 'USER'));
        final matchesQuery = query.isEmpty ||
            u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query);
        return matchesRole && matchesQuery;
      }).toList();
    });
  }

  void _showMessage(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // USER MANAGEMENT ACTIONS
  // ─────────────────────────────────────────────────────────────────
  Future<void> _showAddUserDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'STUDENT';
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
              Text("Add New User", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  items: ['STUDENT', 'FACULTY', 'ALUMNI'].map((r) {
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

  Future<void> _confirmDeleteUser(AdminUserDto user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text("Delete User", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Are you sure you want to remove ${user.name} (${user.email})? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete User", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await AdminService.deleteUser(user.id);
      if (success) {
        setState(() {
          _allUsers.removeWhere((u) => u.id == user.id);
          _filteredUsers.removeWhere((u) => u.id == user.id);
        });
        _showMessage("User ${user.name} removed successfully", isError: false);
        _loadDashboardData();
      } else {
        _showMessage("Failed to delete user");
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // EVENT ACTIONS
  // ─────────────────────────────────────────────────────────────────
  Future<void> _confirmDeleteEvent(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text("Delete Event", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Are you sure you want to delete '${event.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // ─────────────────────────────────────────────────────────────────
  // JOB ACTIONS
  // ─────────────────────────────────────────────────────────────────
  Future<void> _confirmDeleteJob(JobModel job) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text("Delete Job Post", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Are you sure you want to delete '${job.jobTitle}' at '${job.companyName}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // ─────────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────────
  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Are you sure you want to log out of the Admin Portal?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await StorageService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tabController.index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _tabController.index != 0) {
          _tabController.animateTo(0);
        }
      },
      child: Scaffold(
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
                  color: Colors.amber.withValues(alpha: 0.2),
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
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: "Logout",
              onPressed: _confirmLogout,
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 1. OVERVIEW TAB
  // ─────────────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    final stats = _stats ?? AdminStatsModel();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "System Dashboard Statistics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B40)),
          ),
          const SizedBox(height: 14),

          // Row 1: Users & Alumni
          Row(
            children: [
              Expanded(child: _metricCard("Total Users", "${stats.totalUsers}", Icons.people_alt_rounded, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard("Total Alumni", "${stats.totalAlumni}", Icons.school_rounded, Colors.indigo)),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Faculty & Students
          Row(
            children: [
              Expanded(child: _metricCard("Total Faculty", "${stats.totalFaculty}", Icons.badge_rounded, Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard("Total Students", "${stats.totalStudents}", Icons.person_rounded, Colors.blueGrey)),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: Total Jobs & Active Jobs
          Row(
            children: [
              Expanded(child: _metricCard("Total Jobs", "${stats.totalJobs}", Icons.work_rounded, Colors.brown)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard("Active Jobs", "${stats.activeJobs}", Icons.business_center_rounded, Colors.green)),
            ],
          ),
          const SizedBox(height: 12),

          // Row 4: Total Events & Active Events
          Row(
            children: [
              Expanded(child: _metricCard("Total Events", "${stats.totalEvents}", Icons.event_rounded, Colors.purple)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard("Active Events", "${stats.activeEvents}", Icons.event_available_rounded, Colors.deepOrange)),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
          ),
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userSearchController,
                  onChanged: (_) => _applyUserSearch(),
                  decoration: InputDecoration(
                    hintText: "Search by name or email...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _userSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _userSearchController.clear();
                              _applyUserSearch();
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text("Add User", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
        // Role Section Filters (All, Alumni, Faculty, Students)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  label: "All Users",
                  isSelected: _userRoleFilter == 'ALL',
                  onSelected: () {
                    setState(() {
                      _userRoleFilter = 'ALL';
                      _applyUserSearch();
                    });
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Alumni",
                  isSelected: _userRoleFilter == 'ALUMNI',
                  onSelected: () {
                    setState(() {
                      _userRoleFilter = 'ALUMNI';
                      _applyUserSearch();
                    });
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Faculty",
                  isSelected: _userRoleFilter == 'FACULTY',
                  onSelected: () {
                    setState(() {
                      _userRoleFilter = 'FACULTY';
                      _applyUserSearch();
                    });
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Students",
                  isSelected: _userRoleFilter == 'STUDENT',
                  onSelected: () {
                    setState(() {
                      _userRoleFilter = 'STUDENT';
                      _applyUserSearch();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: _filteredUsers.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text("No users match your search query", style: TextStyle(color: Colors.grey))),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final u = _filteredUsers[index];
                      final role = u.roleName.toUpperCase();
                      final isAlumni = role == 'ALUMNI';
                      final isFaculty = role == 'FACULTY';
                      final isAdmin = role == 'ADMIN';

                      final roleColor = isAlumni
                          ? Colors.indigo
                          : isFaculty
                              ? Colors.teal
                              : isAdmin
                                  ? Colors.amber.shade900
                                  : Colors.blueGrey;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1.5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: roleColor.withValues(alpha: 0.15),
                            child: Text(
                              u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(u.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (u.department.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text("• ${u.department}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ],
                              ),
                            ],
                          ),
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
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 3. EVENTS TAB (With Upcoming / Past / All Filters)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildEventsTab() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<EventModel> displayEvents = [];
    if (_eventFilter == 'UPCOMING') {
      displayEvents = _allEvents.where((e) {
        try {
          final d = DateTime.parse(e.eventDate.split('T')[0]);
          return !d.isBefore(today);
        } catch (_) {
          return true;
        }
      }).toList();
    } else if (_eventFilter == 'PAST') {
      displayEvents = _allEvents.where((e) {
        try {
          final d = DateTime.parse(e.eventDate.split('T')[0]);
          return d.isBefore(today);
        } catch (_) {
          return false;
        }
      }).toList();
    } else {
      displayEvents = List.from(_allEvents);
    }

    return Column(
      children: [
        // Filter Bar & Create Event Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(
                        label: "Upcoming",
                        isSelected: _eventFilter == 'UPCOMING',
                        onSelected: () => setState(() => _eventFilter = 'UPCOMING'),
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: "Past",
                        isSelected: _eventFilter == 'PAST',
                        onSelected: () => setState(() => _eventFilter = 'PAST'),
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: "All Events",
                        isSelected: _eventFilter == 'ALL',
                        onSelected: () => setState(() => _eventFilter = 'ALL'),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A8F),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                ).then((_) => _loadDashboardData()),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text("New Event", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: displayEvents.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text("No events found", style: TextStyle(color: Colors.grey))),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: displayEvents.length,
                    itemBuilder: (context, index) {
                      final event = displayEvents[index];
                      return _eventCard(event);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _eventCard(EventModel event) {
    final isExpired = DateHelper.isExpired(event.eventDate);
    final statusText = isExpired ? "PAST" : "UPCOMING";
    final badgeColor = isExpired ? Colors.grey : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: event, isAdmin: true),
            ),
          );
          if (result == true) {
            _loadDashboardData();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (event.targetDepartment != null && event.targetDepartment!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text("• ${event.targetDepartment}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF1A3A8F)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreateEventScreen(eventToEdit: event)),
                    ).then((_) => _loadDashboardData()),
                    tooltip: "Edit Event",
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    onPressed: () => _confirmDeleteEvent(event),
                    tooltip: "Delete Event",
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
              ),

              // Network Image Preview
              if (event.imageUrl != null && event.imageUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    event.imageUrl!.startsWith("http")
                        ? event.imageUrl!
                        : "${ApiConfig.baseUrl}${event.imageUrl!}",
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateHelper.formatFriendlyDate(event.eventDate),
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (event.createdByName != null && event.createdByName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  "Organized by: ${event.createdByName}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 4. JOBS TAB (With Active / Expired / All Filters)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildJobsTab() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<JobModel> displayJobs = [];
    if (_jobFilter == 'ACTIVE') {
      displayJobs = _allJobs.where((j) {
        try {
          if (j.lastDateToApply.isEmpty) return true;
          final d = DateTime.parse(j.lastDateToApply.split('T')[0]);
          return !d.isBefore(today);
        } catch (_) {
          return true;
        }
      }).toList();
    } else if (_jobFilter == 'PAST') {
      displayJobs = _allJobs.where((j) {
        try {
          if (j.lastDateToApply.isEmpty) return false;
          final d = DateTime.parse(j.lastDateToApply.split('T')[0]);
          return d.isBefore(today);
        } catch (_) {
          return false;
        }
      }).toList();
    } else {
      displayJobs = List.from(_allJobs);
    }

    return Column(
      children: [
        // Filter Bar & Post Job Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(
                        label: "Active Jobs",
                        isSelected: _jobFilter == 'ACTIVE',
                        onSelected: () => setState(() => _jobFilter = 'ACTIVE'),
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: "Expired Jobs",
                        isSelected: _jobFilter == 'PAST',
                        onSelected: () => setState(() => _jobFilter = 'PAST'),
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: "All Jobs",
                        isSelected: _jobFilter == 'ALL',
                        onSelected: () => setState(() => _jobFilter = 'ALL'),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A8F),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostJobScreen()),
                ).then((_) => _loadDashboardData()),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text("Post Job", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: displayJobs.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text("No jobs found", style: TextStyle(color: Colors.grey))),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: displayJobs.length,
                    itemBuilder: (context, index) {
                      final job = displayJobs[index];
                      return _jobCard(job);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _jobCard(JobModel job) {
    final isExpired = DateHelper.isExpired(job.lastDateToApply);
    final statusText = isExpired ? "EXPIRED" : "ACTIVE";
    final badgeColor = isExpired ? Colors.grey : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailScreen(job: job, isAdmin: true),
            ),
          );
          if (result == true) {
            _loadDashboardData();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3A8F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work_rounded, color: Color(0xFF1A3A8F), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text("${job.companyName} • ${job.location}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF1A3A8F)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PostJobScreen(jobToEdit: job)),
                    ).then((_) => _loadDashboardData()),
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
              Text(job.jobDescription, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (job.salary.isNotEmpty)
                    Chip(
                      label: Text("💰 ${SalaryHelper.formatLpa(job.salary)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (job.experienceRequired.isNotEmpty)
                    Chip(
                      label: Text("⏳ ${job.experienceRequired}", style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (job.jobType.isNotEmpty)
                    Chip(
                      label: Text("📌 ${job.jobType}", style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (job.userName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text("Posted by ${job.userName} (${job.userEmail})", style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF1A3A8F),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF0F172A),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}