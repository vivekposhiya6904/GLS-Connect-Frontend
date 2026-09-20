import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/event_model.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../screens/dashboard/event_detail_screen.dart';
import '../utils/date_helper.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final String myEmail;
  final VoidCallback? onRefresh;

  const EventCard({
    super.key,
    required this.event,
    this.myEmail = "",
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpired = DateHelper.isExpired(event.eventDate);
    final statusText = DateHelper.getEventStatus(event.eventDate);

    final showChat = event.createdByEmail != null &&
        event.createdByEmail!.isNotEmpty &&
        event.createdByEmail!.trim().toLowerCase() != myEmail.trim().toLowerCase();

    final imgUrl = event.imageUrl != null && event.imageUrl!.isNotEmpty
        ? (event.imageUrl!.startsWith("http")
            ? event.imageUrl!
            : "${ApiConfig.baseUrl}${event.imageUrl}")
        : "https://picsum.photos/600/300?random=${event.title}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A8F).withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailScreen(event: event),
              ),
            );
            if (result == true) {
              onRefresh?.call();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image Banner with Status Badge
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Image.network(
                      imgUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: const Color(0xFF1A3A8F).withValues(alpha: 0.1),
                        child: const Center(
                          child: Icon(Icons.event, size: 48, color: Color(0xFF1A3A8F)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.black.withValues(alpha: 0.75)
                              : const Color(0xFF15803D).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          statusText.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
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
                    // Title
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Date & Location Metadata
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF1A3A8F)),
                        const SizedBox(width: 5),
                        Text(
                          DateHelper.formatFriendlyDate(event.eventDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Informational Note: Calm, subtle styling (NOT warning/error style)
                    if (event.note != null && event.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event.note!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Bottom Row: Organizer info & Chat Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event.createdByName != null && event.createdByName!.isNotEmpty
                                ? "By ${event.createdByName!}"
                                : (event.targetDepartment ?? "GLS Connect"),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            if (showChat)
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF1A3A8F)),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                tooltip: "Chat with Organizer",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatDetailScreen(
                                        name: event.createdByName ?? "Organizer",
                                        receiverEmail: event.createdByEmail!,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
