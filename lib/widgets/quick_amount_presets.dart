import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class QuickAmountPresets extends StatelessWidget {
  final Function(String) onAmountSelected;
  final Color? color;

  const QuickAmountPresets({
    super.key,
    required this.onAmountSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final presetAmounts = ['100', '500', '1000', '2000', '5000'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Add',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presetAmounts.map((amount) {
            return _buildPresetButton(amount);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String amount) {
    return Material(
      color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onAmountSelected(amount),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 16,
                color: color ?? AppTheme.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                '₹$amount',
                style: TextStyle(
                  color: color ?? AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
