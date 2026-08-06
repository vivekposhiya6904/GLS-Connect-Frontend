import 'package:flutter/material.dart';

import '../notification/notification_screen.dart';
import '../search/search_screen.dart';
import '../../services/job_service.dart';
import '../../models/job_model.dart';
import '../../utils/storage_service.dart';
import '../chat/chat_detail_screen.dart';
import '../../models/event_model.dart';
import '../../models/post_model.dart';
import '../../models/alumni_profile_model.dart';
import '../../models/faculty_profile_model.dart';
import '../../services/event_service.dart';
import '../../services/post_service.dart';
import '../../services/alumni_profile_service.dart';
import '../../services/faculty_profile_service.dart';
import '../../config/api_config.dart';
import '../profile/profile_detail_screen.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),

        appBar: AppBar(
          backgroundColor: const Color(0xFF1A3A8F),
          elevation: 2,
          title: Row(
            children: [
              const Icon(Icons.school_rounded, color: Colors.amber, size: 26),
              const SizedBox(width: 10),
              const Text(
                "GLS Connect",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
                  "ALUMNI",
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
              Tab(text: "All", icon: Icon(Icons.dynamic_feed_rounded, size: 18)),
              Tab(text: "Jobs", icon: Icon(Icons.work_rounded, size: 18)),
              Tab(text: "My Activity", icon: Icon(Icons.history_rounded, size: 18)),
              Tab(text: "Alumni", icon: Icon(Icons.people_alt_rounded, size: 18)),
              Tab(text: "Faculty", icon: Icon(Icons.badge_rounded, size: 18)),
            ],
          ),

          actions: [
            FutureBuilder<int>(
              future: NotificationService.getUnreadCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
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
                        ).then((_) {
                          setState(() {});
                        });
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Color(0xFF1A3A8F),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 5),
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white),
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
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final normalizedToday = DateTime(today.year, today.month, today.day);
      final diffDays = normalizedToday.difference(normalizedDate).inDays;
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
      future: Future.wait([eventsFuture, jobsFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        final results = snapshot.data ?? [];
        final events = results.isNotEmpty ? (results[0] as List<EventModel>?) ?? [] : <EventModel>[];
        final jobs = results.length > 1 ? (results[1] as List<JobModel>?) ?? [] : <JobModel>[];

        final filteredEvents = events.where((e) => _isExpired(e.eventDate) == _showPast).toList();
        final filteredJobs = jobs.where((j) => _isExpired(j.lastDateToApply) == _showPast).toList();

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
                  icon: Icon(_showPast ? Icons.feed_outlined : Icons.history_toggle_off, size: 16),
                  label: Text(_showPast ? "Show Active" : "Previous Ends"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showPast ? Colors.amber.shade700 : const Color(0xFF1A3A8F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// 📅 EVENTS
            Text(
              _showPast ? "Past Events (Expired)" : "Upcoming Events",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            
            if (filteredEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No events in this category.", style: TextStyle(color: Colors.grey)),
              )
            else
              ...filteredEvents.map((event) {
                final imgUrl = event.imageUrl != null && event.imageUrl!.isNotEmpty
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
              }).toList(),

            const SizedBox(height: 20),

            /// 💼 ACTIVE JOB POSTINGS
            Text(
              _showPast ? "Past Job Openings (Expired)" : "Latest Job Openings",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            if (filteredJobs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("No jobs in this category.", style: TextStyle(color: Colors.grey)),
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
              }).toList(),
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
class MyActivityPage extends StatefulWidget {
  const MyActivityPage({super.key});

  @override
  State<MyActivityPage> createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage> {
  late Future<List<JobModel>?> myJobsFuture;
  late Future<List<EventModel>?> myEventsFuture;
  late Future<List<PostModel>?> myPostsFuture;
  String myEmail = "";

  @override
  void initState() {
    super.initState();
    myEventsFuture = EventService.getMyEvents();
    myPostsFuture = PostService.getMyPosts();
    myJobsFuture = _loadMyJobs();
  }

  Future<List<JobModel>?> _loadMyJobs() async {
    final email = await StorageService.getUserEmail();
    myEmail = email ?? "";
    final allJobs = await JobService.getAllJobs();
    if (allJobs == null) return null;
    return allJobs.where((j) => j.userEmail == myEmail).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: const TabBar(
          labelColor: Color(0xFF1A3A8F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF1A3A8F),
          tabs: [
            Tab(text: "My Jobs"),
            Tab(text: "My Events"),
            Tab(text: "My Posts"),
          ],
        ),
        body: TabBarView(
          children: [
            _buildMyJobsList(),
            _buildMyEventsList(),
            _buildMyPostsList(),
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
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("You haven't posted any jobs.", style: TextStyle(color: Colors.grey)),
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
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
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("You haven't created any events.", style: TextStyle(color: Colors.grey)),
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final imgUrl = event.imageUrl != null && event.imageUrl!.isNotEmpty
                ? "${ApiConfig.baseUrl}${event.imageUrl}"
                : "https://picsum.photos/600/300?random=${event.title}";
            return EventCard(
              title: event.title,
              date: event.eventDate,
              location: event.location,
              imageUrl: imgUrl,
              description: event.description,
              isPast: false,
            );
          },
        );
      },
    );
  }

  Widget _buildMyPostsList() {
    return FutureBuilder<List<PostModel>?>(
      future: myPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("You haven't shared any posts.", style: TextStyle(color: Colors.grey)),
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(post.createdAt?.split('T').first ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    if (post.id != null) {
                      final success = await PostService.deletePost(post.id!);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Post deleted")),
                        );
                        setState(() {
                          myPostsFuture = PostService.getMyPosts();
                        });
                      }
                    }
                  },
                ),
              ),
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
    return const ProfileList(role: "ALUMNI");
  }
}

class FacultyPage extends StatelessWidget {
  const FacultyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileList(role: "FACULTY");
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
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A8F).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageZoomScreen(imageUrl: imageUrl, tag: title),
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
                      errorBuilder: (context, error, stackTrace) => Image.network(
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3A8F).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                if (targetDepartment != null && targetDepartment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3A8F).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_outlined, size: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.shade200 : const Color(0xFF1A3A8F)),
                        const SizedBox(width: 4),
                        Text(
                          "Department: $targetDepartment",
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.shade200 : const Color(0xFF1A3A8F),
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
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2515) : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.amber.shade800 : Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.amber.shade200 : Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Note: $note",
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.amber.shade200 : Colors.amber.shade900,
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
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                ),
              ),

              const SizedBox(width: 10),

              /// FILTER BUTTON
              GestureDetector(
                onTap: () => _openFilterSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A8F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white),
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text("Failed to load jobs"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          jobsFuture = JobService.getAllJobs();
                        }),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                );
              }

              final jobs = snapshot.data ?? [];

              if (jobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("No jobs available"),
                    ],
                  ),
                );
              }

              // Filter jobs
              final filteredJobs = jobs.where((job) {
                final matchesSearch =
                    job.jobTitle.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        job.companyName.toLowerCase().contains(searchQuery.toLowerCase());

                final matchesLocation =
                    selectedLocation == "All" || job.location == selectedLocation;

                final matchesSalary =
                    selectedSalary == "All" || job.salary == selectedSalary;

                return matchesSearch && matchesLocation && matchesSalary;
              }).toList();

              if (filteredJobs.isEmpty) {
                return const Center(
                  child: Text("No jobs match your filters"),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = filteredJobs[index];

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
                },
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
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "Filters",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              /// LOCATION
              DropdownButtonFormField<String>(
                initialValue: selectedLocation,
                decoration: const InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
                items: ["All", "Ahmedabad", "Remote", "Mumbai"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedLocation = value!);
                },
              ),

              const SizedBox(height: 15),

              /// SALARY
              DropdownButtonFormField<String>(
                initialValue: selectedSalary,
                decoration: const InputDecoration(
                  labelText: "Salary",
                  border: OutlineInputBorder(),
                ),
                items: ["All", "20k-35k", "25k-40k", "30k-50k"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedSalary = value!);
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
                  child: const Text("Apply Filters"),
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
    final showChatIcon = postedByEmail.isNotEmpty && postedByEmail != myEmail;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A8F).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Work Icon + Title & Company
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A8F).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.work_outline,
                    color: Color(0xFF1A3A8F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        style: const TextStyle(
                          color: Color(0xFF1A3A8F),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chips for Job Type
                if (jobType != null && jobType!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      jobType!,
                      style: TextStyle(
                        color: Colors.indigo.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Metadata Row: Location, Salary, Deadline
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(location, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontSize: 13)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_rupee_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(salary, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontSize: 13)),
                  ],
                ),
                if (joiningType != null && joiningType!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Joining: $joiningType", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontSize: 13)),
                    ],
                  ),
                if (lastDateToApply != null && lastDateToApply!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Text(
                        "Apply by: $lastDateToApply",
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
            ),

            // Rich Details: Description, Skills, Experience
            if (jobDescription != null && jobDescription!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                "Job Description",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                jobDescription!,
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontSize: 13, height: 1.4),
              ),
            ],

            if (skillsRequired != null && skillsRequired!.isNotEmpty && skillsRequired != "N/A") ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Skills: ",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                  ),
                  Expanded(
                    child: Text(
                      skillsRequired!,
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],

            if (experienceRequired != null && experienceRequired!.isNotEmpty && experienceRequired != "N/A") ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    "Experience: ",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                  ),
                  Text(
                    experienceRequired!,
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ],

            // Apply channels
            if ((companyLink != null && companyLink!.isNotEmpty) ||
                (companyEmail != null && companyEmail!.isNotEmpty)) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    if (companyLink != null && companyLink!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.link, size: 16, color: Color(0xFF1A3A8F)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                companyLink!,
                                style: const TextStyle(
                                  color: Color(0xFF1A3A8F),
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (companyEmail != null && companyEmail!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.mail_outline, size: 16, color: Colors.black54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Send Resume: ${companyEmail!}",
                              style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],

            // Footer: Posted by details & Chat Shortcut
            if (postedByName.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFF0F4FF),
                          child: Icon(Icons.person, size: 16, color: Color(0xFF1A3A8F)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Posted by: $postedByName",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (posterDepartment != null && posterDepartment!.isNotEmpty && posterDepartment != "N/A")
                                Text(
                                  "${posterDepartment!}${posterBatchYear != null && posterBatchYear!.isNotEmpty && posterBatchYear != "N/A" ? ' • $posterBatchYear' : ''}",
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showChatIcon)
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1A3A8F), size: 20),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              name: postedByName,
                              receiverEmail: postedByEmail,
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
class ProfileList extends StatefulWidget {
  final String role;

  const ProfileList({super.key, required this.role});

  @override
  State<ProfileList> createState() => _ProfileListState();
}

class _ProfileListState extends State<ProfileList> {
  late Future<List<dynamic>?> _profilesFuture;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    if (widget.role == "ALUMNI") {
      _profilesFuture = AlumniProfileService.getAllAlumniProfiles();
    } else {
      _profilesFuture = FacultyProfileService.getAllFacultyProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search ${widget.role.toLowerCase()}...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>?>(
            future: _profilesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text("Error loading directory"));
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Center(child: Text("No profiles found."));
              }

              final filtered = list.where((p) {
                if (widget.role == "ALUMNI") {
                  final alumni = p as AlumniProfileModel;
                  final isFilled = (alumni.degree != null && alumni.degree!.isNotEmpty) ||
                                   (alumni.companyName != null && alumni.companyName!.isNotEmpty) ||
                                   (alumni.designation != null && alumni.designation!.isNotEmpty) ||
                                   (alumni.department != null && alumni.department!.isNotEmpty) ||
                                   (alumni.batchYear != null && alumni.batchYear! > 0);
                  if (!isFilled) return false;

                  final name = alumni.userName ?? "";
                  return name.toLowerCase().contains(_searchQuery);
                } else {
                  final faculty = p as FacultyProfileModel;
                  final isFilled = (faculty.department != null && faculty.department!.isNotEmpty) ||
                                   (faculty.designation != null && faculty.designation!.isNotEmpty) ||
                                   (faculty.qualification != null && faculty.qualification!.isNotEmpty) ||
                                   (faculty.specialization != null && faculty.specialization!.isNotEmpty) ||
                                   (faculty.experienceYears != null && faculty.experienceYears! > 0);
                  if (!isFilled) return false;

                  final name = faculty.userName ?? "";
                  return name.toLowerCase().contains(_searchQuery);
                }
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text("No profiles match your search"));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final p = filtered[index];
                  String name = "";
                  String subtitle = "";
                  int userId = 0;
                  String? profilePic;

                  if (widget.role == "ALUMNI") {
                    final alumni = p as AlumniProfileModel;
                    name = alumni.userName ?? "Alumni Member";
                    subtitle = "${alumni.designation ?? 'Graduate'} at ${alumni.companyName ?? 'GLS'}";
                    userId = alumni.userId ?? 0;
                    profilePic = alumni.profilePictureUrl;
                  } else {
                    final faculty = p as FacultyProfileModel;
                    name = faculty.userName ?? "Faculty Member";
                    subtitle = "${faculty.designation ?? 'Professor'} • ${faculty.department ?? 'GLS'}";
                    userId = faculty.userId ?? 0;
                    profilePic = faculty.profilePictureUrl;
                  }

                  return ProfileCard(
                    name: name,
                    role: subtitle,
                    userId: userId,
                    userRole: widget.role,
                    profilePictureUrl: profilePic,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  final int userId;
  final String userRole;
  final String? profilePictureUrl;

  const ProfileCard({
    super.key,
    required this.name,
    required this.role,
    required this.userId,
    required this.userRole,
    this.profilePictureUrl,
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
            color: const Color(0xFF1A3A8F).withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFE0E7FF),
          backgroundImage: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
              ? NetworkImage("${ApiConfig.baseUrl}$profilePictureUrl")
              : null,
          child: profilePictureUrl == null || profilePictureUrl!.isEmpty
              ? const Icon(Icons.person, color: Colors.indigo)
              : null,
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          role,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        onTap: () {
          if (userId > 0) {
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
        },
      ),
    );
  }
}

class ImageZoomScreen extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const ImageZoomScreen({super.key, required this.imageUrl, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: tag,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.network(
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
                padding: const EdgeInsets.all(16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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