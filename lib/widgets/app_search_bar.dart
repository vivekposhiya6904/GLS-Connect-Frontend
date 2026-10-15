import 'package:flutter/material.dart';

/// Standardized, accessible search bar component used across GLS Connect
class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Color fillColor;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.fillColor = Colors.white,
    this.focusNode,
    this.textInputAction = TextInputAction.search,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveFill = isDark ? const Color(0xFF262626) : fillColor;

    return Semantics(
      textField: true,
      label: hintText,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;

          return TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: textInputAction,
            onSubmitted: (text) {
              focusNode?.unfocus();
              onSubmitted?.call(text);
            },
            onChanged: onChanged,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.5,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade500,
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF1A3A8F),
                size: 22,
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      tooltip: "Clear search",
                      onPressed: () {
                        controller.clear();
                        onClear?.call();
                      },
                    )
                  : null,
              filled: true,
              fillColor: effectiveFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1A3A8F), width: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }
}
