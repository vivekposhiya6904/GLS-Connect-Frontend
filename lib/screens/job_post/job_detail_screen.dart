import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_model.dart';
import '../../screens/chat/chat_detail_screen.dart';
import '../../utils/date_helper.dart';
import '../../utils/salary_helper.dart';
import '../../utils/storage_service.dart';
import 'job_post_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;
  final bool isAdmin;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.isAdmin = false,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
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
    final isExpired = DateHelper.isExpired(widget.job.lastDateToApply);
    final statusText = DateHelper.getJobStatus(widget.job.lastDateToApply);
    final formattedSalary = SalaryHelper.formatLpa(widget.job.salary);
    final isMyJob = widget.job.userEmail.isNotEmpty &&
        widget.job.userEmail.trim().toLowerCase() == myEmail;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A8F),
        elevation: 0,
        title: const Text("Job Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isMyJob || widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: "Edit Job",
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostJobScreen(jobToEdit: widget.job),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card: Title, Company, Status, and Overview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A8F).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.work_outline,
                          color: Color(0xFF1A3A8F),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.job.jobTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.job.companyName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A3A8F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Expiration / Active Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9))
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isExpired
                                ? (isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1))
                                : const Color(0xFF86EFAC),
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isExpired
                                ? (isDark ? Colors.grey.shade400 : const Color(0xFF64748B))
                                : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Key attributes grid
                  Wrap(
                    spacing: 24,
                    runSpacing: 14,
                    children: [
                      _buildDetailBadge(
                        icon: Icons.currency_rupee_outlined,
                        label: "Salary Package",
                        value: formattedSalary,
                        valueColor: const Color(0xFF1A3A8F),
                        isBold: true,
                      ),
                      _buildDetailBadge(
                        icon: Icons.location_on_outlined,
                        label: "Location",
                        value: widget.job.location,
                      ),
                      _buildDetailBadge(
                        icon: Icons.access_time_outlined,
                        label: "Job Type",
                        value: widget.job.jobType,
                      ),
                      _buildDetailBadge(
                        icon: Icons.flash_on_outlined,
                        label: "Joining",
                        value: widget.job.joiningType,
                      ),
                      _buildDetailBadge(
                        icon: Icons.badge_outlined,
                        label: "Experience",
                        value: widget.job.experienceRequired,
                      ),
                      _buildDetailBadge(
                        icon: Icons.calendar_month_outlined,
                        label: "Deadline",
                        value: DateHelper.formatFriendlyDate(widget.job.lastDateToApply),
                        valueColor: isExpired ? Colors.redAccent : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Description Section
            _buildContentSection(
              title: "Job Description",
              content: widget.job.jobDescription,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // Skills Required
            _buildContentSection(
              title: "Skills & Requirements",
              content: widget.job.skillsRequired,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // Company Contact & Apply Links
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Application Information",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.job.companyLink != null && widget.job.companyLink!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 18, color: Color(0xFF1A3A8F)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.job.companyLink!,
                              style: const TextStyle(
                                color: Color(0xFF1A3A8F),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.job.companyEmail != null && widget.job.companyEmail!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.mail_outline, size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Submit Resume to: ${widget.job.companyEmail!}",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Poster Profile Summary
            if (widget.job.userName.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                            "Posted by: ${widget.job.userName}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (widget.job.posterDepartment != null &&
                              widget.job.posterDepartment!.isNotEmpty &&
                              widget.job.posterDepartment != "N/A")
                            Text(
                              "${widget.job.posterDepartment!}${widget.job.posterBatchYear != null ? ' • ${widget.job.posterBatchYear!}' : ''}",
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 90), // Space for bottom action bar
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
              onPressed: (isExpired || isMyJob)
                  ? null
                  : () async {
                      final emailToUse = (widget.job.companyEmail != null && widget.job.companyEmail!.trim().isNotEmpty)
                          ? widget.job.companyEmail!.trim()
                          : widget.job.userEmail.trim();

                      if (emailToUse.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No contact email provided for this job.")),
                        );
                        return;
                      }

                      final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: emailToUse,
                        queryParameters: {
                          'subject': 'Application for ${widget.job.jobTitle} position at ${widget.job.companyName}',
                        },
                      );

                      try {
                        if (await canLaunchUrl(emailLaunchUri)) {
                          await launchUrl(emailLaunchUri);
                        } else {
                          await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Email client opened for: $emailToUse")),
                          );
                        }
                      }
                    },
              icon: Icon(
                isExpired
                    ? Icons.block_rounded
                    : (isMyJob ? Icons.person_rounded : Icons.mail_outline_rounded),
                size: 18,
              ),
              label: Text(
                isExpired
                    ? "Applications Closed"
                    : (isMyJob ? "You posted this job" : "Apply Now"),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A8F),
                disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                foregroundColor: Colors.white,
                disabledForegroundColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: (isExpired || isMyJob) ? 0 : 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBadge({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A3A8F)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.isNotEmpty ? content : "Not specified",
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
