import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  File? selectedImage;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  void submitJob() {
    final jobData = {
      "title": title.text,
      "company": company.text,
      "location": location.text,
      "salary": salary.text,
      "description": description.text,
      "link": link.text,
      "image": selectedImage?.path,
    };

    Navigator.pop(context, jobData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Post Job", style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 SECTION: JOB DETAILS
            sectionTitle("Job Details"),

            inputField(title, "Job Title"),
            inputField(company, "Company Name"),
            inputField(location, "Location"),
            inputField(salary, "Salary"),

            SizedBox(height: 20),

            /// 🔹 SECTION: DESCRIPTION
            sectionTitle("Job Description"),

            inputField(description, "Enter description", maxLines: 4),

            SizedBox(height: 20),

            /// 🔹 SECTION: APPLY LINK
            sectionTitle("Apply Link"),

            inputField(link, "Paste apply link"),

            SizedBox(height: 20),

            /// 🔹 SECTION: IMAGE
            sectionTitle("Upload Job Poster"),

            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 40),
                    SizedBox(height: 8),
                    Text("Tap to upload image"),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            /// 🔥 SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: submitJob,
                child: Text(
                  "Post Job",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            SizedBox(height: 20),
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