import 'package:flutter/material.dart';
import '../services/cache_service.dart';

class OfflineIndicatorBanner extends StatelessWidget {
  final DateTime? lastUpdated;
  final String? timeAgo;
  final VoidCallback? onRetry;

  const OfflineIndicatorBanner({
    super.key,
    this.lastUpdated,
    this.timeAgo,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = timeAgo ??
        (lastUpdated != null ? CacheService.formatTimeAgo(lastUpdated!) : null);
    final bannerText = timeStr != null
        ? "Offline mode • Showing cached data (saved $timeStr)"
        : "Offline mode • Showing cached data";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bannerText,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null)
            InkWell(
              onTap: onRetry,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  "Retry",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
