import 'package:aqim/utils/plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../services/app_localization.dart';
import '../services/global_service.dart';

class SettingsScreen2 extends StatefulWidget {
  const SettingsScreen2({
    super.key,
    required this.onThemeChange,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentThemeMode,
    required this.currentLanguage,
  });

  final Function(ThemeMode) onThemeChange;
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final ThemeMode currentThemeMode;
  final String currentLanguage;

  @override
  State<SettingsScreen2> createState() => _SettingsScreen2State();
}

class _SettingsScreen2State extends State<SettingsScreen2> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('appearance')), elevation: 0),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 24.w),
        child: ListView(
          children: [
            TitleTheme(text: loc.translate('theme')),
            BuildSettingContainer(
              listWidgets: [
                BuildThemeOption(
                  mode: ThemeMode.light,
                  icon: Icons.light_mode,
                  label: loc.translate('light'),
                  cs: cs,
                  onThemeChange: widget.onThemeChange,
                  currentMode: widget.currentThemeMode,
                  isFirst: true,
                ),
                BuildThemeOption(
                  mode: ThemeMode.dark,
                  icon: Icons.dark_mode,
                  label: loc.translate('dark'),
                  cs: cs,
                  onThemeChange: widget.onThemeChange,
                  currentMode: widget.currentThemeMode,
                ),
                BuildThemeOption(
                  mode: ThemeMode.system,
                  icon: Icons.brightness_auto,
                  label: loc.translate('system_default'),
                  cs: cs,
                  onThemeChange: widget.onThemeChange,
                  currentMode: widget.currentThemeMode,
                  isLast: true,
                ),
              ],
            ),

            TitleTheme(text: loc.translate('language')),
            BuildSettingContainer(
              listWidgets: [
                BuildLanguageOption(
                  onLanguageChange: widget.onLanguageChange,
                  code: 'ms',
                  name: 'Bahasa Melayu',
                  flag: '🇲🇾',
                  currentLanguage: widget.currentLanguage,
                ),
                // BuildLanguageOption(
                //   onLanguageChange: widget.onLanguageChange,
                //   code: 'en',
                //   name: 'English',
                //   flag: '🇬🇧',
                //   currentLanguage: widget.currentLanguage,
                // ),
                // BuildLanguageOption(
                //   onLanguageChange: widget.onLanguageChange,
                //   code: 'ar',
                //   name: 'العربية',
                //   flag: '🇸🇦',
                //   currentLanguage: widget.currentLanguage,
                // ),
              ],
            ),

            // TitleTheme(text: loc.translate('time_format')),
            // BuildTimeFormat(cs: cs, loc: loc),
            TitleTheme(text: loc.translate('notification')),
            BuildSettingContainer(
              listWidgets: [
                BuildPrayerSection(
                  prayerName: 'Subuh',
                  prayerKey: 'subuh',
                  icon: Icons.wb_twilight,
                  cs: cs,
                ),
                BuildPrayerSection(
                  prayerName: 'Zohor',
                  prayerKey: 'zohor',
                  icon: Icons.wb_sunny,
                  cs: cs,
                ),
                BuildPrayerSection(
                  prayerName: 'Asar',
                  prayerKey: 'asar',
                  icon: Icons.wb_cloudy,
                  cs: cs,
                ),
                BuildPrayerSection(
                  prayerName: 'Maghrib',
                  prayerKey: 'maghrib',
                  icon: Icons.wb_twilight,
                  cs: cs,
                ),
                BuildPrayerSection(
                  prayerName: 'Isyak',
                  prayerKey: 'isyak',
                  icon: Icons.nights_stay,
                  cs: cs,
                  isLast: true,
                ),
              ],
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class TitleTheme extends StatelessWidget {
  const TitleTheme({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 24.h),
      child: Text(
        text,
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class BuildSettingContainer extends StatelessWidget {
  const BuildSettingContainer({super.key, required this.listWidgets});

  final List<Widget> listWidgets;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
      ),
      child: Column(children: listWidgets),
    );
  }
}

class BuildThemeOption extends StatefulWidget {
  const BuildThemeOption({
    super.key,
    required this.mode,
    required this.icon,
    required this.label,
    required this.cs,
    required this.onThemeChange,
    required this.currentMode,
    this.isFirst = false,
    this.isLast = false,
  });

  final ThemeMode mode;
  final ThemeMode currentMode;
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final Function(ThemeMode) onThemeChange;
  final bool isFirst;
  final bool isLast;

  @override
  State<BuildThemeOption> createState() => _BuildThemeOptionState();
}

class _BuildThemeOptionState extends State<BuildThemeOption> {
  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final isSelected = widget.currentMode == widget.mode;

    return InkWell(
      onTap: () {
        if (!mounted) return;

        setState(() {
          widget.onThemeChange(widget.mode);
        });
      },
      borderRadius: BorderRadius.vertical(
        top: widget.isFirst ? Radius.circular(radius) : Radius.zero,
        bottom: widget.isLast ? Radius.circular(radius) : Radius.zero,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer.withValues(alpha: 0.5) : null,
          border: !widget.isLast
              ? Border(
                  bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                )
              : null,
        ),
        child: ListTile(
          // contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          // dense: true,
          // visualDensity: VisualDensity(horizontal: -2, vertical: -2),
          // Leading Icon
          leading: Icon(
            widget.icon,
            size: 24.sp,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),

          // Title text
          title: Text(
            widget.label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: cs.onSurface,
            ),
          ),
          // Checkmark when selected
          trailing: isSelected
              ? Icon(Icons.check, color: cs.primary, size: 20.sp)
              : null,

          onTap: () {
            if (!mounted) return;

            setState(() {
              widget.onThemeChange(widget.mode);
            });
          },
        ),
      ),
    );
  }
}

