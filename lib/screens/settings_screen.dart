import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'package:city_flow_app/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Update status bar based on theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTab, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Appearance
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 8),
          _buildThemeSelector(themeProvider),
          
          const SizedBox(height: 24),
          
          // Language
          _buildSectionHeader(l10n.language),
          const SizedBox(height: 8),
          _buildLanguageSelector(languageProvider),
          
          const SizedBox(height: 24),
          
          // Notifications
          _buildSectionHeader('Notifications'),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? 'Notifications Enabled' : 'Notifications Disabled'),
                    backgroundColor: value ? AppTheme.accentGreen : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  ),
                );
              },
              activeColor: AppTheme.accentGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
      ),
    );
  }

  Widget _buildThemeSelector(ThemeProvider themeProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Column(
        children: [
          _buildThemeOption(
            icon: Icons.wb_sunny_outlined,
            title: 'Light',
            isSelected: themeProvider.themeMode == ThemeMode.light,
            onTap: () => themeProvider.setTheme(ThemeMode.light),
            showBorder: true,
          ),
          _buildThemeOption(
            icon: Icons.nightlight_outlined,
            title: 'Dark',
            isSelected: themeProvider.themeMode == ThemeMode.dark,
            onTap: () => themeProvider.setTheme(ThemeMode.dark),
            showBorder: true,
          ),
          _buildThemeOption(
            icon: Icons.brightness_auto_outlined,
            title: 'System',
            isSelected: themeProvider.themeMode == ThemeMode.system,
            onTap: () => themeProvider.setTheme(ThemeMode.system),
            showBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool showBorder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: showBorder ? Border(
            bottom: BorderSide(
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            ),
          ) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected 
                  ? AppTheme.accentGreen
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 22,
                color: AppTheme.accentGreen,
              )
            else
              Icon(
                Icons.circle_outlined,
                size: 22,
                color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Column(
        children: [
          _buildLanguageOption(
            flag: '🇺🇸',
            title: 'English',
            isSelected: languageProvider.currentLocale.languageCode == 'en',
            onTap: () => languageProvider.changeLanguage(const Locale('en')),
            showBorder: true,
          ),
          _buildLanguageOption(
            flag: '🇮🇳',
            title: 'हिंदी',
            isSelected: languageProvider.currentLocale.languageCode == 'hi',
            onTap: () => languageProvider.changeLanguage(const Locale('hi')),
            showBorder: true,
          ),
          _buildLanguageOption(
            flag: '🇮🇳',
            title: 'मराठी',
            isSelected: languageProvider.currentLocale.languageCode == 'mr',
            onTap: () => languageProvider.changeLanguage(const Locale('mr')),
            showBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String flag,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool showBorder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: showBorder ? Border(
            bottom: BorderSide(
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            ),
          ) : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 22,
                color: AppTheme.accentGreen,
              )
            else
              Icon(
                Icons.circle_outlined,
                size: 22,
                color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
