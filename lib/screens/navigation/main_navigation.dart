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

    _unreadTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        _fetchUnreadTotal();
      },
    );
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadTotal() async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        return;
      }

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
          if (count is int) {
            total += count;
          }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
        canPop: selectedIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && selectedIndex != 0) {
            setState(() {
              selectedIndex = 0;
            });
          }
        },
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      body: pages[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                // 1. Home
                Expanded(
                  child: buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: "Home",
                    index: 0,
                  ),
                ),

                // 2. Create (+)
                Expanded(
                  child: buildCreateNavItem(isDark: isDark),
                ),

                // 3. Chat
                Expanded(
                  child: buildNavItem(
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: "Chat",
                    index: 1,
                    badgeCount: _totalUnreadCount,
                  ),
                ),

                // 4. Profile
                Expanded(
                  child: buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person_rounded,
                    label: "Profile",
                    index: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
    );
  }

  Widget buildNavItem({
    required IconData icon,
    required int index,
    IconData? activeIcon,
    String? label,
    int badgeCount = 0,
  }) {
    final isSelected = selectedIndex == index;

    final displayIcon = isSelected ? (activeIcon ?? icon) : icon;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = isDark ? Colors.white : const Color(0xFF0D1B2A);

    const inactiveColor = Colors.grey;

    final color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });

        if (index == 1) {
          _fetchUnreadTotal();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                displayIcon,
                color: color,
                size: 24,
              ),
              if (badgeCount > 0 && index == 1)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (label != null) ...[
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildCreateNavItem({required bool isDark}) {
    final buttonColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFF0D1B2A);

    return InkWell(
      onTap: showCreateOptions,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: buttonColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Create",
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void showCreateOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
          ),
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
                leading: const Icon(
                  Icons.work_outline,
                ),
                title: const Text(
                  "Post Job",
                ),
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
                leading: const Icon(
                  Icons.event_outlined,
                ),
                title: const Text(
                  "Create Event",
                ),
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