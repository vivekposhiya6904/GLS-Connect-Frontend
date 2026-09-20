import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../screens/job_post/job_detail_screen.dart';
import '../utils/date_helper.dart';
import '../utils/salary_helper.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final String myEmail;
  final VoidCallback? onRefresh;

  const JobCard({
    super.key,
    required this.job,
    this.myEmail = "",
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpired = DateHelper.isExpired(job.lastDateToApply);
    final statusText = DateHelper.getJobStatus(job.lastDateToApply);
    final formattedSalary = SalaryHelper.formatLpa(job.salary);

    final showChat = job.userEmail.isNotEmpty &&
        job.userEmail.trim().toLowerCase() != myEmail.trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                builder: (_) => JobDetailScreen(job: job),
              ),
            );
            if (result == true) {
              onRefresh?.call();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Icon, Title & Company, Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3A8F).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.work_outline,
                        color: Color(0xFF1A3A8F),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.jobTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            job.companyName,
                            style: const TextStyle(
                              color: Color(0xFF1A3A8F),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9))
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isExpired
                              ? (isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1))
                              : const Color(0xFF86EFAC),
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isExpired
                              ? (isDark ? Colors.grey.shade400 : const Color(0xFF64748B))
                              : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Summary Metadata Row: Location, Salary (LPA), Experience
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_rupee_outlined, size: 15, color: Color(0xFF1A3A8F)),
                        const SizedBox(width: 4),
                        Text(
                          formattedSalary,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A8F),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          job.location,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    if (job.experienceRequired.isNotEmpty && job.experienceRequired != "N/A")
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge_outlined, size: 15, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            job.experienceRequired,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Bottom row: Deadline info & quick actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: isExpired ? Colors.redAccent : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isExpired
                              ? "Deadline ended: ${DateHelper.formatFriendlyDate(job.lastDateToApply)}"
                              : "Apply by: ${DateHelper.formatFriendlyDate(job.lastDateToApply)}",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isExpired ? Colors.redAccent : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (showChat)
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF1A3A8F)),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tooltip: "Chat with Poster",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    name: job.userName,
                                    receiverEmail: job.userEmail,
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
                      ],
                    ),
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
