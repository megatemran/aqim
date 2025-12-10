import 'package:aqim/utils/plugin.dart';
import 'package:audioplayers/audioplayers.dart';
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
        padding: EdgeInsets.symmetric(horizontal: 24.w),
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
              ],
            ),

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
          leading: Icon(
            widget.icon,
            size: 24.sp,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),

          title: Text(
            widget.label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: cs.onSurface,
            ),
          ),
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
          leading: Text(widget.flag, style: TextStyle(fontSize: 24.sp)),

          title: Text(
            widget.name,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: cs.onSurface,
            ),
          ),

          trailing: isSelected
              ? Icon(Icons.check, size: 20.sp, color: cs.primary)
              : null,

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
        leading: Icon(
          Icons.access_time,
          size: 24.sp,
          color: is24Hour
              ? widget.cs.primary
              : widget.cs.onSurface.withValues(alpha: 0.6),
        ),

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

  // Azan preview audio player state
  AudioPlayer? _azanPreviewPlayer;
  int?
  _currentAudioIndex; // Track which audio is playing (for player display only)
  bool _isAzanPlaying = false;
  bool _isAzanPaused = false;
  Duration _azanCurrentPosition = Duration.zero;
  Duration _azanTotalDuration = Duration.zero;
  Function? _modalSetState;

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
        return 'azan_isyak_munif_hijjaz';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.w, right: 3.w),
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

        SizedBox(height: 13.h),
        !widget.isLast! ? Divider() : SizedBox.shrink(),
      ],
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
    if (mounted) {
      setState(() {});
    }
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
              SizedBox(height: 50.h),
            ],
          ),
        );
      },
    );
  }

  // Audio Player Lifecycle Methods
  void _initAzanPreviewPlayer() {
    _azanPreviewPlayer = AudioPlayer();

    _azanPreviewPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) {
        _isAzanPlaying = state == PlayerState.playing;
        _isAzanPaused = state == PlayerState.paused;
        _modalSetState?.call(() {});
      }
    });

    _azanPreviewPlayer!.onDurationChanged.listen((duration) {
      if (mounted) {
        _azanTotalDuration = duration;
        _modalSetState?.call(() {});
      }
    });

    _azanPreviewPlayer!.onPositionChanged.listen((position) {
      if (mounted) {
        _azanCurrentPosition = position;
        _modalSetState?.call(() {});
      }
    });

    _azanPreviewPlayer!.onPlayerComplete.listen((_) {
      if (mounted) {
        _isAzanPlaying = false;
        _azanCurrentPosition = Duration.zero;
        _modalSetState?.call(() {});
      }
    });
  }

  void _disposeAzanPreviewPlayer() {
    _azanPreviewPlayer?.stop();
    _azanPreviewPlayer?.dispose();
    _azanPreviewPlayer = null;
  }

  Future<void> _playAzan(int index, String azanFile) async {
    // Update which audio is playing (for player display)
    _currentAudioIndex = index;

    String soundFile = azanFile.endsWith('.mp3') ? azanFile : '$azanFile.mp3';
    await _azanPreviewPlayer?.stop();
    await _azanPreviewPlayer?.play(AssetSource('sounds/$soundFile'));
  }

  Future<void> _pauseResumeAzan() async {
    if (_isAzanPlaying) {
      await _azanPreviewPlayer?.pause();
    } else if (_isAzanPaused) {
      await _azanPreviewPlayer?.resume();
    }
  }

  Future<void> _stopAzan() async {
    await _azanPreviewPlayer?.stop();
    _isAzanPlaying = false;
    _isAzanPaused = false;
    _azanCurrentPosition = Duration.zero;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showAzanPicker(String prayerKey, ColorScheme colorScheme) {
    // Initialize audio player and reset state
    _initAzanPreviewPlayer();

    // Get saved sound and find index
    final savedSound = _getPrayerSound(prayerKey);
    final savedIndex = azanOptions.indexWhere((a) => a['file'] == savedSound);

    // Set initial audio index to saved azan
    _currentAudioIndex = savedIndex != -1 ? savedIndex : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            _modalSetState = setModalState;

            // Get CURRENT saved sound - this determines "Dipilih" badge
            final currentSavedSound = _getPrayerSound(prayerKey);

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Azan ${widget.prayerName}',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _disposeAzanPreviewPlayer();
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close_rounded, size: 24.sp),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1.h, thickness: 1),

                  // Audio Player Section
                  Container(
                    margin: EdgeInsets.all(20.w),
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Track Info
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                Icons.music_note,
                                color: colorScheme.onPrimaryContainer,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isAzanPlaying || _isAzanPaused
                                        ? 'Sedang Dimainkan'
                                        : 'Pratonton',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    azanOptions[_currentAudioIndex ??
                                        0]['name']!,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // Seekable Progress Slider
                        Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4.h,
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 8.r,
                                ),
                                overlayShape: RoundSliderOverlayShape(
                                  overlayRadius: 16.r,
                                ),
                                activeTrackColor: colorScheme.primary,
                                inactiveTrackColor:
                                    colorScheme.surfaceContainerHighest,
                                thumbColor: colorScheme.primary,
                                overlayColor: colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              child: Slider(
                                value: _azanTotalDuration.inSeconds > 0
                                    ? _azanCurrentPosition.inSeconds
                                          .toDouble()
                                          .clamp(
                                            0.0,
                                            _azanTotalDuration.inSeconds
                                                .toDouble(),
                                          )
                                    : 0.0,
                                min: 0.0,
                                max: _azanTotalDuration.inSeconds > 0
                                    ? _azanTotalDuration.inSeconds.toDouble()
                                    : 1.0,
                                onChanged: (value) async {
                                  // Seek to new position when user drags
                                  final newPosition = Duration(
                                    seconds: value.toInt(),
                                  );
                                  await _azanPreviewPlayer?.seek(newPosition);
                                  setModalState(() {
                                    _azanCurrentPosition = newPosition;
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_azanCurrentPosition),
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12.sp,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_azanTotalDuration),
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12.sp,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),

                        // Player Controls - ALWAYS show play button (never changes based on list selection)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Previous
                            IconButton(
                              onPressed: () async {
                                await _azanPreviewPlayer?.stop();
                                int newIndex =
                                    (_currentAudioIndex == 0 ||
                                        _currentAudioIndex == null)
                                    ? azanOptions.length - 1
                                    : _currentAudioIndex! - 1;

                                _currentAudioIndex = newIndex;
                                await _playAzan(
                                  newIndex,
                                  azanOptions[newIndex]['file']!,
                                );

                                // Save selection when navigating with prev button
                                await _updatePrayerSound(
                                  prayerKey,
                                  azanOptions[newIndex]['file']!,
                                );

                                setModalState(() {});
                              },
                              icon: Icon(Icons.skip_previous_rounded),
                              iconSize: 32.sp,
                              color: colorScheme.onSurface,
                            ),

                            SizedBox(width: 8.w),

                            // Play/Pause - Icon changes based on playing state only
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  if (_isAzanPlaying) {
                                    await _pauseResumeAzan();
                                  } else if (_isAzanPaused) {
                                    await _pauseResumeAzan();
                                  } else {
                                    // Not playing, start from current audio index
                                    final selectedFile =
                                        azanOptions[_currentAudioIndex ??
                                            0]['file']!;
                                    await _playAzan(
                                      _currentAudioIndex ?? 0,
                                      selectedFile,
                                    );
                                  }
                                  setModalState(() {});
                                },
                                icon: Icon(
                                  _isAzanPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                iconSize: 32.sp,
                                color: colorScheme.onPrimary,
                                padding: EdgeInsets.all(12.w),
                              ),
                            ),

                            SizedBox(width: 8.w),
                            // Stop
                            IconButton(
                              onPressed: () async {
                                await _stopAzan();
                                setModalState(() {});
                              },
                              icon: Icon(Icons.stop_rounded),
                              iconSize: 32.sp,
                              color: colorScheme.onSurface,
                            ),
                            SizedBox(width: 8.w),
                            // Next
                            IconButton(
                              onPressed: () async {
                                await _azanPreviewPlayer?.stop();
                                int newIndex =
                                    (_currentAudioIndex == null ||
                                        _currentAudioIndex! >=
                                            azanOptions.length - 1)
                                    ? 0
                                    : _currentAudioIndex! + 1;

                                _currentAudioIndex = newIndex;
                                await _playAzan(
                                  newIndex,
                                  azanOptions[newIndex]['file']!,
                                );

                                // Save selection when navigating with next button
                                await _updatePrayerSound(
                                  prayerKey,
                                  azanOptions[newIndex]['file']!,
                                );

                                setModalState(() {});
                              },
                              icon: Icon(Icons.skip_next_rounded),
                              iconSize: 32.sp,
                              color: colorScheme.onSurface,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // List of Azans - UI stays stable, only "Dipilih" badge changes on save
                  Expanded(
                    child: ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        // vertical: 12.h,
                        horizontal: 16.w,
                      ),
                      itemCount: azanOptions.length,
                      itemBuilder: (context, index) {
                        final azan = azanOptions[index];

                        // "Dipilih" badge shows for SAVED selection only
                        final isSavedSelection =
                            currentSavedSound == azan['file'];

                        return Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            onTap: () async {
                              // Play audio preview
                              _currentAudioIndex = index;
                              await _playAzan(index, azan['file']!);

                              // Save selection immediately
                              await _updatePrayerSound(
                                prayerKey,
                                azan['file']!,
                              );

                              // Refresh to show "Dipilih" badge
                              setModalState(() {});
                            },
                            leading: Icon(
                              isSavedSelection
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSavedSelection
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              size: 24.sp,
                            ),
                            title: Text(
                              azan['name']!,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: isSavedSelection
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            // Show "Dipilih" ONLY for saved selection
                            trailing: isSavedSelection
                                ? Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      'Dipilih',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  // SizedBox(height: 40.h),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _modalSetState = null;
      _disposeAzanPreviewPlayer();
      // Rebuild parent to show updated subtitle
      if (mounted) setState(() {});
    });
  }
}
