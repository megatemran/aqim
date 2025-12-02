import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../services/app_localization.dart';
import '../services/global_service.dart';
import '../utils/plugin.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final String currentLanguage;
  final Function(ThemeMode) onThemeChange;
  final Function(String) onLanguageChange;

  const AppearanceSettingsScreen({
    super.key,
    required this.currentThemeMode,
    required this.currentLanguage,
    required this.onThemeChange,
    required this.onLanguageChange,
  });

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  final GlobalService _globalService = GlobalService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('appearance')), elevation: 0),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Theme Section
          Text(
            loc.translate('theme'),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          _buildThemeSelector(colorScheme, loc),

          SizedBox(height: 24.h),

          // Language Section
          Text(
            loc.translate('language'),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          _buildLanguageSelector(colorScheme, loc),

          SizedBox(height: 24.h),

          // Time Format Section
          Text(
            loc.translate('time_format'),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          _buildTimeFormatSetting(colorScheme, loc),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ColorScheme colorScheme, AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildThemeOption(
            ThemeMode.light,
            Icons.light_mode,
            loc.translate('light'),
            colorScheme,
            isFirst: true,
          ),
          _buildThemeOption(
            ThemeMode.dark,
            Icons.dark_mode,
            loc.translate('dark'),
            colorScheme,
          ),
          _buildThemeOption(
            ThemeMode.system,
            Icons.brightness_auto,
            loc.translate('system_default'),
            colorScheme,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    ThemeMode mode,
    IconData icon,
    String label,
    ColorScheme colorScheme, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = widget.currentThemeMode == mode;

    return InkWell(
      onTap: () {
        widget.onThemeChange(mode);
        setState(() {});
      },
      borderRadius: BorderRadius.vertical(
        top: isFirst ? Radius.circular(radius) : Radius.zero,
        bottom: isLast ? Radius.circular(radius) : Radius.zero,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : null,
          border: !isLast
              ? Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Icon(
              icon,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: colorScheme.primary, size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(ColorScheme colorScheme, AppLocalizations loc) {
    final languages = [
      {'code': 'ms', 'name': 'Bahasa Melayu', 'flag': '🇲🇾'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: languages.asMap().entries.map((entry) {
          final index = entry.key;
          final lang = entry.value;
          final isSelected = widget.currentLanguage == lang['code'];
          final isFirst = index == 0;
          final isLast = index == languages.length - 1;

          return InkWell(
            onTap: () {
              widget.onLanguageChange(lang['code']!);
              setState(() {});
            },
            borderRadius: BorderRadius.vertical(
              top: isFirst ? Radius.circular(radius) : Radius.zero,
              bottom: isLast ? Radius.circular(radius) : Radius.zero,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : null,
                border: !isLast
                    ? Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(lang['flag']!, style: TextStyle(fontSize: 24.sp)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      lang['name']!,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check, color: colorScheme.primary, size: 20.sp),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeFormatSetting(
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    final is24Hour = _globalService.is24HourFormat;
    final now = DateTime.now();
    final example = is24Hour
        ? DateFormat('HH:mm').format(now)
        : DateFormat('h:mm a').format(now);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: is24Hour
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('24_hour_format'),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${loc.translate('example')}: $example',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: is24Hour,
              onChanged: (value) async {
                await _globalService.updateSetting(prefIs24HourFormat, value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
