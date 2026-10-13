import 'package:flutter/material.dart';

import '../../models/event_model.dart';
import '../../models/job_model.dart';
import '../../models/alumni_profile_model.dart';
import '../../models/faculty_profile_model.dart';
import '../../services/event_service.dart';
import '../../services/job_service.dart';
import '../../services/alumni_profile_service.dart';
import '../../services/faculty_profile_service.dart';
import '../../config/api_config.dart';
import '../profile/profile_detail_screen.dart';
import '../../utils/date_helper.dart';
import '../../utils/salary_helper.dart';
import '../../utils/storage_service.dart';
import '../../widgets/event_card.dart';
import '../../widgets/job_card.dart';
import '../notification/notification_screen.dart';
import '../search/search_screen.dart';
import '../../utils/city_constants.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A3A8F),
          elevation: 2,
          title: Row(
            children: [
              const Icon(Icons.school_rounded, color: Colors.amber, size: 26),
              const SizedBox(width: 10),
              const Text(
                "GLS Connect",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
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
                  "STUDENT",
                  style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
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
            isScrollable: true,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: "Events", icon: Icon(Icons.event_rounded, size: 18)),
              Tab(text: "Jobs", icon: Icon(Icons.work_rounded, size: 18)),
              Tab(text: "My Activity", icon: Icon(Icons.history_rounded, size: 18)),
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
            const SizedBox(width: 5),
            IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            EventsPage(),
            JobsPage(),
            MyActivityPage(),
            AlumniPage(),
            FacultyPage(),
          ],
        ),
      ),
    );
  }
}

/// ================= EVENTS =================
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Future<List<EventModel>?> eventsFuture;
  String myEmail = "";
  bool _showPast = false;

  bool _isExpired(String dateStr) {
    return DateHelper.isExpired(dateStr);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    eventsFuture = EventService.getAllEvents();
    loadMyEmail();
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
    return FutureBuilder<List<EventModel>?>(
      future: eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Failed to load events",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "No events available.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          );
        }

        final filteredEvents = events
            .where(
              (event) => _isExpired(event.eventDate) == _showPast,
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filter Toggle Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showPast ? "Previous Events" : "Active Feed",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A8F),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showPast = !_showPast;
                    });
                  },
                  icon: Icon(
                    _showPast
                        ? Icons.feed_outlined
                        : Icons.history_toggle_off,
                    size: 16,
                  ),
                  label: Text(
                    _showPast
                        ? "Show Active"
                        : "Previous Events",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showPast
                        ? Colors.amber.shade700
                        : const Color(0xFF1A3A8F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (filteredEvents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    "No events available.",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ...filteredEvents.map((event) {
                return EventCard(
                  event: event,
                  myEmail: myEmail,
                  onRefresh: () {
                    setState(() {
                      eventsFuture = EventService.getAllEvents();
                    });
                  },
                );
              }),
          ],
        );
      },
    );
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

/// ================= MY ACTIVITY (MY JOBS + MY EVENTS) =================
class MyActivityPage extends StatefulWidget {
  const MyActivityPage({super.key});

  @override
  State<MyActivityPage> createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage> {
  late Future<List<JobModel>?> myJobsFuture;
  late Future<List<EventModel>?> myEventsFuture;
  String myEmail = "";

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    myEventsFuture = EventService.getMyEvents();
    myJobsFuture = JobService.getMyJobs();
    _loadMyEmail();
  }

  Future<void> _loadMyEmail() async {
    final email = await StorageService.getUserEmail();
    if (mounted) {
      setState(() {
        myEmail = email ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: const TabBar(
          labelColor: Color(0xFF1A3A8F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF1A3A8F),
          tabs: [
            Tab(text: "My Jobs"),
            Tab(text: "My Events"),
          ],
        ),
        body: TabBarView(
          children: [
            _buildMyJobsList(),
            _buildMyEventsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyJobsList() {
    return FutureBuilder<List<JobModel>?>(
      future: myJobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "No jobs posted yet.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return JobCard(
              job: job,
              myEmail: myEmail,
            );
          },
        );
      },
    );
  }

  Widget _buildMyEventsList() {
    return FutureBuilder<List<EventModel>?>(
      future: myEventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "No events created yet.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCard(
              event: event,
              myEmail: myEmail,
            );
          },
        );
      },
    );
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
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search jobs...",
                    prefixIcon:
                    const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),

              const SizedBox(width: 10),

              /// FILTER BUTTON
              GestureDetector(
                onTap: () =>
                    _openFilterSheet(context),
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
                return Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
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
                            jobsFuture =
                                JobService.getAllJobs();
                          });
                        },
                        child:
                        const Text("Retry"),
                      ),
                    ],
                  ),
                );
              }

              final jobs = snapshot.data ?? [];

              if (jobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.work_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No jobs available.",
                      ),
                    ],
                  ),
                );
              }

              // Filter jobs
              final filteredJobs =
              jobs.where((job) {
                final matchesSearch =
                    job.jobTitle
                        .toLowerCase()
                        .contains(
                      searchQuery
                          .toLowerCase(),
                    ) ||
                        job.companyName
                            .toLowerCase()
                            .contains(
                          searchQuery
                              .toLowerCase(),
                        );

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
                return const Center(
                  child: Text("No jobs match your filters"),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    jobsFuture = JobService.getAllJobs();
                  });
                },
                child: ListView.builder(
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
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
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
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
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search $roleLabel by name, department, role...",
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1A3A8F)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = "");
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.trim().toLowerCase());
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
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          "No $roleLabel match your search",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                      ],
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