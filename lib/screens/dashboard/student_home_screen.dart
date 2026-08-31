import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../models/event_model.dart';
import '../../models/job_model.dart';
import '../../services/event_service.dart';
import '../../services/job_service.dart';
import '../../utils/storage_service.dart';
import '../chat/chat_detail_screen.dart';
import '../notification/notification_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "GLS Connect",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "All"),
              Tab(text: "Jobs"),
              Tab(text: "My Activity"),
              Tab(text: "Alumni"),
              Tab(text: "Faculty"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.black,
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
                Icons.search,
                color: Colors.black,
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
            AllPage(),
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

/// ================= ALL (EVENTS + JOBS) =================
class AllPage extends StatefulWidget {
  const AllPage({super.key});

  @override
  State<AllPage> createState() => _AllPageState();
}

class _AllPageState extends State<AllPage> {
  late Future<List<JobModel>?> jobsFuture;
  late Future<List<EventModel>?> eventsFuture;

  String myEmail = "";
  bool _showPast = false;

  bool _isExpired(String dateStr) {
    try {
      if (dateStr.isEmpty) return false;

      final date = DateTime.parse(dateStr);
      final today = DateTime.now();

      final normalizedDate = DateTime(
        date.year,
        date.month,
        date.day,
      );

      final normalizedToday = DateTime(
        today.year,
        today.month,
        today.day,
      );

      final diffDays =
          normalizedToday.difference(normalizedDate).inDays;

      return diffDays > 3;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    jobsFuture = JobService.getAllJobs();
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
    return FutureBuilder<List<dynamic>?>(
      future: Future.wait([
        eventsFuture,
        jobsFuture,
      ]),
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
                    "Failed to load feed",
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

        final results = snapshot.data ?? [];

        final events = results.isNotEmpty
            ? (results[0] as List<EventModel>?) ?? <EventModel>[]
            : <EventModel>[];

        final jobs = results.length > 1
            ? (results[1] as List<JobModel>?) ?? <JobModel>[]
            : <JobModel>[];

        final filteredEvents = events
            .where(
              (event) =>
          _isExpired(event.eventDate) == _showPast,
        )
            .toList();

        final filteredJobs = jobs
            .where(
              (job) =>
          _isExpired(job.lastDateToApply) == _showPast,
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

            /// 📅 EVENTS
            Text(
              _showPast
                  ? "Past Events (Expired)"
                  : "Upcoming Events",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            if (filteredEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No events scheduled.",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              )
            else
              ...filteredEvents.map((event) {
                final imgUrl =
                event.imageUrl != null &&
                    event.imageUrl!.isNotEmpty
                    ? "${ApiConfig.baseUrl}${event.imageUrl}"
                    : "https://picsum.photos/600/300?random=${event.title}";

                return EventCard(
                  title: event.title,
                  date: event.eventDate,
                  location: event.location,
                  imageUrl: imgUrl,
                  description: event.description,
                  isPast: _showPast,
                  targetDepartment: event.targetDepartment,
                  note: event.note,
                );
              }),

            const SizedBox(height: 20),

            /// 💼 JOB POSTINGS
            Text(
              _showPast
                  ? "Past Job Openings (Expired)"
                  : "Latest Job Openings",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            if (filteredJobs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "No jobs available in this category.",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ...filteredJobs.map((job) {
                return JobCard(
                  title: job.jobTitle,
                  company: job.companyName,
                  location: job.location,
                  salary: job.salary,
                  postedByName: job.userName,
                  postedByEmail: job.userEmail,
                  myEmail: myEmail,
                  companyLink: job.companyLink,
                  companyEmail: job.companyEmail,
                  posterDepartment: job.posterDepartment,
                  posterBatchYear: job.posterBatchYear,
                  jobDescription: job.jobDescription,
                  skillsRequired: job.skillsRequired,
                  experienceRequired: job.experienceRequired,
                  joiningType: job.joiningType,
                  jobType: job.jobType,
                  lastDateToApply: job.lastDateToApply,
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

/// ================= MY ACTIVITY =================
class MyActivityPage extends StatelessWidget {
  const MyActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        /// EVENT STATUS
        EventCard(
          title: "Alumni Meet 2023",
          date: "May 15, 2023",
          location: "Campus Auditorium",
          imageUrl:
          "https://picsum.photos/600/300?random=1",
          description:
          "An annual meeting for all alumni to gather and connect.",
          isPast: false,
        ),

        /// JOB APPLICATION STATUS
        JobCard(
          title: "Flutter Developer",
          company: "Tech Solutions Pvt Ltd",
          location: "Ahmedabad",
          salary: "Applied",
        ),

        JobCard(
          title: "Backend Developer",
          company: "InnovateX",
          location: "Remote",
          salary: "Shortlisted",
        ),
      ],
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

/// ================= EVENT CARD =================
class EventCard extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final String imageUrl;
  final String description;
  final bool isPast;
  final String? targetDepartment;
  final String? note;

  const EventCard({
    super.key,
    required this.title,
    required this.date,
    required this.location,
    required this.imageUrl,
    required this.description,
    required this.isPast,
    this.targetDepartment,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A8F).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ImageZoomScreen(
                              imageUrl: imageUrl,
                              tag: title,
                            ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: title,
                    child: Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                          Image.network(
                            "https://picsum.photos/600/300?random=$title",
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                    ),
                  ),
                ),
                if (isPast)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3A8F)
                            .withValues(alpha: 0.7),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "PAST",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                if (targetDepartment != null &&
                    targetDepartment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3A8F)
                          .withValues(alpha: 0.08),
                      borderRadius:
                      BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 12,
                          color: Color(0xFF1A3A8F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Department: $targetDepartment",
                          style: const TextStyle(
                            color: Color(0xFF1A3A8F),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius:
                      BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Note: $note",
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
                        "No jobs available",
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

                final matchesSalary =
                    selectedSalary == "All" ||
                        job.salary ==
                            selectedSalary;

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
                    title: job.jobTitle,
                    company: job.companyName,
                    location: job.location,
                    salary: job.salary,
                    postedByName:
                    job.userName,
                    postedByEmail:
                    job.userEmail,
                    myEmail: myEmail,
                    companyLink:
                    job.companyLink,
                    companyEmail:
                    job.companyEmail,
                    posterDepartment:
                    job.posterDepartment,
                    posterBatchYear:
                    job.posterBatchYear,
                    jobDescription:
                    job.jobDescription,
                    skillsRequired:
                    job.skillsRequired,
                    experienceRequired:
                    job.experienceRequired,
                    joiningType:
                    job.joiningType,
                    jobType: job.jobType,
                    lastDateToApply:
                    job.lastDateToApply,
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
                  labelText: "Salary",
                  border:
                  OutlineInputBorder(),
                ),
                items: [
                  "All",
                  "20k-35k",
                  "25k-40k",
                  "30k-50k",
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

/// ================= JOB CARD =================
class JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String salary;

  final String postedByName;
  final String postedByEmail;
  final String myEmail;

  final String? companyLink;
  final String? companyEmail;
  final String? posterDepartment;
  final String? posterBatchYear;
  final String? jobDescription;
  final String? skillsRequired;
  final String? experienceRequired;
  final String? joiningType;
  final String? jobType;
  final String? lastDateToApply;

  const JobCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    this.postedByName = "",
    this.postedByEmail = "",
    this.myEmail = "",
    this.companyLink,
    this.companyEmail,
    this.posterDepartment,
    this.posterBatchYear,
    this.jobDescription,
    this.skillsRequired,
    this.experienceRequired,
    this.joiningType,
    this.jobType,
    this.lastDateToApply,
  });

  @override
  Widget build(BuildContext context) {
    final showChatIcon =
        postedByEmail.isNotEmpty &&
            postedByEmail != myEmail;

    return Container(
      margin:
      const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A8F)
                .withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF1A3A8F,
                    ).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.work_outline,
                    color:
                    Color(0xFF1A3A8F),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 16,
                          color:
                          Colors.black87,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        company,
                        style:
                        const TextStyle(
                          color:
                          Color(0xFF1A3A8F),
                          fontSize: 14,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (jobType != null &&
                    jobType!.isNotEmpty)
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.indigo.shade50,
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Text(
                      jobType!,
                      style: TextStyle(
                        color:
                        Colors.indigo.shade700,
                        fontSize: 11,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Metadata
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style:
                      const TextStyle(
                        color:
                        Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.currency_rupee_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      salary,
                      style:
                      const TextStyle(
                        color:
                        Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                if (joiningType != null &&
                    joiningType!.isNotEmpty)
                  Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.flash_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        "Joining: $joiningType",
                        style:
                        const TextStyle(
                          color:
                          Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                if (lastDateToApply != null &&
                    lastDateToApply!
                        .isNotEmpty)
                  Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons
                            .calendar_today_outlined,
                        size: 14,
                        color:
                        Colors.redAccent,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Text(
                        "Apply by: $lastDateToApply",
                        style:
                        const TextStyle(
                          color:
                          Colors.redAccent,
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Job Description
            if (jobDescription != null &&
                jobDescription!.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                "Job Description",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                jobDescription!,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],

            // Skills
            if (skillsRequired != null &&
                skillsRequired!.isNotEmpty &&
                skillsRequired != "N/A") ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Skills: ",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      skillsRequired!,
                      style:
                      const TextStyle(
                        color:
                        Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Experience
            if (experienceRequired != null &&
                experienceRequired!
                    .isNotEmpty &&
                experienceRequired !=
                    "N/A") ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text(
                    "Experience: ",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    experienceRequired!,
                    style:
                    const TextStyle(
                      color:
                      Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],

            // Apply channels
            if ((companyLink != null &&
                companyLink!.isNotEmpty) ||
                (companyEmail != null &&
                    companyEmail!.isNotEmpty)) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius:
                  BorderRadius.circular(12),
                  border: Border.all(
                    color:
                    Colors.grey.shade100,
                  ),
                ),
                child: Column(
                  children: [
                    if (companyLink != null &&
                        companyLink!.isNotEmpty)
                      Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 6,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.link,
                              size: 16,
                              color:
                              Color(0xFF1A3A8F),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                companyLink!,
                                style:
                                const TextStyle(
                                  color:
                                  Color(0xFF1A3A8F),
                                  fontSize: 13,
                                  decoration:
                                  TextDecoration
                                      .underline,
                                  fontWeight:
                                  FontWeight.w500,
                                ),
                                overflow:
                                TextOverflow
                                    .ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (companyEmail != null &&
                        companyEmail!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.mail_outline,
                            size: 16,
                            color:
                            Colors.black54,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Text(
                              "Send Resume: ${companyEmail!}",
                              style:
                              const TextStyle(
                                color:
                                Colors.black87,
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w500,
                              ),
                              overflow:
                              TextOverflow
                                  .ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],

            // Footer
            if (postedByName.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor:
                          Color(0xFFF0F4FF),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color:
                            Color(0xFF1A3A8F),
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                "Posted by: $postedByName",
                                style:
                                const TextStyle(
                                  color:
                                  Colors.black87,
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                                overflow:
                                TextOverflow
                                    .ellipsis,
                              ),

                              if (posterDepartment !=
                                  null &&
                                  posterDepartment!
                                      .isNotEmpty &&
                                  posterDepartment !=
                                      "N/A")
                                Text(
                                  "${posterDepartment!}${posterBatchYear != null && posterBatchYear!.isNotEmpty && posterBatchYear != "N/A" ? ' • $posterBatchYear' : ''}",
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.black54,
                                    fontSize: 11,
                                  ),
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (showChatIcon)
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color:
                        Color(0xFF1A3A8F),
                        size: 20,
                      ),
                      constraints:
                      const BoxConstraints(),
                      padding:
                      const EdgeInsets.all(4),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatDetailScreen(
                                  name: postedByName,
                                  receiverEmail:
                                  postedByEmail,
                                ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
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