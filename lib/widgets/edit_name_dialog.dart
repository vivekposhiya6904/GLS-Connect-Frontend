import 'package:flutter/material.dart';
import '../services/user_service.dart';

class EditNameDialog extends StatefulWidget {
  final String currentName;
  final Function(String newName) onNameUpdated;

  const EditNameDialog({
    super.key,
    required this.currentName,
    required this.onNameUpdated,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String currentName,
    required Function(String newName) onNameUpdated,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditNameDialog(
        currentName: currentName,
        onNameUpdated: onNameUpdated,
      ),
    );
  }

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    if (newName == widget.currentName.trim()) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await UserService.updateUserName(newName);

    if (!mounted) return;

    if (success) {
      widget.onNameUpdated(newName);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Name updated successfully!"),
          backgroundColor: Color(0xFF1A3A8F),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = UserService.lastErrorMessage ?? "Failed to update name. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A8F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_outlined, color: Color(0xFF1A3A8F), size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            "Edit Full Name",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0D1B40),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your display name will be updated across your profile, dashboard, and directory listings.",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Full Name*",
                hintText: "Enter your full name",
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF1A3A8F)),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A3A8F), width: 1.8),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Name cannot be empty.";
                }
                final clean = val.trim();
                if (clean.length < 2) {
                  return "Name must be at least 2 characters.";
                }
                if (clean.length > 60) {
                  return "Name cannot exceed 60 characters.";
                }
                if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(clean)) {
                  return "Name can only contain letters, spaces, dots, hyphens, and apostrophes.";
                }
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            "Cancel",
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3A8F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

