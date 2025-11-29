import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class NotesField extends StatefulWidget {
  final TextEditingController controller;
  final String? hint;

  const NotesField({
    super.key,
    required this.controller,
    this.hint,
  });

  @override
  State<NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<NotesField> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.note_alt_outlined,
                color: AppTheme.primaryColor),
            title: const Text('Add Notes (Optional)'),
            subtitle: widget.controller.text.isEmpty
                ? null
                : Text(
                    widget.controller.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall,
                  ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: widget.controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: widget.hint ?? 'Add any additional notes here...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  setState(() {}); // Update to show preview
                },
              ),
            ),
        ],
      ),
    );
  }
}
