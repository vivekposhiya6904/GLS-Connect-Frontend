import 'package:flutter/material.dart';
import '../config/api_config.dart';

/// A robust, reusable profile avatar widget supporting circular and rectangular layouts,
/// automatic URL resolution via [ApiConfig.resolveUrl], image caching, graceful error fallbacks,
/// and customizable styling across all GLS-Connect screens.
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData fallbackIcon;
  final bool isCircle;
  final BoxFit fit;
  final VoidCallback? onTap;
  final bool enableCacheBust;
  final bool showInitials;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24.0,
    this.width,
    this.height,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.backgroundColor,
    this.foregroundColor,
    this.fallbackIcon = Icons.person,
    this.isCircle = true,
    this.fit = BoxFit.cover,
    this.onTap,
    this.enableCacheBust = false,
    this.showInitials = true,
  });

  static String getInitials(String? name) {
    if (name == null) return "";
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "";
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : "";
      final second = parts[1].isNotEmpty ? parts[1][0] : "";
      return (first + second).toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  static Color getDeterministicColor(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const Color(0xFF1A3A8F);
    }
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
    final effectiveWidth = width ?? (radius * 2);
    final effectiveHeight = height ?? (radius * 2);
    final initials = showInitials ? getInitials(name) : "";
    final effectiveBgColor = backgroundColor ??
        (initials.isNotEmpty ? getDeterministicColor(name) : const Color(0xFFE2E8F0));
    final effectiveFgColor = foregroundColor ??
        (initials.isNotEmpty ? Colors.white : const Color(0xFF64748B));

    final resolvedUrl = ApiConfig.resolveUrl(imageUrl, cacheBust: enableCacheBust);

    Widget fallbackWidget = Container(
      width: effectiveWidth,
      height: effectiveHeight,
      color: effectiveBgColor,
      alignment: Alignment.center,
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: TextStyle(
                color: effectiveFgColor,
                fontWeight: FontWeight.bold,
                fontSize: (effectiveWidth < effectiveHeight ? effectiveWidth : effectiveHeight) * 0.38,
                letterSpacing: 0.5,
              ),
            )
          : Icon(
              fallbackIcon,
              size: (effectiveWidth < effectiveHeight ? effectiveWidth : effectiveHeight) * 0.55,
              color: effectiveFgColor,
            ),
    );

    Widget content;
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      content = fallbackWidget;
    } else {
      content = Image.network(
        resolvedUrl,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallbackWidget,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return fallbackWidget;
        },
      );
    }

    Widget clippedContent;
    if (isCircle) {
      clippedContent = ClipOval(child: content);
    } else if (borderRadius != null) {
      clippedContent = ClipRRect(borderRadius: borderRadius!, child: content);
    } else {
      clippedContent = content;
    }

    Widget containerWidget = Container(
      width: effectiveWidth,
      height: effectiveHeight,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: clippedContent,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: containerWidget,
      );
    }

    return containerWidget;
  }
}
