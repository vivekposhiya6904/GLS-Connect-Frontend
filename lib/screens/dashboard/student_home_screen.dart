import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../models/alumni_profile_model.dart';
import '../../models/faculty_profile_model.dart';
import '../../services/job_service.dart';
import '../../services/alumni_profile_service.dart';
import '../../services/faculty_profile_service.dart';
import '../../config/api_config.dart';
import '../profile/profile_detail_screen.dart';
import '../../utils/date_helper.dart';
import '../../utils/salary_helper.dart';
import '../../utils/storage_service.dart';
import '../../widgets/job_card.dart';
import '../../widgets/app_search_bar.dart';
import '../notification/notification_screen.dart';
import '../../utils/city_constants.dart';
import '../../utils/focus_helper.dart';
import 'alumni_home_screen.dart' show EventList;

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A3A8F),
          elevation: 2,
          title: Row(
            children: [
              const Icon(Icons.school_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  "GLS Connect",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: const Text(
                  "STUDENT",
                  style: TextStyle(color: Colors.amber, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: "Events", icon: Icon(Icons.event_rounded, size: 18)),
              Tab(text: "Jobs", icon: Icon(Icons.work_rounded, size: 18)),
              Tab(text: "Alumni", icon: Icon(Icons.people_alt_rounded, size: 18)),
              Tab(text: "Faculty", icon: Icon(Icons.badge_rounded, size: 18)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: const TabBarView(
          children: [
            EventsPage(),
            JobsPage(),
            AlumniPage(),
            FacultyPage(),
          ],
        ),
      ),
    );
  }
}

/// ================= EVENTS =================
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EventList();
  }
}

/// ================= JOBS =================
class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const JobList();
  }
}

/// ================= ALUMNI =================
class AlumniPage extends StatelessWidget {
  const AlumniPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileList(
      title: "Alumni Directory",
      role: "ALUMNI",
    );
  }
}

/// ================= FACULTY =================
class FacultyPage extends StatelessWidget {
  const FacultyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileList(
      title: "Faculty Members",
      role: "FACULTY",
    );
  }
}

/// ================= JOB LIST =================
class JobList extends StatefulWidget {
  const JobList({super.key});

  @override
  State<JobList> createState() => _JobListState();
}

class _JobListState extends State<JobList> {
  late Future<List<JobModel>?> jobsFuture;

  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String selectedLocation = "All";
  String selectedSalary = "All";
  bool showPast = false;
  String myEmail = "";

