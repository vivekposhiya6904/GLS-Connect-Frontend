import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../services/job_service.dart';

class PostJobScreen extends StatefulWidget {
  final JobModel? jobToEdit;

  const PostJobScreen({super.key, this.jobToEdit});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final title = TextEditingController();
  final company = TextEditingController();
  final location = TextEditingController();
  final salary = TextEditingController();
  final description = TextEditingController();
  final companyLink = TextEditingController();
  final companyEmail = TextEditingController();
  final skillsRequired = TextEditingController();
  final experienceRequired = TextEditingController();

  String joiningType = "Immediate";
  String jobType = "Full Time";
  DateTime? selectedDate;
  bool _dateError = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.jobToEdit != null) {
      final j = widget.jobToEdit!;
      title.text = j.jobTitle;
      company.text = j.companyName;
      location.text = j.location;
      salary.text = j.salary;
      description.text = j.jobDescription;
      companyLink.text = j.companyLink ?? "";
      companyEmail.text = j.companyEmail ?? "";
      skillsRequired.text = j.skillsRequired;
      experienceRequired.text = j.experienceRequired;
      joiningType = j.joiningType.isNotEmpty ? j.joiningType : "Immediate";
      jobType = j.jobType.isNotEmpty ? j.jobType : "Full Time";
      try {
        if (j.lastDateToApply.isNotEmpty) {
          selectedDate = DateTime.parse(j.lastDateToApply);
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    title.dispose();
    company.dispose();
    location.dispose();
    salary.dispose();
    description.dispose();
    companyLink.dispose();
    companyEmail.dispose();
    skillsRequired.dispose();
    experienceRequired.dispose();
    super.dispose();
  }

  void submitJob() async {
    setState(() {
      _dateError = selectedDate == null;
    });

    if (!_formKey.currentState!.validate() || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all required fields with valid details."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final cleanSalary = salary.text.trim();
      final lpaFormatted = cleanSalary.toLowerCase().endsWith("lpa")
          ? cleanSalary
          : "$cleanSalary LPA";

      final dateStr =
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

      final bool isEditing = widget.jobToEdit != null;
      final success = isEditing
          ? await JobService.updateJob(
              jobId: widget.jobToEdit!.id!,
              companyName: company.text.trim(),
              jobTitle: title.text.trim(),
              location: location.text.trim(),
              salary: lpaFormatted,
              jobDescription: description.text.trim(),
              skillsRequired: skillsRequired.text.trim(),
              experienceRequired: experienceRequired.text.trim(),
              joiningType: joiningType,
              jobType: jobType,
              lastDateToApply: dateStr,
              companyLink: companyLink.text.trim(),
              companyEmail: companyEmail.text.trim(),
            )
          : await JobService.createJob(
              companyName: company.text.trim(),
              jobTitle: title.text.trim(),
              location: location.text.trim(),
              salary: lpaFormatted,
              jobDescription: description.text.trim(),
              skillsRequired: skillsRequired.text.trim(),
              experienceRequired: experienceRequired.text.trim(),
              joiningType: joiningType,
              jobType: jobType,
              lastDateToApply: dateStr,
              companyLink: companyLink.text.trim(),
              companyEmail: companyEmail.text.trim(),
            );

      setState(() => isLoading = false);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? "Job updated successfully!" : "Job posted successfully!"),
            backgroundColor: const Color(0xFF1A3A8F),
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to post job. Please check your inputs."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A8F),
        elevation: 0,
        title: Text(widget.jobToEdit != null ? "Edit Job" : "Post Job", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle("Job Overview"),
              formInputField(
                controller: title,
                label: "Job Title*",
                hint: "e.g. Senior Flutter Developer",
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Job title is required.";
                  }
                  if (val.trim().length < 2) {
                    return "Job title must be at least 2 characters.";
                  }
                  return null;
                },
              ),
              formInputField(
                controller: company,
                label: "Company Name*",
                hint: "e.g. Infosys, TCS, Google",
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Company name is required.";
                  }
                  return null;
                },
              ),
              formInputField(
                controller: location,
                label: "Location*",
                hint: "e.g. Ahmedabad / Remote / Hybrid",
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Job location is required.";
                  }
                  return null;
                },
              ),
              formInputField(
                controller: salary,
                label: "Annual Salary (LPA)*",
                hint: "e.g. 4.5, 6.25, 12",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Salary is required.";
                  }
                  final clean = val.trim().replaceAll("(?i)lpa", "").replaceAll("₹", "").trim();
                  final num = double.tryParse(clean);
                  if (num == null) {
                    return "Please enter a valid annual salary in LPA (e.g. 4.5).";
                  }
                  if (num <= 0) {
                    return "Salary must be greater than 0 LPA.";
                  }
                  if (num > 200) {
                    return "Please enter a realistic annual salary in LPA (max 200).";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              sectionTitle("Job Description & Requirements"),
              formInputField(
                controller: description,
                label: "Job Description*",
                hint: "Detailed overview of roles and daily responsibilities",
                maxLines: 4,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Job description is required.";
                  }
                  if (val.trim().length < 10) {
                    return "Please provide a more descriptive job overview (min 10 chars).";
                  }
                  return null;
                },
              ),
              formInputField(
                controller: skillsRequired,
                label: "Skills Required*",
                hint: "e.g. Flutter, Dart, REST APIs, Git",
                maxLines: 2,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please specify required skills.";
                  }
                  return null;
                },
              ),
              formInputField(
                controller: experienceRequired,
                label: "Experience Required*",
                hint: "e.g. Freshers / 1–3 Years / 3+ Years",
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please specify required experience.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              sectionTitle("Company Contact & Application Channels"),
              formInputField(
                controller: companyLink,
                label: "Company Website / Apply Link*",
                hint: "https://example.com/careers",
                keyboardType: TextInputType.url,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Application link or website is required.";
                  }
                  final v = val.trim().toLowerCase();
                  if (!v.contains(".")) {
                    return "Please enter a valid URL or website domain.";
                  }
                  return null;
                },
              ),
              formInputField(
                controller: companyEmail,
                label: "Resume Submission Email*",
                hint: "careers@company.com",
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Company contact email is required.";
                  }
                  final v = val.trim();
                  if (!v.contains("@") || !v.contains(".")) {
                    return "Please enter a valid email address.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              sectionTitle("Employment Type & Joining"),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: jobType,
                      decoration: InputDecoration(
                        labelText: "Job Type*",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: ["Full Time", "Part Time", "Contract", "Internship"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => jobType = value);
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "Please select an employment type.";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: joiningType,
                      decoration: InputDecoration(
                        labelText: "Joining*",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: ["Immediate", "15 Days", "30 Days", "60 Days"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => joiningType = value);
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "Please select a joining timeline.";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              sectionTitle("Application Deadline*"),
              GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 2),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                      _dateError = false;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: _dateError ? Colors.red.shade700 : Colors.grey.shade300,
                      width: _dateError ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate != null
                            ? "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}"
                            : "Select application deadline date",
                        style: TextStyle(
                          color: selectedDate != null ? Colors.black87 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, color: Color(0xFF1A3A8F), size: 20),
                    ],
                  ),
                ),
              ),
              if (_dateError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    "Application deadline is required.",
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A8F),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isLoading ? null : submitJob,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          "Post Job",
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget formInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A3A8F), width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}