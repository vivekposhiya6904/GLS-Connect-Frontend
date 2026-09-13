import 'package:flutter/material.dart';

import '../../models/event_model.dart';
import '../../models/job_model.dart';
import '../../services/event_service.dart';
import '../../services/job_service.dart';
import '../../utils/date_helper.dart';
import '../../utils/salary_helper.dart';
import '../../utils/storage_service.dart';
import '../../widgets/event_card.dart';
import '../../widgets/job_card.dart';
import '../notification/notification_screen.dart';
import '../search/search_screen.dart';

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
                  _showPast ? "Previous Ends" : "Active Feed",
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
                        : "Previous Ends",
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

                final matchesLocation =
                    selectedLocation == "All" ||
                        job.location ==
                            selectedLocation;

                final matchesSalary = SalaryHelper.matchesFilter(job.salary, selectedSalary);

                return matchesSearch &&
                    matchesLocation &&
                    matchesSalary;
              }).toList();

              if (filteredJobs.isEmpty) {
                return const Center(
                  child: Text(
                    "No jobs match your filters",
                  ),
                );
              }

              return ListView.builder(
                padding:
                const EdgeInsets.all(16),
                itemCount: filteredJobs.length,
                itemBuilder:
                    (context, index) {
                  final job =
                  filteredJobs[index];

                  return JobCard(
                    job: job,
                    myEmail: myEmail,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// 🔥 FILTER BOTTOM SHEET
  void _openFilterSheet(
      BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Filters",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              /// LOCATION
              DropdownButtonFormField<String>(
                initialValue: selectedLocation,
                decoration:
                const InputDecoration(
                  labelText: "Location",
                  border:
                  OutlineInputBorder(),
                ),
                items: [
                  "All",
                  "Ahmedabad",
                  "Remote",
                  "Mumbai",
                ]
                    .map(
                      (e) =>
                      DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedLocation =
                        value;
                  });
                },
              ),

              const SizedBox(height: 15),

              /// SALARY
              DropdownButtonFormField<String>(
                initialValue: selectedSalary,
                decoration:
                const InputDecoration(
                  labelText: "Salary (LPA)",
                  border:
                  OutlineInputBorder(),
                ),
                items: SalaryHelper.filterOptions
                    .map(
                      (e) =>
                      DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedSalary = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              /// APPLY BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child:
                  const Text("Apply Filters"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ================= PROFILE LIST =================
class ProfileList extends StatelessWidget {
  final String title;

  const ProfileList({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ProfileCard(
          name: "Alex Thompson",
          role: "Software Engineer",
        ),
        ProfileCard(
          name: "Jessica Martinez",
          role: "Product Manager",
        ),
      ],
    );
  }
}

/// ================= PROFILE CARD =================
class ProfileCard extends StatelessWidget {
  final String name;
  final String role;

  const ProfileCard({
    super.key,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
      const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor:
            Color(0xFFE0E7FF),
            child: Icon(
              Icons.person,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
        ],
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