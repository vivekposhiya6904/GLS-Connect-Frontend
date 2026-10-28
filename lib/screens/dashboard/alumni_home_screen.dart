import 'package:flutter/material.dart';

import '../notification/notification_screen.dart';
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
import '../../widgets/profile_avatar.dart';
import '../profile/profile_detail_screen.dart';
import '../../services/notification_service.dart';
import '../../widgets/event_card.dart';
import '../../widgets/job_card.dart';
import '../../utils/date_helper.dart';
import '../../utils/city_constants.dart';
import '../../utils/salary_helper.dart';
import '../../utils/focus_helper.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/offline_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<int>? _unreadNotificationFuture;

  @override
  void initState() {
    super.initState();
    _unreadNotificationFuture = NotificationService.getUnreadCount();
  }

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
              const Icon(Icons.school_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  "GLS Connect",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
                  "ALUMNI",
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
            isScrollable: true,
            tabAlignment: TabAlignment.center,
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
              future: _unreadNotificationFuture,
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
            const SizedBox(width: 8),
          ],
        ),

        body: const TabBarView(
          children: [
            EventsPage(),
            JobsPage(),
            MyActivityPage(showPosts: false),
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String selectedDepartment = "All";
  bool showPast = false;
  String myEmail = "";
  bool _isOffline = false;
  String? _cacheTimeAgo;
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    eventsFuture = _loadEvents();
    loadMyEmail();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void refreshData() {
    if (mounted) {
      setState(() {
        eventsFuture = _loadEvents();
      });
    }
  }

  Future<List<EventModel>?> _loadEvents() async {
    // 1. Check local cache first
    final cached = await EventService.getCachedAllEvents();
    if (cached != null) {
      _isFromCache = true;
      _isOffline = false;
      _cacheTimeAgo = cached.timeAgoFormatted;
      // Start background refresh
      _refreshInBackground();
      return cached.data;
    }

    // 2. No cache, fetch from network
    try {
      final fresh = await EventService.getAllEvents();
      _isFromCache = false;
      _isOffline = false;
      _cacheTimeAgo = null;
      return fresh;
    } catch (_) {
      final fallback = await EventService.getCachedAllEvents();
      if (fallback != null) {
        _isFromCache = true;
        _isOffline = true;
        _cacheTimeAgo = fallback.timeAgoFormatted;
        return fallback.data;
      }
      return null;
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final fresh = await EventService.getAllEvents();
      if (fresh != null && mounted) {
        setState(() {
          _isFromCache = false;
          _isOffline = false;
          _cacheTimeAgo = null;
          eventsFuture = Future.value(fresh);
        });
      } else if (fresh == null && mounted) {
        setState(() {
          _isOffline = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
      }
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
                  hintText: "Search events by title, department or venue...",
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                  onClear: () {
                    setState(() => searchQuery = "");
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

        if (_isOffline && _isFromCache)
          OfflineIndicatorBanner(
            timeAgo: _cacheTimeAgo,
            onRetry: refreshData,
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
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              const Text("Failed to load events"),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: refreshData,
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("No events available"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final filteredEvents = events.where((event) {
                final query = searchQuery.trim().toLowerCase();
                final matchesSearch = query.isEmpty ||
                    event.title.toLowerCase().contains(query) ||
                    event.location.toLowerCase().contains(query) ||
                    event.description.toLowerCase().contains(query) ||
                    (event.targetDepartment != null && event.targetDepartment!.toLowerCase().contains(query));

                final matchesDepartment = selectedDepartment == "All" ||
                    (event.targetDepartment != null && event.targetDepartment == selectedDepartment);

                final isExpired = DateHelper.isExpired(event.eventDate);
                final matchesPast = showPast ? true : !isExpired;

                return matchesSearch && matchesDepartment && matchesPast;
              }).toList();

              if (filteredEvents.isEmpty) {
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
                                "No events match your search or filters",
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
                                    selectedDepartment = "All";
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
                  refreshData();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return EventCard(
                      event: event,
                      myEmail: myEmail,
                      onRefresh: refreshData,
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
  const MyActivityPage({super.key, this.showPosts = false});

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
    myEventsFuture = _loadMyEvents();
    if (widget.showPosts) {
      myPostsFuture = PostService.getMyPosts();
    }
    myJobsFuture = _loadMyJobs();
  }

  Future<List<JobModel>?> _loadMyJobs() async {
    final email = await StorageService.getUserEmail();
    myEmail = email ?? "";
    final cached = await JobService.getCachedMyJobs();
    if (cached != null) {
      _refreshMyJobsInBackground();
      return cached.data;
    }
    return JobService.getMyJobs();
  }

  Future<void> _refreshMyJobsInBackground() async {
    try {
      final fresh = await JobService.getMyJobs();
      if (fresh != null && mounted) {
        setState(() {
          myJobsFuture = Future.value(fresh);
        });
      }
    } catch (_) {}
  }

  Future<List<EventModel>?> _loadMyEvents() async {
    final cached = await EventService.getCachedMyEvents();
    if (cached != null) {
      _refreshMyEventsInBackground();
      return cached.data;
    }
    return EventService.getMyEvents();
  }

  Future<void> _refreshMyEventsInBackground() async {
    try {
      final fresh = await EventService.getMyEvents();
      if (fresh != null && mounted) {
        setState(() {
          myEventsFuture = Future.value(fresh);
        });
      }
    } catch (_) {}
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
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                ),
              ),
            ),
          );
        }
        return ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                ),
              ),
            ),
          );
        }
        return ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                ),
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String selectedLocation = "All";
  String selectedSalary = "All";
  bool showPast = false;
  String myEmail = "";
  bool _isOffline = false;
  String? _cacheTimeAgo;
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    jobsFuture = _loadJobs();
    loadMyEmail();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void refreshData() {
    if (mounted) {
      setState(() {
        jobsFuture = _loadJobs();
      });
    }
  }

  Future<List<JobModel>?> _loadJobs() async {
    // 1. Check local cache first
    final cached = await JobService.getCachedAllJobs();
    if (cached != null) {
      _isFromCache = true;
      _isOffline = false;
      _cacheTimeAgo = cached.timeAgoFormatted;
      // Start background refresh
      _refreshInBackground();
      return cached.data;
    }

    // 2. No cache, fetch from network
    try {
      final fresh = await JobService.getAllJobs();
      _isFromCache = false;
      _isOffline = false;
      _cacheTimeAgo = null;
      return fresh;
    } catch (_) {
      final fallback = await JobService.getCachedAllJobs();
      if (fallback != null) {
        _isFromCache = true;
        _isOffline = true;
        _cacheTimeAgo = fallback.timeAgoFormatted;
        return fallback.data;
      }
      return null;
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final fresh = await JobService.getAllJobs();
      if (fresh != null && mounted) {
        setState(() {
          _isFromCache = false;
          _isOffline = false;
          _cacheTimeAgo = null;
          jobsFuture = Future.value(fresh);
        });
      } else if (fresh == null && mounted) {
        setState(() {
          _isOffline = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
      }
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
                    setState(() => searchQuery = value);
                  },
                  onClear: () {
                    setState(() => searchQuery = "");
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

        if (_isOffline && _isFromCache)
          OfflineIndicatorBanner(
            timeAgo: _cacheTimeAgo,
            onRetry: refreshData,
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
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              const Text("Failed to load jobs"),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: refreshData,
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
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
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.work_outline, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("No jobs available"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Filter jobs
              final filteredJobs = jobs.where((job) {
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

                final matchesSalary =
                    SalaryHelper.matchesFilter(job.salary, selectedSalary);

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
                  refreshData();
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
                      onRefresh: refreshData,
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
  final String role;

  const ProfileList({super.key, required this.role});

  @override
  State<ProfileList> createState() => _ProfileListState();
}

class _ProfileListState extends State<ProfileList> {
  late Future<List<dynamic>?> _profilesFuture;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
    if (widget.role == "ALUMNI") {
      _profilesFuture = AlumniProfileService.getAllAlumniProfiles();
    } else {
      _profilesFuture = FacultyProfileService.getAllFacultyProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = widget.role == "ALUMNI" ? "Alumni" : "Faculty";

    return Column(
      children: [
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
        Expanded(
          child: FutureBuilder<List<dynamic>?>(
            future: _profilesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: const Center(child: Text("Error loading directory")),
                    ),
                  ),
                );
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(child: Text("No $roleLabel profiles found.")),
                    ),
                  ),
                );
              }

              final filtered = list.where((p) {
                if (_searchQuery.isEmpty) return true;

                if (widget.role == "ALUMNI") {
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

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _loadProfiles();
                  });
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                ),
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
        leading: ProfileAvatar(
          imageUrl: profilePictureUrl,
          name: name,
          radius: 22,
          backgroundColor: const Color(0xFFE0E7FF),
          foregroundColor: Colors.indigo,
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