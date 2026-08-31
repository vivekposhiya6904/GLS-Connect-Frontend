import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import 'chat_status_ticks.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final bubbleColor = isMe
        ? primaryColor
        : (isDark ? const Color(0xFF242424) : Colors.white);

    final textColor = isMe
        ? Colors.white
        : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A));

    final timeColor = isMe
        ? Colors.white.withValues(alpha: 0.75)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    final borderColor = isMe
        ? Colors.transparent
        : (isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 3),
                bottomRight: Radius.circular(isMe ? 3 : 18),
              ),
              border: Border.all(
                color: borderColor,
                width: isMe ? 0 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: timeColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      ChatStatusTicks(
                        status: message.status,
                        color: Colors.white.withValues(alpha: 0.75),
                        readColor: const Color(0xFF38BDF8),
                        size: 13,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
