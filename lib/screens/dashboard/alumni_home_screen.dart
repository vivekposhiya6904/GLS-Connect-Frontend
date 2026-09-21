import 'package:flutter/material.dart';

import '../notification/notification_screen.dart';
import '../search/search_screen.dart';
import '../../services/job_service.dart';
import '../../models/job_model.dart';
import '../../utils/storage_service.dart';
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
import '../../widgets/event_card.dart';
import '../../widgets/job_card.dart';
import '../../utils/date_helper.dart';

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
              Tab(text: "Events", icon: Icon(Icons.event_rounded, size: 18)),
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
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EventList();
  }
}

class EventList extends StatefulWidget {
  const EventList({super.key});

  @override
  State<EventList> createState() => EventListState();
}

class EventListState extends State<EventList> {
  late Future<List<EventModel>?> eventsFuture;
  String searchQuery = "";
  String selectedDepartment = "All";
  bool showPast = false;
  String myEmail = "";

  @override
  void initState() {
    super.initState();
    refreshData();
    loadMyEmail();
  }

  void refreshData() {
    if (mounted) {
      setState(() {
        eventsFuture = EventService.getAllEvents();
      });
    }
  }

  Future<void> loadMyEmail() async {
    final email = await StorageService.getUserEmail();
    if (mounted) {
      setState(() {
        myEmail = email ?? "";
      });
    }
  }

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
                        "Filter Events",
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
                  const Text("Department", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedDepartment,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: ["All", "Computer Science", "Information Technology", "Business Administration", "Commerce", "Computer Applications"]
                        .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedDepartment = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Show Past Events", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Switch(
                        value: showPast,
                        onChanged: (val) => setSheetState(() => showPast = val),
                        activeColor: const Color(0xFF1A3A8F),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                    hintText: "Search events...",
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

        /// EVENT LIST
        Expanded(
          child: FutureBuilder<List<EventModel>?>(
            future: eventsFuture,
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
                      const Text("Failed to load events"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          eventsFuture = EventService.getAllEvents();
                        }),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                );
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No events available"),
                    ],
                  ),
                );
              }

              final filteredEvents = events.where((event) {
                final matchesSearch = event.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                    event.location.toLowerCase().contains(searchQuery.toLowerCase()) ||
                    event.description.toLowerCase().contains(searchQuery.toLowerCase());

                final matchesDepartment = selectedDepartment == "All" ||
                    (event.targetDepartment != null && event.targetDepartment == selectedDepartment);

                final isExpired = DateHelper.isExpired(event.eventDate);
                final matchesPast = showPast ? true : !isExpired;

                return matchesSearch && matchesDepartment && matchesPast;
              }).toList();

              if (filteredEvents.isEmpty) {
                return const Center(
                  child: Text("No events match your filters"),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    eventsFuture = EventService.getAllEvents();
                  });
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return EventCard(
                      event: event,
                      myEmail: myEmail,
                      onRefresh: () {
                        setState(() {
                          eventsFuture = EventService.getAllEvents();
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
  final bool showPosts;
  const MyActivityPage({super.key, this.showPosts = true});

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
    if (widget.showPosts) {
      myPostsFuture = PostService.getMyPosts();
    }
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
      length: widget.showPosts ? 3 : 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: TabBar(
          labelColor: const Color(0xFF1A3A8F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1A3A8F),
          tabs: [
            const Tab(text: "My Jobs"),
            const Tab(text: "My Events"),
            if (widget.showPosts) const Tab(text: "My Posts"),
          ],
        ),
        body: TabBarView(
          children: [
            _buildMyJobsList(),
            _buildMyEventsList(),
            if (widget.showPosts) _buildMyPostsList(),
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
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 52, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No Job Posts Yet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  SizedBox(height: 6),
                  Text("Jobs you post will appear here.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
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
              onRefresh: () {
                setState(() {
                  myJobsFuture = JobService.getMyJobs();
                });
              },
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
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note_outlined, size: 52, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No Events Created Yet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  SizedBox(height: 6),
                  Text("Events you create will appear here.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
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
              onRefresh: () {
                setState(() {
                  myEventsFuture = EventService.getMyEvents();
                });
              },
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dynamic_feed_outlined, size: 52, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No Posts Shared Yet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  SizedBox(height: 6),
                  Text("Posts you share will appear here.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          );
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
                    items: ["All", "Ahmedabad", "Remote", "Mumbai", "Bangalore", "Delhi", "Pune"]
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
                      labelText: "Salary",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: ["All", "20k-35k", "25k-40k", "30k-50k"]
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
              ? NetworkImage(profilePictureUrl!.startsWith("http")
                  ? profilePictureUrl!
                  : "${ApiConfig.baseUrl}$profilePictureUrl")
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