class BuildLanguageOption extends StatefulWidget {
  const BuildLanguageOption({
    super.key,
    required this.onLanguageChange,
    required this.code,
    required this.name,
    required this.flag,
    required this.currentLanguage,
    this.isFirst = false,
    this.isLast = false,
  });

  final Function(String) onLanguageChange;
  final String code;
  final String name;
  final String flag;
  final String currentLanguage;
  final bool isFirst;
  final bool isLast;

  @override
  State<BuildLanguageOption> createState() => _BuildLanguageOptionState();
}

class _BuildLanguageOptionState extends State<BuildLanguageOption> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = widget.currentLanguage == widget.code;

    return InkWell(
      onTap: () {
        setState(() {
          widget.onLanguageChange(widget.code);
        });
      },
      borderRadius: BorderRadius.vertical(
        top: widget.isFirst ? Radius.circular(radius) : Radius.zero,
        bottom: widget.isLast ? Radius.circular(radius) : Radius.zero,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer.withValues(alpha: 0.5) : null,
          border: !widget.isLast
              ? Border(
                  bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                )
              : null,
        ),
        child: ListTile(
          // contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          // dense: true,
          // visualDensity: VisualDensity(horizontal: -2, vertical: -2),
          // FLAG (leading)
          leading: Text(widget.flag, style: TextStyle(fontSize: 24.sp)),

          // LANGUAGE NAME (title)
          title: Text(
            widget.name,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: cs.onSurface,
            ),
          ),

          // CHECK ICON IF SELECTED (trailing)
          trailing: isSelected
              ? Icon(Icons.check, size: 20.sp, color: cs.primary)
              : null,

          // Make whole tile tappable
          onTap: () {
            setState(() {
              widget.onLanguageChange(widget.code);
            });
          },
        ),
      ),
    );
  }
}

class BuildTimeFormat extends StatefulWidget {
  const BuildTimeFormat({super.key, required this.cs, required this.loc});

  final ColorScheme cs;
  final AppLocalizations loc;

  @override
  State<BuildTimeFormat> createState() => _BuildTimeFormatState();
}

class _BuildTimeFormatState extends State<BuildTimeFormat> {
  @override
  Widget build(BuildContext context) {
    final globalService = GlobalService();
    final is24Hour = globalService.is24HourFormat;

    final now = DateTime.now();
    final example = is24Hour
        ? DateFormat('HH:mm').format(now)
        : DateFormat('h:mm a').format(now);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: widget.cs.outline.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 16.w, right: 10.w),
        // dense: true,
        // visualDensity: VisualDensity(horizontal: -2, vertical: -1),
        // Leading icon
        leading: Icon(
          Icons.access_time,
          size: 24.sp,
          color: is24Hour
              ? widget.cs.primary
              : widget.cs.onSurface.withValues(alpha: 0.6),
        ),

