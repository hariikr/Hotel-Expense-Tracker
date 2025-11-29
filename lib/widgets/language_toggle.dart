import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../utils/app_theme.dart';

class LanguageToggle extends StatefulWidget {
  final Function()? onLanguageChanged;

  const LanguageToggle({super.key, this.onLanguageChanged});

  @override
  State<LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<LanguageToggle> {
  @override
  Widget build(BuildContext context) {
    final isEnglish = LanguageService.currentLanguage == AppLanguage.english;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageButton(
            'English',
            isEnglish,
            () => _switchLanguage(AppLanguage.english),
          ),
          _buildLanguageButton(
            'മലയാളം',
            !isEnglish,
            () => _switchLanguage(AppLanguage.malayalam),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _switchLanguage(AppLanguage language) async {
    await LanguageService.setLanguage(language);
    setState(() {});
    widget.onLanguageChanged?.call();
  }
}
