import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';

class ChatStatusTicks extends StatelessWidget {
  final MessageStatus status;
  final Color? color;
  final Color? readColor;
  final double size;

  const ChatStatusTicks({
    super.key,
    required this.status,
    this.color,
    this.readColor,
    this.size = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Colors.grey.shade500;
    final blueTickColor = readColor ?? const Color(0xFF38BDF8);

    switch (status) {
      case MessageStatus.sent:
        return Icon(
          Icons.check_rounded,
          size: size,
          color: defaultColor,
        );
      case MessageStatus.delivered:
        return SizedBox(
          width: size * 1.45,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Icon(
                Icons.check_rounded,
                size: size,
                color: defaultColor,
              ),
              Positioned(
                left: size * 0.42,
                child: Icon(
                  Icons.check_rounded,
                  size: size,
                  color: defaultColor,
                ),
              ),
            ],
          ),
        );
      case MessageStatus.read:
        return SizedBox(
          width: size * 1.45,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Icon(
                Icons.check_rounded,
                size: size,
                color: blueTickColor,
              ),
              Positioned(
                left: size * 0.42,
                child: Icon(
                  Icons.check_rounded,
                  size: size,
                  color: blueTickColor,
                ),
              ),
            ],
          ),
        );
    }
  }
}
