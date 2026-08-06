import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../utils/storage_service.dart';

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
  Timer? _unreadTimer;
  int _totalUnreadCount = 0;

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

    _fetchUnreadTotal();
    _unreadTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchUnreadTotal();
    });
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadTotal() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/chat/unread"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        int total = 0;
        data.forEach((_, count) {
          if (count is int) total += count;
        });

        if (mounted) {
          setState(() {
            _totalUnreadCount = total;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,

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
              buildNavItem(Icons.chat_bubble_outline, 1, badgeCount: _totalUnreadCount),
              buildNavItem(Icons.person_outline, 2),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFF0D1B2A),
        onPressed: () {
          showCreateOptions();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget buildNavItem(IconData icon, int index, {int badgeCount = 0}) {
    final isSelected = selectedIndex == index;
    final color = isSelected
        ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0D1B2A))
        : Colors.grey;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              selectedIndex = index;
            });
            if (index == 1) {
              _fetchUnreadTotal();
            }
          },
          icon: Icon(icon, color: color),
        ),
        if (badgeCount > 0 && index == 1)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

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