  @override
  void initState() {
    super.initState();

    jobsFuture = JobService.getAllJobs();

    loadMyEmail();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> loadMyEmail() async {
    final email = await StorageService.getUserEmail();

    if (mounted) {
      setState(() {
        myEmail = email ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🔍 SEARCH + FILTER BUTTON
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              /// SEARCH BAR
              Expanded(
                child: AppSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: "Search jobs by title, company or skills...",
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  onClear: () {
                    setState(() {
                      searchQuery = "";
                    });
                  },
                ),
              ),

              const SizedBox(width: 10),

              /// FILTER BUTTON
              GestureDetector(
                onTap: () {
                  _searchFocusNode.unfocus();
                  _openFilterSheet(context);
                },
                child: Container(
                  padding:
                  const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A8F),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        /// JOB LIST
        Expanded(
          child: FutureBuilder<List<JobModel>?>(
            future: jobsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Failed to load jobs",
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  jobsFuture = JobService.getAllJobs();
                                });
                              },
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final jobs = snapshot.data ?? [];

              if (jobs.isEmpty) {
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No jobs available.",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Filter jobs
              final filteredJobs =
              jobs.where((job) {
                final query = searchQuery.trim().toLowerCase();
                final matchesSearch = query.isEmpty ||
                    job.jobTitle.toLowerCase().contains(query) ||
                    job.companyName.toLowerCase().contains(query) ||
                    job.skillsRequired.toLowerCase().contains(query) ||
                    job.jobDescription.toLowerCase().contains(query) ||
                    job.location.toLowerCase().contains(query);

                final matchesLocation = selectedLocation == "All" ||
                    job.location.trim().toLowerCase() == selectedLocation.trim().toLowerCase() ||
                    (selectedLocation.contains("Bengaluru") && job.location.toLowerCase().contains("bangalore")) ||
                    (selectedLocation.contains("Delhi") && job.location.toLowerCase().contains("delhi"));

                final matchesSalary = SalaryHelper.matchesFilter(job.salary, selectedSalary);

                final isExpired = DateHelper.isExpired(job.lastDateToApply);
                final matchesPast = showPast ? true : !isExpired;

                return matchesSearch && matchesLocation && matchesSalary && matchesPast;
              }).toList();

              if (filteredJobs.isEmpty) {
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              const Text(
                                "No jobs match your search or filters",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                searchQuery.isNotEmpty
                                    ? "Try adjusting your query or resetting filters."
                                    : "Try selecting different filter options.",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _searchFocusNode.unfocus();
                                  setState(() {
                                    _searchController.clear();
                                    searchQuery = "";
                                    selectedLocation = "All";
                                    selectedSalary = "All";
                                    showPast = false;
                                  });
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text("Reset Search & Filters"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A3A8F),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    jobsFuture = JobService.getAllJobs();
                  });
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) {
                    final job = filteredJobs[index];
                    return JobCard(
                      job: job,
                      myEmail: myEmail,
                      onRefresh: () {
                        setState(() {
                          jobsFuture = JobService.getAllJobs();
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 🔥 FILTER BOTTOM SHEET
  void _openFilterSheet(BuildContext context) {
    AppFocusHelper.unfocus(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filter Jobs",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    /// LOCATION
                    DropdownButtonFormField<String>(
                      value: selectedLocation,
                      decoration: InputDecoration(
                        labelText: "Location",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      items: CityConstants.filterCities
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setSheetState(() => selectedLocation = value);
                      },
                    ),

                    const SizedBox(height: 14),

                    /// SALARY
                    DropdownButtonFormField<String>(
                      value: selectedSalary,
                      decoration: InputDecoration(
                        labelText: "Salary (LPA)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      items: SalaryHelper.filterOptions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setSheetState(() => selectedSalary = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    /// SHOW PAST JOBS SWITCH
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Show Past Jobs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Switch(
                          value: showPast,
                          onChanged: (val) => setSheetState(() => showPast = val),
                          activeColor: const Color(0xFF1A3A8F),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// APPLY BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3A8F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          AppFocusHelper.unfocus(context);
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ================= PROFILE LIST =================
class ProfileList extends StatefulWidget {
  final String title;
  final String? role;

  const ProfileList({
    super.key,
    required this.title,
    this.role,
  });

  @override
  State<ProfileList> createState() => _ProfileListState();
}

class _ProfileListState extends State<ProfileList> {
  late Future<List<dynamic>?> _profilesFuture;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String get _resolvedRole =>
      (widget.role ?? (widget.title.toLowerCase().contains("faculty") ? "FACULTY" : "ALUMNI")).toUpperCase();

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadProfiles() {
    if (_resolvedRole == "ALUMNI") {
      _profilesFuture = AlumniProfileService.getAllAlumniProfiles();
    } else {
      _profilesFuture = FacultyProfileService.getAllFacultyProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAlumni = _resolvedRole == "ALUMNI";
    final roleLabel = isAlumni ? "alumni" : "faculty";

    return Column(
      children: [
        /// 🔍 SEARCH BAR
        Padding(
          padding: const EdgeInsets.all(12),
          child: AppSearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: "Search $roleLabel by name, department, role...",
            onChanged: (value) {
              setState(() => _searchQuery = value.trim().toLowerCase());
            },
            onClear: () {
              setState(() => _searchQuery = "");
            },
          ),
        ),

        /// PROFILES LIST WITH STATES
        Expanded(
          child: FutureBuilder<List<dynamic>?>(
            future: _profilesFuture,
            builder: (context, snapshot) {
              // 1. Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Error state
              if (snapshot.hasError || snapshot.data == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          "Failed to load $roleLabel records",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error?.toString() ?? "Could not connect to server.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _loadProfiles();
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text("Retry"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3A8F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final list = snapshot.data!;

              // 3. Empty state from backend
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAlumni ? Icons.people_outline : Icons.badge_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isAlumni ? "No alumni found" : "No faculty found",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isAlumni
                              ? "Registered alumni will appear here."
                              : "Registered faculty members will appear here.",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 4. Search Filter
              final filtered = list.where((p) {
                if (_searchQuery.isEmpty) return true;

                if (isAlumni) {
                  final alumni = p as AlumniProfileModel;
                  final name = alumni.userName?.toLowerCase() ?? "";
                  final company = alumni.companyName?.toLowerCase() ?? "";
                  final designation = alumni.designation?.toLowerCase() ?? "";
                  final dept = alumni.department?.toLowerCase() ?? "";
                  final degree = alumni.degree?.toLowerCase() ?? "";
                  final skills = alumni.skills?.toLowerCase() ?? "";
                  final city = alumni.currentCity?.toLowerCase() ?? "";
                  return name.contains(_searchQuery) ||
                      company.contains(_searchQuery) ||
                      designation.contains(_searchQuery) ||
                      dept.contains(_searchQuery) ||
                      degree.contains(_searchQuery) ||
                      skills.contains(_searchQuery) ||
                      city.contains(_searchQuery);
                } else {
                  final faculty = p as FacultyProfileModel;
                  final name = faculty.userName?.toLowerCase() ?? "";
                  final dept = faculty.department?.toLowerCase() ?? "";
                  final designation = faculty.designation?.toLowerCase() ?? "";
                  final qualification = faculty.qualification?.toLowerCase() ?? "";
                  final specialization = faculty.specialization?.toLowerCase() ?? "";
                  final skills = faculty.skills?.toLowerCase() ?? "";
                  return name.contains(_searchQuery) ||
                      dept.contains(_searchQuery) ||
                      designation.contains(_searchQuery) ||
                      qualification.contains(_searchQuery) ||
                      specialization.contains(_searchQuery) ||
                      skills.contains(_searchQuery);
                }
              }).toList();

              if (filtered.isEmpty) {
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                "No $roleLabel match your search",
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _searchFocusNode.unfocus();
                                    _searchController.clear();
                                    setState(() => _searchQuery = "");
                                  },
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  label: const Text("Clear Search"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A3A8F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              // 5. Success state
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _loadProfiles();
                  });
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    if (isAlumni) {
                      final alumni = filtered[index] as AlumniProfileModel;

                      String subtitle = "";
                      if (alumni.designation != null &&
                          alumni.designation!.isNotEmpty &&
                          alumni.companyName != null &&
                          alumni.companyName!.isNotEmpty) {
                        subtitle = "${alumni.designation} at ${alumni.companyName}";
                      } else if (alumni.designation != null && alumni.designation!.isNotEmpty) {
                        subtitle = alumni.designation!;
                      } else if (alumni.companyName != null && alumni.companyName!.isNotEmpty) {
                        subtitle = "Works at ${alumni.companyName}";
                      } else if (alumni.degree != null && alumni.degree!.isNotEmpty) {
                        subtitle = alumni.batchYear != null
                            ? "${alumni.degree} • Batch ${alumni.batchYear}"
                            : alumni.degree!;
                      } else {
                        subtitle = "Alumni Member";
                      }

                      String? deptInfo;
                      if (alumni.department != null &&
                          alumni.department!.isNotEmpty &&
                          !subtitle.contains(alumni.department!)) {
                        deptInfo = alumni.department;
                      }

                      return ProfileCard(
                        name: (alumni.userName != null && alumni.userName!.trim().isNotEmpty)
                            ? alumni.userName!.trim()
                            : "Alumni Member",
                        role: subtitle,
                        department: deptInfo,
                        userId: alumni.userId ?? 0,
                        userRole: "ALUMNI",
                        profilePictureUrl: alumni.profilePictureUrl,
                      );
                    } else {
                      final faculty = filtered[index] as FacultyProfileModel;

                      String subtitle = "";
                      if (faculty.designation != null &&
                          faculty.designation!.isNotEmpty &&
                          faculty.department != null &&
                          faculty.department!.isNotEmpty) {
                        subtitle = "${faculty.designation} • ${faculty.department}";
                      } else if (faculty.designation != null && faculty.designation!.isNotEmpty) {
                        subtitle = faculty.designation!;
                      } else if (faculty.department != null && faculty.department!.isNotEmpty) {
                        subtitle = faculty.department!;
                      } else {
                        subtitle = "Faculty Member";
                      }

                      String? extraInfo;
                      if (faculty.specialization != null &&
                          faculty.specialization!.isNotEmpty &&
                          !subtitle.contains(faculty.specialization!)) {
                        extraInfo = faculty.specialization;
                      }

                      return ProfileCard(
                        name: (faculty.userName != null && faculty.userName!.trim().isNotEmpty)
                            ? faculty.userName!.trim()
                            : "Faculty Member",
                        role: subtitle,
                        department: extraInfo,
                        userId: faculty.userId ?? 0,
                        userRole: "FACULTY",
                        profilePictureUrl: faculty.profilePictureUrl,
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ================= PROFILE CARD =================
class ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  final int userId;
  final String userRole;
  final String? profilePictureUrl;
  final String? department;

  const ProfileCard({
    super.key,
    required this.name,
    required this.role,
    this.userId = 0,
    this.userRole = "",
    this.profilePictureUrl,
    this.department,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: userId > 0
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileDetailScreen(
                        userId: userId,
                        userName: name,
                        userRole: userRole,
                      ),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE0E7FF),
                  backgroundImage: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                      ? NetworkImage(
                          profilePictureUrl!.startsWith("http")
                              ? profilePictureUrl!
                              : "${ApiConfig.baseUrl}$profilePictureUrl",
                        )
                      : null,
                  onBackgroundImageError: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                      ? (exception, stackTrace) {
                          // Handled safely without crashing
                        }
                      : null,
                  child: profilePictureUrl == null || profilePictureUrl!.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.indigo,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (role.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          role,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (department != null && department!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          department!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (userId > 0)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ================= IMAGE ZOOM =================
class ImageZoomScreen extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const ImageZoomScreen({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Colors.black.withValues(alpha: 0.95),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin:
              const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: tag,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) =>
                      Image.network(
                        "https://picsum.photos/600/300?random=$tag",
                        fit: BoxFit.contain,
                      ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding:
                const EdgeInsets.all(16.0),
                child: CircleAvatar(
                  backgroundColor:
                  Colors.black38,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}