        // Title + subtitle
        title: Text(
          widget.loc.translate('24_hour_format'),
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Text(
            '${widget.loc.translate('example')}: $example',
            style: TextStyle(
              fontSize: 12.sp,
              color: widget.cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),

        // Switch
        trailing: Transform.scale(
          scale: 0.6,
          child: Switch(
            value: is24Hour,
            onChanged: (value) async {
              await globalService.updateSetting(prefIs24HourFormat, value);
              setState(() {});
            },
          ),
        ),

        // Make entire tile clickable
        onTap: () async {
          await globalService.updateSetting(prefIs24HourFormat, !is24Hour);
          setState(() {});
        },
      ),
    );
  }
}

class BuildPrayerSection extends StatefulWidget {
  const BuildPrayerSection({
    super.key,
    required this.prayerName,
    required this.prayerKey,
    required this.icon,
    required this.cs,
    this.isLast = false,
  });

  final String prayerName;
  final String prayerKey;
  final IconData icon;
  final ColorScheme cs;
  final bool? isLast;

  @override
  State<BuildPrayerSection> createState() => _BuildPrayerSectionState();
}

class _BuildPrayerSectionState extends State<BuildPrayerSection> {
  final GlobalService _globalService = GlobalService();
  bool _getPrayerEnabled(String prayerKey) {
    switch (prayerKey) {
      case 'subuh':
        return _globalService.subuhEnabled;
      case 'zohor':
        return _globalService.zohorEnabled;
      case 'asar':
        return _globalService.asarEnabled;
      case 'maghrib':
        return _globalService.maghribEnabled;
      case 'isyak':
        return _globalService.isyakEnabled;
      default:
        return false;
    }
  }

  Future<void> _updatePrayerEnabled(String prayerKey, bool value) async {
    String prefKey;
    switch (prayerKey) {
      case 'subuh':
        prefKey = prefSubuhEnabled;
        break;
      case 'zohor':
        prefKey = prefZohorEnabled;
        break;
      case 'asar':
        prefKey = prefAsarEnabled;
        break;
      case 'maghrib':
        prefKey = prefMaghribEnabled;
        break;
      case 'isyak':
        prefKey = prefIsyakEnabled;
        break;
      default:
        return;
    }

    await _globalService.updateSetting(prefKey, value);
    if (!mounted) return;
    setState(() {});
  }

  String _getAzanName(String azanFile) {
    final azan = azanOptions.firstWhere(
      (a) => a['file'] == azanFile,
      orElse: () => azanOptions[0],
    );
    return azan['name']!;
  }

  String _getPrayerSound(String prayerKey) {
    switch (prayerKey) {
      case 'subuh':
        return _globalService.subuhSound;
      case 'zohor':
        return _globalService.zohorSound;
      case 'asar':
        return _globalService.asarSound;
      case 'maghrib':
        return _globalService.maghribSound;
      case 'isyak':
        return _globalService.isyakSound;
      default:
        return 'azan_munif_hijjaz';
    }
  }

  bool _getPrayerFullscreen(String prayerKey) {
    switch (prayerKey) {
      case 'subuh':
        return _globalService.subuhFullscreen;
      case 'zohor':
        return _globalService.zohorFullscreen;
      case 'asar':
        return _globalService.asarFullscreen;
      case 'maghrib':
        return _globalService.maghribFullscreen;
      case 'isyak':
        return _globalService.isyakFullscreen;
      default:
        return true;
    }
  }

  bool _getPrayerVibrate(String prayerKey) {
    switch (prayerKey) {
      case 'subuh':
        return _globalService.subuhVibrate;
      case 'zohor':
        return _globalService.zohorVibrate;
      case 'asar':
        return _globalService.asarVibrate;
      case 'maghrib':
        return _globalService.maghribVibrate;
      case 'isyak':
        return _globalService.isyakVibrate;
      default:
        return true;
    }
  }

  bool _getPrayerLed(String prayerKey) {
    switch (prayerKey) {
      case 'subuh':
        return _globalService.subuhLed;
      case 'zohor':
        return _globalService.zohorLed;
      case 'asar':
        return _globalService.asarLed;
      case 'maghrib':
        return _globalService.maghribLed;
      case 'isyak':
        return _globalService.isyakLed;
      default:
        return true;
    }
  }

  // bool _getPrayerReminder5Min(String prayerKey) {
  //   switch (prayerKey) {
  //     case 'subuh':
  //       return _globalService.subuhReminder5Min;
  //     case 'zohor':
  //       return _globalService.zohorReminder5Min;
  //     case 'asar':
  //       return _globalService.asarReminder5Min;
  //     case 'maghrib':
  //       return _globalService.maghribReminder5Min;
  //     case 'isyak':
  //       return _globalService.isyakReminder5Min;
  //     default:
  //       return false;
  //   }
  // }

