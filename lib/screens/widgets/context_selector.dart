import 'package:flutter/material.dart';

class ContextSelector extends StatelessWidget {
  final String selectedContext;
  final ValueChanged<String> onContextChanged;

  const ContextSelector({
    super.key,
    required this.selectedContext,
    required this.onContextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContextButton(context, 'Hotel', Icons.business),
          const SizedBox(width: 8),
          _buildContextButton(context, 'House', Icons.home),
        ],
      ),
    );
  }

  Widget _buildContextButton(
      BuildContext context, String contextType, IconData icon) {
    final isSelected =
        selectedContext.toLowerCase() == contextType.toLowerCase();
    return GestureDetector(
      onTap: () => onContextChanged(contextType.toLowerCase()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isSelected ? Colors.white : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 6),
            Text(
              contextType,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
