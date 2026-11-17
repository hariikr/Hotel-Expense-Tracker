import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/language_service.dart';
import '../../utils/app_theme.dart';

String entryT(String en, String ml) =>
    LanguageService.getLanguageCode() == 'ml' ? ml : en;

final NumberFormat entryMoney =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

final List<TextInputFormatter> amountInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}(\.\d{0,2})?')),
];

double parseAmount(String text) => double.tryParse(text.trim()) ?? 0;

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Today / Yesterday / pick-a-date chips. Most entries are for today or the
/// day before, so those are one tap instead of opening the date picker.
class EntryDatePicker extends StatelessWidget {
  final DateTime date;
  final Color color;
  final ValueChanged<DateTime> onChanged;

  const EntryDatePicker({
    super.key,
    required this.date,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final isToday = _sameDay(date, today);
    final isYesterday = _sameDay(date, yesterday);
    final isOther = !isToday && !isYesterday;

    Widget chip(String label, bool selected, VoidCallback onTap,
        {IconData? icon}) {
      return ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 18, color: selected ? color : AppTheme.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(label),
          ],
        ),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? color : AppTheme.textPrimary,
        ),
        selectedColor: color.withValues(alpha: 0.12),
        backgroundColor: Colors.white,
        side: BorderSide(
            color: selected ? color : AppTheme.darkSurface, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(entryT('Today', 'ഇന്ന്'), isToday, () => onChanged(today)),
        chip(entryT('Yesterday', 'ഇന്നലെ'), isYesterday,
            () => onChanged(yesterday)),
        chip(
          isOther ? DateFormat('d MMM yyyy').format(date) : entryT('Pick date', 'തീയതി'),
          isOther,
          icon: Icons.calendar_today,
          () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: today,
            );
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }
}

/// Sticky footer with the running total and the save button.
class EntryBottomBar extends StatelessWidget {
  final String totalLabel;
  final double total;
  final String? detail;
  final String buttonLabel;
  final Color color;
  final bool loading;
  final VoidCallback? onSave;

  const EntryBottomBar({
    super.key,
    required this.totalLabel,
    required this.total,
    required this.buttonLabel,
    required this.color,
    required this.loading,
    required this.onSave,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.darkSurface)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      entryMoney.format(total),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: total > 0 ? color : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: loading ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  disabledBackgroundColor: AppTheme.darkSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded, size: 24),
                label: Text(buttonLabel, style: const TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks before throwing away amounts that were typed but not saved.
Future<bool> confirmDiscardEntries(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(entryT('Discard entries?', 'എൻട്രികൾ ഒഴിവാക്കണോ?')),
      content: Text(entryT(
        'The amounts you typed have not been saved.',
        'നിങ്ങൾ നൽകിയ തുകകൾ സേവ് ചെയ്തിട്ടില്ല.',
      )),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(entryT('Keep editing', 'തുടരുക')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppTheme.lossColor),
          child: Text(entryT('Discard', 'ഒഴിവാക്കുക')),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showEntrySnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppTheme.lossColor : AppTheme.textPrimary,
    ),
  );
}
