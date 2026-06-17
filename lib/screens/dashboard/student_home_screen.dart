import 'package:flutter/material.dart';

import '../notification/notification_screen.dart';
import '../search/search_screen.dart';
import '../../services/job_service.dart';
import '../../models/job_model.dart';

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
              icon: const Icon(Icons.notifications_none, color: Colors.black),
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
              icon: const Icon(Icons.search, color: Colors.black),
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
class AllPage extends StatelessWidget {
  const AllPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [

        /// EVENTS
        EventCard(
          title: "Alumni Meet 2023",
          date: "May 15, 2023",
          location: "Campus Auditorium",
          isPast: false,
        ),

        EventCard(
          title: "Networking Night",
          date: "April 05, 2023",
          location: "Alumni Hall",
          isPast: true,
        ),

        /// JOBS
        JobCard(
          title: "Flutter Developer",
          company: "Tech Solutions Pvt Ltd",
          location: "Ahmedabad",
          salary: "₹25,000 - ₹40,000",
        ),

        JobCard(
          title: "Backend Developer",
          company: "InnovateX",
          location: "Remote",
          salary: "₹30,000 - ₹50,000",
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
    return const ProfileList(title: "Alumni Directory");
  }
}

/// ================= FACULTY =================
class FacultyPage extends StatelessWidget {
  const FacultyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileList(title: "Faculty Members");
  }
}

/// ================= EVENT CARD =================
class EventCard extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final bool isPast;

  const EventCard({
    super.key,
    required this.title,
    required this.date,
    required this.location,
    required this.isPast,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                Image.network(
                  "https://picsum.photos/600/300?random=$title",
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (isPast)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
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

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
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

  @override
  void initState() {
    super.initState();
    jobsFuture = JobService.getAllJobs();
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
                    photoUrl: job.photoUrl,
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
  final String? photoUrl;

  const JobCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    this.photoUrl,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(18)),
            child: _buildImage(),
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

                const SizedBox(height: 8),

                Text(
                  company,
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.currency_rupee,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      salary,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build image with proper error handling
  Widget _buildImage() {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
      );
    }

    return Image.network(
      photoUrl!,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 180,
          width: double.infinity,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 180,
          width: double.infinity,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

/// ================= PROFILE LIST =================
class ProfileList extends StatelessWidget {
  final String title;

  const ProfileList({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ProfileCard(name: "Alex Thompson", role: "Software Engineer"),
        ProfileCard(name: "Jessica Martinez", role: "Product Manager"),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFE0E7FF),
            child: Icon(Icons.person, color: Colors.indigo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}