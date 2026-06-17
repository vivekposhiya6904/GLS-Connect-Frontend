import 'package:flutter/material.dart';
import '../../services/job_service.dart';

class PostJobScreen extends StatefulWidget {
  @override
  _PostJobScreenState createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {

  final title = TextEditingController();
  final company = TextEditingController();
  final location = TextEditingController();
  final salary = TextEditingController();
  final description = TextEditingController();
  final link = TextEditingController();
  final skillsRequired = TextEditingController();
  final experienceRequired = TextEditingController();
  
  String joiningType = "Immediate";
  String jobType = "Full Time";
  DateTime? selectedDate;
  bool isLoading = false;

  void submitJob() async {
    // Validate inputs
    if (title.text.isEmpty ||
        company.text.isEmpty ||
        location.text.isEmpty ||
        salary.text.isEmpty ||
        description.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await JobService.createJob(
        companyName: company.text,
        jobTitle: title.text,
        location: location.text,
        salary: salary.text,
        jobDescription: description.text,
        skillsRequired: skillsRequired.text.isNotEmpty ? skillsRequired.text : "N/A",
        experienceRequired: experienceRequired.text.isNotEmpty ? experienceRequired.text : "N/A",
        joiningType: joiningType,
        jobType: jobType,
        lastDateToApply: "${selectedDate?.year}-${selectedDate?.month.toString().padLeft(2, '0')}-${selectedDate?.day.toString().padLeft(2, '0')}",
      );

      setState(() => isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job posted successfully!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to post job")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A8F),
        elevation: 0,
        title: const Text("Post Job", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 SECTION: JOB DETAILS
            sectionTitle("Job Details"),

            inputField(title, "Job Title*"),
            inputField(company, "Company Name*"),
            inputField(location, "Location*"),
            inputField(salary, "Salary*"),

            const SizedBox(height: 20),

            /// 🔹 SECTION: DESCRIPTION
            sectionTitle("Job Description"),

            inputField(description, "Enter description*", maxLines: 4),
            inputField(skillsRequired, "Skills Required (Optional)", maxLines: 2),
            inputField(experienceRequired, "Experience Required (Optional)", maxLines: 2),

            const SizedBox(height: 20),

            /// 🔹 SECTION: JOB TYPE
            sectionTitle("Job Type & Joining"),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: jobType,
                    decoration: InputDecoration(
                      labelText: "Job Type",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: ["Full Time", "Part Time", "Contract", "Internship"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setState(() => jobType = value!);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: joiningType,
                    decoration: InputDecoration(
                      labelText: "Joining",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: ["Immediate", "15 Days", "30 Days", "60 Days"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setState(() => joiningType = value!);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔹 SECTION: DEADLINE
            sectionTitle("Application Deadline*"),

            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate != null
                          ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                          : "Select date",
                      style: TextStyle(
                        color: selectedDate != null ? Colors.black : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: Color(0xFF1A3A8F)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// 🔥 SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A8F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : submitJob,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Post Job",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 🔹 CUSTOM INPUT FIELD
  Widget inputField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// 🔹 SECTION TITLE
  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}