import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../models/event_model.dart';
import '../../screens/chat/chat_detail_screen.dart';
import '../../utils/date_helper.dart';
import '../../utils/storage_service.dart';
import 'create_event_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String myEmail = "";

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final email = await StorageService.getUserEmail();
    if (mounted) {
      setState(() {
        myEmail = (email ?? "").trim().toLowerCase();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpired = DateHelper.isExpired(widget.event.eventDate);
    final statusText = DateHelper.getEventStatus(widget.event.eventDate);

    final isMyEvent = widget.event.createdByEmail != null &&
        widget.event.createdByEmail!.isNotEmpty &&
        widget.event.createdByEmail!.trim().toLowerCase() == myEmail;
    final hasOrganizer = widget.event.createdByEmail != null &&
        widget.event.createdByEmail!.isNotEmpty;

    final imgUrl = widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty
        ? (widget.event.imageUrl!.startsWith("http")
            ? widget.event.imageUrl!
            : "${ApiConfig.baseUrl}${widget.event.imageUrl}")
        : "https://picsum.photos/800/400?random=${widget.event.title}";

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A8F),
        elevation: 0,
        title: const Text("Event Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isMyEvent)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: "Edit Event",
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateEventScreen(eventToEdit: widget.event),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Hero Banner Image
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: Colors.black,
                      appBar: AppBar(
                        backgroundColor: Colors.black,
                        iconTheme: const IconThemeData(color: Colors.white),
                      ),
                      body: Center(
                        child: InteractiveViewer(
                          child: Image.network(imgUrl, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  Image.network(
                    imgUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 220,
                      color: const Color(0xFF1A3A8F).withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(Icons.event, size: 64, color: Color(0xFF1A3A8F)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Colors.black.withValues(alpha: 0.75)
                            : const Color(0xFF15803D).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.event.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Metadata Cards Row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow(
                          icon: Icons.calendar_today_outlined,
                          title: "Event Date",
                          value: DateHelper.formatFriendlyDate(widget.event.eventDate),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        _buildMetaRow(
                          icon: Icons.location_on_outlined,
                          title: "Location / Venue",
                          value: widget.event.location,
                          isDark: isDark,
                        ),
                        if (widget.event.targetDepartment != null &&
                            widget.event.targetDepartment!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildMetaRow(
                            icon: Icons.school_outlined,
                            title: "Target Department",
                            value: widget.event.targetDepartment!,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Organizer Section
                  if (widget.event.createdByName != null &&
                      widget.event.createdByName!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFF0F4FF),
                            child: Icon(Icons.person, color: Color(0xFF1A3A8F), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Organized by ${widget.event.createdByName!}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (widget.event.createdByEmail != null &&
                                    widget.event.createdByEmail!.isNotEmpty)
                                  Text(
                                    widget.event.createdByEmail!,
                                    style: TextStyle(
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (hasOrganizer && !isMyEvent)
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1A3A8F)),
                              tooltip: "Chat with Organizer",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailScreen(
                                      name: widget.event.createdByName ?? "Organizer",
                                      receiverEmail: widget.event.createdByEmail!,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "About This Event",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.event.description.isNotEmpty
                              ? widget.event.description
                              : "No description provided.",
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Important Note: Calm informational styling (NOT error or alarming amber styling)
                  if (widget.event.note != null && widget.event.note!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A2634) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2D3F54) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Event Note",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.event.note!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 90), // Space for bottom sheet
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (isMyEvent || !hasOrganizer)
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            name: widget.event.createdByName ?? "Organizer",
                            receiverEmail: widget.event.createdByEmail!,
                          ),
                        ),
                      );
                    },
              icon: Icon(
                isMyEvent
                    ? Icons.person_rounded
                    : (!hasOrganizer ? Icons.info_outline : Icons.chat_bubble_outline),
                size: 18,
              ),
              label: Text(
                isMyEvent
                    ? "You organized this event"
                    : (!hasOrganizer ? "Organizer unavailable" : "Contact Organizer"),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A8F),
                disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                foregroundColor: Colors.white,
                disabledForegroundColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: (isMyEvent || !hasOrganizer) ? 0 : 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A3A8F)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
