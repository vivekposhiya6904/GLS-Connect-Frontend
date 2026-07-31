import 'package:flutter/material.dart';

import '../dashboard/alumni_home_screen.dart';
import '../dashboard/faculty_home_screen.dart';
import '../dashboard/admin_home_screen.dart';
import '../chat/chat_screen.dart';

import '../job_post/job_post_screen.dart';
import '../profile/alumni_profile_screen.dart';
import '../profile/faculty_profile_screen.dart';
import '../dashboard/create_event_screen.dart';

class MainNavigation extends StatefulWidget {
  final String userRole;

  const MainNavigation({
    super.key,
    required this.userRole,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();

    if (widget.userRole == "ADMIN") {
      pages = const [
        AdminHomeScreen(),
        ChatScreen(),
        AlumniProfileScreen(),
      ];
    } else if (widget.userRole == "FACULTY") {
      pages = const [
        FacultyDashboard(),
        ChatScreen(),
        FacultyProfileScreen(),
      ];
    } else {
      pages = const [
        HomeScreen(),
        ChatScreen(),
        AlumniProfileScreen(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // ✅ FIXED KEYBOARD ISSUE

      body: pages[selectedIndex],

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildNavItem(Icons.home_outlined, 0),
              const SizedBox(width: 40),
              buildNavItem(Icons.chat_bubble_outline, 1),
              buildNavItem(Icons.person_outline, 2),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFF0D1B2A),
        onPressed: () {
          showCreateOptions(); // ✅ OPEN MENU
        },
        child: Icon(Icons.add, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white),
      ),

      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget buildNavItem(IconData icon, int index) {
    return IconButton(
      onPressed: () {
        setState(() {
          selectedIndex = index;
        });
      },
      icon: Icon(
        icon,
        color: selectedIndex == index
            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0D1B2A))
            : Colors.grey,
      ),
    );
  }

  // 🔥 INSTAGRAM-LIKE MENU
  void showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Create",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // JOB OPTION
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: const Text("Post Job"),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostJobScreen(),
                    ),
                  );
                },
              ),

              // EVENT OPTION
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text("Create Event"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateEventScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}