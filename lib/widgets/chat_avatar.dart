import 'package:flutter/material.dart';

class ChatAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;
  final bool isOnline;
  final Color? backgroundColor;

  const ChatAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 24,
    this.isOnline = false,
    this.backgroundColor,
  });

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : "";
      final second = parts[1].isNotEmpty ? parts[1][0] : "";
      return (first + second).toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getDeterministicColor(String text) {
    const colors = [
      Color(0xFF1A3A8F),
      Color(0xFF0284C7),
      Color(0xFF0D9488),
      Color(0xFF4F46E5),
      Color(0xFF7C3AED),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFFE11D48),
    ];
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? _getDeterministicColor(name);
    final borderColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
              ? NetworkImage(imageUrl!)
              : null,
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? Text(
                  _getInitials(name),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.75,
                    letterSpacing: 0.5,
                  ),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.52,
              height: radius * 0.52,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: radius * 0.08 < 1.5 ? 1.5 : radius * 0.08,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
