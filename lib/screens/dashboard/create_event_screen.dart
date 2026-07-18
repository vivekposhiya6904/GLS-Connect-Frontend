import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _selectedDepartment = "All";
  final List<String> _departments = [
    "All",
    "Computer Science",
    "Information Technology",
    "Business Administration",
    "Commerce",
    "Computer Applications",
  ];

  DateTime? _selectedDate;
  XFile? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = picked;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitEvent() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final loc = _locationController.text.trim();

    if (title.isEmpty || desc.isEmpty || loc.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

    final success = await EventService.createEvent(
      title: title,
      description: desc,
      location: loc,
      eventDate: dateStr,
      targetDepartment: _selectedDepartment,
      note: _noteController.text.trim(),
      imageFile: _imageFile,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event created successfully!")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create event")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A8F),
        title: const Text("Create Event", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Event Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A8F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_titleController, "Event Title*", Icons.title),
                  const SizedBox(height: 12),
                  _buildTextField(_descController, "Description*", Icons.description, maxLines: 4),
                  const SizedBox(height: 12),
                  _buildTextField(_locationController, "Location*", Icons.location_on),
                  const SizedBox(height: 12),
                  
                  // Department Dropdown
                  const Text(
                    "Department (Who can join)*",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.school, color: Color(0xFF1A3A8F)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: _departments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept,
                        child: Text(dept),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDepartment = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Note Text Field
                  _buildTextField(_noteController, "Important Note (Optional)", Icons.note_alt_outlined, maxLines: 2),
                  const SizedBox(height: 16),
                  
                  // Date Picker
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null
                                ? "Select Event Date*"
                                : "Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                            style: TextStyle(
                              color: _selectedDate == null ? Colors.grey.shade600 : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                          const Icon(Icons.calendar_today, color: Color(0xFF1A3A8F)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image Picker Container
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _imageFile == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text("Upload Event Image (Optional)", style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                                  : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3A8F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Create Event",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1A3A8F)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
