import 'package:flutter/material.dart';
import 'alumni_home_screen.dart' show EventList, EventListState, ProfileList, JobList, MyActivityPage;

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => FacultyDashboardState();
}

class FacultyDashboardState extends State<FacultyDashboard> {
  final GlobalKey<EventListState> _eventListKey = GlobalKey<EventListState>();

  void refreshData() {
    _eventListKey.currentState?.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: AppBar(
          automaticallyImplyLeading: false,
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
                  "FACULTY",
                  style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
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
        ),
        body: TabBarView(
          children: [
            EventList(key: _eventListKey),
            const JobList(),
            const MyActivityPage(showPosts: false),
            const ProfileList(role: "ALUMNI"),
            const ProfileList(role: "FACULTY"),
          ],
        ),
      ),
    );
  }
}