  // bool _getPrayerReminder10Min(String prayerKey) {
  //   switch (prayerKey) {
  //     case 'subuh':
  //       return _globalService.subuhReminder10Min;
  //     case 'zohor':
  //       return _globalService.zohorReminder10Min;
  //     case 'asar':
  //       return _globalService.asarReminder10Min;
  //     case 'maghrib':
  //       return _globalService.maghribReminder10Min;
  //     case 'isyak':
  //       return _globalService.isyakReminder10Min;
  //     default:
  //       return false;
  //   }
  // }

  // bool _getPrayerReminder15Min(String prayerKey) {
  //   switch (prayerKey) {
  //     case 'subuh':
  //       return _globalService.subuhReminder15Min;
  //     case 'zohor':
  //       return _globalService.zohorReminder15Min;
  //     case 'asar':
  //       return _globalService.asarReminder15Min;
  //     case 'maghrib':
  //       return _globalService.maghribReminder15Min;
  //     case 'isyak':
  //       return _globalService.isyakReminder15Min;
  //     default:
  //       return false;
  //   }
  // }

  Future<void> _updatePrayerLed(String prayerKey, bool value) async {
    String prefKey;
    switch (prayerKey) {
      case 'subuh':
        prefKey = prefSubuhLed;
        break;
      case 'zohor':
        prefKey = prefZohorLed;
        break;
      case 'asar':
        prefKey = prefAsarLed;
        break;
      case 'maghrib':
        prefKey = prefMaghribLed;
        break;
      case 'isyak':
        prefKey = prefIsyakLed;
        break;
      default:
        return;
    }

    await _globalService.updateSetting(prefKey, value);
    setState(() {});
  }

  // Future<void> _updatePrayerReminder5Min(String prayerKey, bool value) async {
  //   String prefKey;
  //   switch (prayerKey) {
  //     case 'subuh':
  //       prefKey = prefSubuhReminder5Min;
  //       break;
  //     case 'zohor':
  //       prefKey = prefZohorReminder5Min;
  //       break;
  //     case 'asar':
  //       prefKey = prefAsarReminder5Min;
  //       break;
  //     case 'maghrib':
  //       prefKey = prefMaghribReminder5Min;
  //       break;
  //     case 'isyak':
  //       prefKey = prefIsyakReminder5Min;
  //       break;
  //     default:
  //       return;
  //   }

  //   await _globalService.updateSetting(prefKey, value);
  //   setState(() {});
  // }

  // Future<void> _updatePrayerReminder10Min(String prayerKey, bool value) async {
  //   String prefKey;
  //   switch (prayerKey) {
  //     case 'subuh':
  //       prefKey = prefSubuhReminder10Min;
  //       break;
  //     case 'zohor':
  //       prefKey = prefZohorReminder10Min;
  //       break;
  //     case 'asar':
  //       prefKey = prefAsarReminder10Min;
  //       break;
  //     case 'maghrib':
  //       prefKey = prefMaghribReminder10Min;
  //       break;
  //     case 'isyak':
  //       prefKey = prefIsyakReminder10Min;
  //       break;
  //     default:
  //       return;
  //   }

  //   await _globalService.updateSetting(prefKey, value);
  //   setState(() {});
  // }

  // Future<void> _updatePrayerReminder15Min(String prayerKey, bool value) async {
  //   String prefKey;
  //   switch (prayerKey) {
  //     case 'subuh':
  //       prefKey = prefSubuhReminder15Min;
  //       break;
  //     case 'zohor':
  //       prefKey = prefZohorReminder15Min;
  //       break;
  //     case 'asar':
  //       prefKey = prefAsarReminder15Min;
  //       break;
  //     case 'maghrib':
  //       prefKey = prefMaghribReminder15Min;
  //       break;
  //     case 'isyak':
  //       prefKey = prefIsyakReminder15Min;
  //       break;
  //     default:
  //       return;
  //   }

  //   await _globalService.updateSetting(prefKey, value);
  //   setState(() {});
  // }

