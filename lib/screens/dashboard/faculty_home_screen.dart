import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../config/api_config.dart';
import 'alumni_home_screen.dart'; // To reuse ProfileList and EventCard!

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          title: Text(
            "GLS Connect",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              onPressed: _refreshData,
            ),
            const SizedBox(width: 12),
          ],
          bottom: TabBar(
            labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: const [
              Tab(text: "Events"),
              Tab(text: "My Events"),
              Tab(text: "Alumni"),
              Tab(text: "Faculty"),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading events"));
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
                        _showPast ? "Previous Ends" : "Active Events",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A8F)),
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
                      _showPast ? "Previous Ends" : "Active Events",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A8F)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              );
            }
            final event = events[isMyTab ? index : index - 1];
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
          },
        );
      },
    );
  }
}