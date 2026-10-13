import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../utils/city_constants.dart';
import '../../utils/image_picker_helper.dart';

class CreateEventScreen extends StatefulWidget {
  final EventModel? eventToEdit;

  const CreateEventScreen({super.key, this.eventToEdit});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCity;
  List<String> _cityOptions = [];

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
  bool _dateError = false;
  String? _dateErrorMessage;

  XFile? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _titleController.text = e.title;
      _descController.text = e.description;
      _selectedCity = CityConstants.matchCanonicalCity(e.location);
      _cityOptions = CityConstants.getDropdownOptions(currentCity: _selectedCity);
      _noteController.text = e.note ?? "";
      if (e.targetDepartment != null && _departments.contains(e.targetDepartment)) {
        _selectedDepartment = e.targetDepartment!;
      }
      try {
        if (e.eventDate.isNotEmpty) {
          _selectedDate = DateTime.parse(e.eventDate);
        }
      } catch (_) {}
    } else {
      _cityOptions = CityConstants.getDropdownOptions();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePickerHelper.pickImageWithSourceDialog(
      context,
      title: "Select Event Banner",
    );
    if (picked != null) {
      setState(() {
        _imageFile = picked;
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final initial = (_selectedDate != null && !_selectedDate!.isBefore(today))
        ? _selectedDate!
        : today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = false;
        _dateErrorMessage = null;
      });
    }
  }

  Future<void> _submitEvent() async {
    if (_isLoading) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      if (_selectedDate == null) {
        _dateError = true;
        _dateErrorMessage = "Please select an event date.";
      } else if (_selectedDate!.isBefore(today)) {
        _dateError = true;
        _dateErrorMessage = "Event date cannot be in the past.";
      } else {
        _dateError = false;
        _dateErrorMessage = null;
      }
    });

    final isFormValid = _formKey.currentState!.validate();
    if (!isFormValid || _dateError || _selectedDate == null) {
      // Standardized field-level validation errors are visible directly below each field
      return;
    }

    setState(() => _isLoading = true);

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final loc = _selectedCity ?? "";
    final dateStr =
        "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

    final bool isEditing = widget.eventToEdit != null;
    final success = isEditing
        ? await EventService.updateEvent(
            eventId: widget.eventToEdit!.id!,
            title: title,
            description: desc,
            location: loc,
            eventDate: dateStr,
            targetDepartment: _selectedDepartment,
            note: _noteController.text.trim(),
            imageFile: _imageFile,
          )
        : await EventService.createEvent(
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? "Event updated successfully!" : "Event created successfully!"),
          backgroundColor: const Color(0xFF1A3A8F),
        ),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? "Failed to update event. Please try again." : "Failed to create event. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.eventToEdit != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A8F),
        title: Text(isEditing ? "Edit Event" : "Create Event", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? "Edit Event Details" : "Event Details",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A8F),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _titleController,
                        "Event Title*",
                        Icons.title,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Event title is required.";
                          }
                          if (val.trim().length < 3) {
                            return "Event title must be at least 3 characters.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _descController,
                        "Description*",
                        Icons.description,
                        maxLines: 4,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Event description is required.";
                          }
                          if (val.trim().length < 10) {
                            return "Description must be at least 10 characters.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // City Dropdown
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration: InputDecoration(
                            labelText: "Location / City*",
                            hintText: "Select event city",
                            prefixIcon: const Icon(Icons.location_on, color: Color(0xFF1A3A8F)),
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
                          items: _cityOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCity = val;
                            });
                          },
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Please select a city.";
                            }
                            return null;
                          },
                        ),
                      ),

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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1A3A8F), width: 1.8),
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

                      // Date Picker (No past dates allowed)
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _dateError ? Colors.red.shade700 : Colors.grey.shade300,
                              width: _dateError ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate == null
                                    ? "Select Event Date*"
                                    : "Date: ${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}",
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
                      if (_dateError && _dateErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 12),
                          child: Text(
                            _dateErrorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Image Picker Container (Camera & Gallery)
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
                              ? (isEditing && widget.eventToEdit?.imageUrl != null && widget.eventToEdit!.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.eventToEdit!.imageUrl!.startsWith("http")
                                            ? widget.eventToEdit!.imageUrl!
                                            : "${ApiConfig.baseUrl}${widget.eventToEdit!.imageUrl}",
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_outlined, size: 40, color: Color(0xFF1A3A8F)),
                                        SizedBox(height: 8),
                                        Text("Upload Event Banner (Camera / Gallery)", style: TextStyle(color: Colors.grey)),
                                      ],
                                    ))
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
                          onPressed: _isLoading ? null : _submitEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3A8F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  isEditing ? "Update Event" : "Create Event",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1A3A8F)),
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
}
