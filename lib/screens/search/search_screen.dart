import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  String query = "";
  late TabController _tabController;

  final List<Map<String, String>> events = [
    {
      "title": "Flutter Workshop",
      "date": "March 25, 2026",
      "location": "Auditorium Hall"
    },
    {
      "title": "Flutter Bootcamp",
      "date": "April 10, 2026",
      "location": "Seminar Room"
    },
    {
      "title": "Tech Conference",
      "date": "May 02, 2026",
      "location": "Main Campus"
    },
  ];

  final List<Map<String, String>> alumni = [
    {
      "name": "Alex Thompson",
      "role": "Software Engineer",
      "company": "Google",
      "experience": "4 Years"
    },
    {
      "name": "Jessica Martinez",
      "role": "Product Manager",
      "company": "Amazon",
      "experience": "6 Years"
    },
    {
      "name": "Michael Brown",
      "role": "UI Designer",
      "company": "Adobe",
      "experience": "3 Years"
    },
  ];

  final List<Map<String, String>> faculty = [
    {
      "name": "Prof. Flutter Expert",
      "role": "Head of IT Department",
      "company": "GLS University",
      "experience": "12 Years"
    },
    {
      "name": "Dr. Johnson",
      "role": "Computer Science Professor",
      "company": "GLS University",
      "experience": "15 Years"
    },
    {
      "name": "Dr. Williams",
      "role": "AI Research Lead",
      "company": "GLS University",
      "experience": "10 Years"
    },
  ];

  List filteredEvents = [];
  List filteredAlumni = [];
  List filteredFaculty = [];

  final List<String> stopWords = [
    "of",
    "the",
    "for",
    "and",
    "in",
    "on",
    "at"
  ];

  final List<String> facultyKeywords = [
    "faculty",
    "teacher",
    "prof",
    "professor",
    "dr",
    "sir",
    "madam"
  ];

  final List<String> alumniKeywords = [
    "alumni",
    "student",
    "graduate"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void performSearch(String value) {
    query = value.toLowerCase();

    List<String> words = query
        .split(" ")
        .where((word) =>
    word.isNotEmpty && !stopWords.contains(word))
        .toList();

    bool matches(String text) {
      String lower = text.toLowerCase();
      return words.any((word) => lower.contains(word));
    }

    filteredEvents = events
        .where((e) => matches(e["title"]!))
        .toList();

    filteredAlumni = alumni
        .where((a) => matches(a["name"]!))
        .toList();

    filteredFaculty = faculty
        .where((f) => matches(f["name"]!))
        .toList();

    int targetIndex = 0;

    if (facultyKeywords
        .any((k) => query.contains(k)) &&
        filteredFaculty.isNotEmpty) {
      targetIndex = 2;
    } else if (alumniKeywords
        .any((k) => query.contains(k)) &&
        filteredAlumni.isNotEmpty) {
      targetIndex = 1;
    } else if (filteredEvents.isNotEmpty) {
      targetIndex = 0;
    } else if (filteredAlumni.isNotEmpty) {
      targetIndex = 1;
    } else if (filteredFaculty.isNotEmpty) {
      targetIndex = 2;
    }

    _tabController.animateTo(targetIndex);
    setState(() {});
  }

  Widget buildEventCard(Map event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              "https://picsum.photos/600/300?random=${event["title"]}",
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event["title"],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(event["date"]!,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(event["location"]!,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildProfileCard(Map profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: NetworkImage(
                "https://i.pravatar.cc/150?u=${profile["name"]}"),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  profile["name"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile["role"],
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.business,
                        size: 14,
                        color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(profile["company"]!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.work,
                        size: 14,
                        color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(profile["experience"]!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildList(List items, String type) {
    if (query.isEmpty) {
      return const Center(
          child: Text("Start typing to search"));
    }

    if (items.isEmpty) {
      return const Center(
          child: Text("No results found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        if (type == "event") {
          return buildEventCard(items[index]);
        } else {
          return buildProfileCard(items[index]);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A8F),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.amber,
          decoration: const InputDecoration(
            hintText: "Search events, alumni, faculty...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: performSearch,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Events"),
            Tab(text: "Alumni"),
            Tab(text: "Faculty"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildList(filteredEvents, "event"),
          buildList(filteredAlumni, "profile"),
          buildList(filteredFaculty, "profile"),
        ],
      ),
    );
  }
}