  Future<void> _updatePrayerFullscreen(String prayerKey, bool value) async {
    String prefKey;
    switch (prayerKey) {
      case 'subuh':
        prefKey = prefSubuhFullscreen;
        break;
      case 'zohor':
        prefKey = prefZohorFullscreen;
        break;
      case 'asar':
        prefKey = prefAsarFullscreen;
        break;
      case 'maghrib':
        prefKey = prefMaghribFullscreen;
        break;
      case 'isyak':
        prefKey = prefIsyakFullscreen;
        break;
      default:
        return;
    }

    await _globalService.updateSetting(prefKey, value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _getPrayerEnabled(widget.prayerKey);
    return Column(
      crossAxisAlignment: .start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.w, right: 3.w),
          // dense: true,
          // visualDensity: VisualDensity(horizontal: -2, vertical: 1),
          leading: Icon(widget.icon),
          title: Text(
            widget.prayerName,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
          ),
          trailing: Transform.scale(
            scale: 0.6,
            child: Switch(
              value: isEnabled,
              onChanged: (value) {
                _updatePrayerEnabled(widget.prayerKey, value);
              },
            ),
          ),
        ),

        ListTile(
          contentPadding: EdgeInsets.only(left: 72.w, right: 16.w),
          dense: true,
          visualDensity: VisualDensity(horizontal: -2, vertical: -2),
          title: Text('Pilih Azan', style: TextStyle(fontSize: 14.sp)),
          enabled: isEnabled,
          subtitle: Text(
            _getAzanName(_getPrayerSound(widget.prayerKey)),
            style: TextStyle(fontSize: 12.sp),
          ),
          trailing: Icon(Icons.chevron_right, size: 20.sp),
          onTap: () => _showAzanPicker(widget.prayerKey, widget.cs),
        ),

        // Display Mode
        ListTile(
          enabled: isEnabled,
          contentPadding: EdgeInsets.only(left: 72.w, right: 16.w),
          dense: true,
          visualDensity: VisualDensity(horizontal: -2, vertical: -2),
          title: Text('Mod Paparan', style: TextStyle(fontSize: 14.sp)),
          subtitle: Text(
            _getPrayerFullscreen(widget.prayerKey)
                ? 'Skrin Penuh'
                : 'Notifikasi',
            style: TextStyle(fontSize: 12.sp),
          ),
          trailing: Icon(Icons.chevron_right, size: 20.sp),
          onTap: () => _showDisplayModePicker(widget.prayerKey, widget.cs),
        ),

        // Vibration
        ListTile(
          enabled: isEnabled,
          contentPadding: EdgeInsets.only(left: 72.w, right: 5.w),
          dense: true,
          visualDensity: VisualDensity(horizontal: -2, vertical: -2),
          title: Text('Getar', style: TextStyle(fontSize: 14.sp)),
          trailing: Transform.scale(
            scale: 0.60,
            child: Switch(
              value: _getPrayerVibrate(widget.prayerKey),
              onChanged: isEnabled
                  ? (value) => _updatePrayerVibrate(widget.prayerKey, value)
                  : null,
            ),
          ),
        ),

        // LED
        ListTile(
          enabled: isEnabled,
          contentPadding: EdgeInsets.only(left: 72.w, right: 5.w),
          dense: true,
          visualDensity: VisualDensity(horizontal: -2, vertical: -2),
          title: Text('Lampu LED', style: TextStyle(fontSize: 14.sp)),
          trailing: Transform.scale(
            scale: 0.60,
            child: Switch(
              value: _getPrayerLed(widget.prayerKey),
              onChanged: isEnabled
                  ? (value) => _updatePrayerLed(widget.prayerKey, value)
                  : null,
            ),
          ),
        ),
        // Reminder Section Header

        // 5 minutes before
        // ListTile(
        //   enabled: isEnabled,
        //   contentPadding: EdgeInsets.only(left: 72.w, right: 5.w),
        //   dense: true,
        //   visualDensity: VisualDensity(horizontal: -2, vertical: -2),
        //   title: Text(
        //     'Peringatan sebelum azan',
        //     style: TextStyle(fontSize: 14.sp),
        //   ),
        //   subtitle: Text('5 minit sebelum', style: TextStyle(fontSize: 12.sp)),
        //   trailing: Transform.scale(
        //     scale: 0.6,
        //     child: Switch(
        //       value: _getPrayerReminder5Min(widget.prayerKey),
        //       onChanged: isEnabled
        //           ? (value) =>
        //                 _updatePrayerReminder5Min(widget.prayerKey, value)
        //           : null,
        //     ),
        //   ),
        // ),
        // ListTile(
        //   enabled: isEnabled,
        //   contentPadding: EdgeInsets.only(left: 72.w, right: 5.w),
        //   dense: true,
        //   visualDensity: VisualDensity(horizontal: -2, vertical: -2),
        //   title: Text(
        //     'Peringatan sebelum azan',
        //     style: TextStyle(fontSize: 14.sp),
        //   ),
        //   subtitle: Text('10 minit sebelum', style: TextStyle(fontSize: 12.sp)),
        //   trailing: Transform.scale(
        //     scale: 0.6,
        //     child: Switch(
        //       value: _getPrayerReminder10Min(widget.prayerKey),
        //       onChanged: isEnabled
        //           ? (value) =>
        //                 _updatePrayerReminder10Min(widget.prayerKey, value)
        //           : null,
        //     ),
        //   ),
        // ),
        // ListTile(
        //   enabled: isEnabled,
        //   contentPadding: EdgeInsets.only(left: 72.w, right: 5.w),
        //   dense: true,
        //   visualDensity: VisualDensity(horizontal: -2, vertical: -2),
        //   title: Text(
        //     'Peringatan sebelum azan',
        //     style: TextStyle(fontSize: 14.sp),
        //   ),
        //   subtitle: Text('15 minit sebelum', style: TextStyle(fontSize: 12.sp)),
        //   trailing: Transform.scale(
        //     scale: 0.6,
        //     child: Switch(
        //       value: _getPrayerReminder15Min(widget.prayerKey),
        //       onChanged: isEnabled
        //           ? (value) =>
        //                 _updatePrayerReminder15Min(widget.prayerKey, value)
        //           : null,
        //     ),
        //   ),
        // ),
        SizedBox(height: 13.h),
        !widget.isLast! ? Divider() : SizedBox.shrink(),
      ],
    );
  }

  void _showAzanPicker(String prayerKey, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final currentSound = _getPrayerSound(prayerKey);
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Text(
                  'Pilih Azan',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Divider(height: 1.h),
              ...azanOptions.map((azan) {
                final isSelected = currentSound == azan['file'];
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? colorScheme.primary : null,
                  ),
                  title: Text(azan['name']!),
                  trailing: isSelected
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    _updatePrayerSound(prayerKey, azan['file']!);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updatePrayerSound(String prayerKey, String value) async {
    String prefKey;
    switch (prayerKey) {
      case 'subuh':
        prefKey = prefSubuhSound;
        break;
      case 'zohor':
        prefKey = prefZohorSound;
        break;
      case 'asar':
        prefKey = prefAsarSound;
        break;
      case 'maghrib':
        prefKey = prefMaghribSound;
        break;
      case 'isyak':
        prefKey = prefIsyakSound;
        break;
      default:
        return;
    }

    await _globalService.updateSetting(prefKey, value);
    setState(() {});
  }

  Future<void> _updatePrayerVibrate(String prayerKey, bool value) async {
    String prefKey;
    switch (prayerKey) {
      case 'subuh':
        prefKey = prefSubuhVibrate;
        break;
      case 'zohor':
        prefKey = prefZohorVibrate;
        break;
      case 'asar':
        prefKey = prefAsarVibrate;
        break;
      case 'maghrib':
        prefKey = prefMaghribVibrate;
        break;
      case 'isyak':
        prefKey = prefIsyakVibrate;
        break;
      default:
        return;
    }

    await _globalService.updateSetting(prefKey, value);
    setState(() {});
  }

  void _showDisplayModePicker(String prayerKey, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final isFullscreen = _getPrayerFullscreen(prayerKey);
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Text(
                  'Mod Paparan',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Divider(height: 1.h),
              ListTile(
                leading: Icon(
                  isFullscreen
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isFullscreen ? colorScheme.primary : null,
                ),
                title: const Text('Skrin Penuh'),
                subtitle: const Text('Paparkan azan dalam mod skrin penuh'),
                trailing: isFullscreen
                    ? Icon(Icons.check, color: colorScheme.primary)
                    : null,
                onTap: () {
                  _updatePrayerFullscreen(prayerKey, true);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  !isFullscreen
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: !isFullscreen ? colorScheme.primary : null,
                ),
                title: const Text('Notifikasi Sahaja'),
                subtitle: const Text('Paparkan notifikasi kecil sahaja'),
                trailing: !isFullscreen
                    ? Icon(Icons.check, color: colorScheme.primary)
                    : null,
                onTap: () {
                  _updatePrayerFullscreen(prayerKey, false);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
