import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../config/api_config.dart';
import 'alumni_home_screen.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  late Future<List<EventModel>?> _eventsFuture;
  late Future<List<EventModel>?> _myEventsFuture;
  bool _showPast = false;

  bool _isExpired(String dateStr) {
    try {
      if (dateStr.isEmpty) return false;
      final date = DateTime.parse(dateStr.split('T')[0]);
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
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _eventsFuture = EventService.getAllEvents();
      _myEventsFuture = EventService.getMyEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _refreshData,
              tooltip: "Refresh Data",
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: "Events", icon: Icon(Icons.event_rounded, size: 18)),
              Tab(text: "My Events", icon: Icon(Icons.stars_rounded, size: 18)),
              Tab(text: "Alumni", icon: Icon(Icons.people_alt_rounded, size: 18)),
              Tab(text: "Faculty", icon: Icon(Icons.badge_rounded, size: 18)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEventListTab(_eventsFuture, false),
            _buildEventListTab(_myEventsFuture, true),
            const ProfileList(role: "ALUMNI"),
            const ProfileList(role: "FACULTY"),
          ],
        ),
      ),
    );
  }

  Widget _buildEventListTab(Future<List<EventModel>?> future, bool isMyTab) {
    return FutureBuilder<List<EventModel>?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A8F)));
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading events", style: TextStyle(color: Colors.grey)));
        }

        final allEvents = snapshot.data ?? [];
        final events = isMyTab
            ? allEvents
            : allEvents.where((e) => _isExpired(e.eventDate) == _showPast).toList();

        if (events.isEmpty) {
          return Column(
            children: [
              if (!isMyTab) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showPast ? "Past Events Archive" : "Active Events",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B40)),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showPast = !_showPast;
                          });
                        },
                        icon: Icon(_showPast ? Icons.feed_outlined : Icons.history_toggle_off, size: 16),
                        label: Text(_showPast ? "Show Active" : "Past Events"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showPast ? Colors.amber.shade800 : const Color(0xFF1A3A8F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: Center(
                  child: Text(
                    isMyTab
                        ? "You haven't created any events."
                        : "No events in this category.",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length + (!isMyTab ? 1 : 0),
          itemBuilder: (context, index) {
            if (!isMyTab && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showPast ? "Past Events Archive" : "Active Events",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B40)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showPast = !_showPast;
                        });
                      },
                      icon: Icon(_showPast ? Icons.feed_outlined : Icons.history_toggle_off, size: 16),
                      label: Text(_showPast ? "Show Active" : "Past Events"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showPast ? Colors.amber.shade800 : const Color(0xFF1A3A8F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              );
            }
            final event = events[isMyTab ? index : index - 1];
            final imgUrl = event.imageUrl != null && event.imageUrl!.trim().isNotEmpty
                ? (event.imageUrl!.startsWith("http") ? event.imageUrl! : "${ApiConfig.baseUrl}${event.imageUrl}")
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
          },
        );
      },
    );
  }
}