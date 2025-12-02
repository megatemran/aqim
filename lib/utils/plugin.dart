import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/prayer_time_model.dart';

// MAIN
final String prefIsLegalAccepted = 'isLegalAccepted';
final String prefIsFirstLaunch = 'isFirstLaunch';
final String prefIsPermission = 'isPermission';
final String prefThemeMode = 'themeMode';
final String prefLanguageCode = 'languageCode';

// LOCATION
final String prefCachedLocation = 'cached_location';
final String prefCachedLocationTime = 'location_cache_time';

//SETTINGS
final String prefNotificationsEnabled = 'notificationsEnabled';
final String prefSoundEnabled = 'soundEnabled';
final String prefVibrationEnabled = 'vibrationEnabled';
final String prefIs24HourFormat = 'is24HourFormat';

// Prayer-specific settings (enabled/disabled)
final String prefSubuhEnabled = 'subuhEnabled';
final String prefZohorEnabled = 'zohorEnabled';
final String prefAsarEnabled = 'asarEnabled';
final String prefMaghribEnabled = 'maghribEnabled';
final String prefIsyakEnabled = 'isyakEnabled';

// Prayer sounds
final String prefSubuhSound = 'subuhSound';
final String prefZohorSound = 'zohorSound';
final String prefAsarSound = 'asarSound';
final String prefMaghribSound = 'maghribSound';
final String prefIsyakSound = 'isyakSound';

// Prayer vibration settings
final String prefSubuhVibrate = 'subuhVibrate';
final String prefZohorVibrate = 'zohorVibrate';
final String prefAsarVibrate = 'asarVibrate';
final String prefMaghribVibrate = 'maghribVibrate';
final String prefIsyakVibrate = 'isyakVibrate';

// Prayer LED settings
final String prefSubuhLed = 'subuhLed';
final String prefZohorLed = 'zohorLed';
final String prefAsarLed = 'asarLed';
final String prefMaghribLed = 'maghribLed';
final String prefIsyakLed = 'isyakLed';

// Prayer fullscreen settings (true = fullscreen, false = notification only)
final String prefSubuhFullscreen = 'subuhFullscreen';
final String prefZohorFullscreen = 'zohorFullscreen';
final String prefAsarFullscreen = 'asarFullscreen';
final String prefMaghribFullscreen = 'maghribFullscreen';
final String prefIsyakFullscreen = 'isyakFullscreen';

// Prayer reminder settings (before azan)
final String prefSubuhReminder5Min = 'subuhReminder5Min';
final String prefSubuhReminder10Min = 'subuhReminder10Min';
final String prefSubuhReminder15Min = 'subuhReminder15Min';
final String prefZohorReminder5Min = 'zohorReminder5Min';
final String prefZohorReminder10Min = 'zohorReminder10Min';
final String prefZohorReminder15Min = 'zohorReminder15Min';
final String prefAsarReminder5Min = 'asarReminder5Min';
final String prefAsarReminder10Min = 'asarReminder10Min';
final String prefAsarReminder15Min = 'asarReminder15Min';
final String prefMaghribReminder5Min = 'maghribReminder5Min';
final String prefMaghribReminder10Min = 'maghribReminder10Min';
final String prefMaghribReminder15Min = 'maghribReminder15Min';
final String prefIsyakReminder5Min = 'isyakReminder5Min';
final String prefIsyakReminder10Min = 'isyakReminder10Min';
final String prefIsyakReminder15Min = 'isyakReminder15Min';

//NOTIFICATION
final String channelGroupKeyAzan = 'azan_group';
final String channelKeyAzan = 'azan_notifications';
final String channelNameAzan = 'Azan Notifications';
final String channelDescriptionAzan = 'Play Azan Notifications';

final String channelGroupKeySimple = 'simple_group';
final String channelKeySimple = 'simple_notifications';
final String channelNameSimple = 'Simple Notifications';
final String channelDescriptionSimple = 'Ala Simple je Notifications ni';
// final NotificationActionButton buttonNotiPause = NotificationActionButton(
//   key: 'PAUSE',
//   icon: 'resource://drawable/res_ic_pause',
//   label: 'Pause',
//   autoDismissible: false,
//   showInCompactView: true,
//   actionType: ActionType.KeepOnTop,
// );
// final buttonNotiPlay = NotificationActionButton(
//   key: 'PLAY', // ✅ Show play when paused
//   icon: 'resource://drawable/res_ic_play',
//   label: 'Play',
//   autoDismissible: false,
//   showInCompactView: true,
//   actionType: ActionType.KeepOnTop,
// );

// final buttonNotiClose = NotificationActionButton(
//   key: 'CLOSE',
//   icon: 'resource://drawable/res_ic_stop',
//   label: 'Close',
//   autoDismissible: true,
//   showInCompactView: true,
//   actionType: ActionType.KeepOnTop,
// );

// final buttonNotiRewind = NotificationActionButton(
//   key: 'REWIND',
//   icon: 'resource://drawable/res_ic_prev',
//   label: 'Back 10s',
//   autoDismissible: false,
//   showInCompactView: true,
//   actionType: ActionType.KeepOnTop,
// );
// final buttonNotiForward = NotificationActionButton(
//   key: 'FORWARD',
//   icon: 'resource://drawable/res_ic_next',
//   label: 'Forward 10s',
//   autoDismissible: false,
//   showInCompactView: true,
//   actionType: ActionType.KeepOnTop,
// );
// final buttonNotiFullscreen = NotificationActionButton(
//   key: 'FULLSCREEN',
//   icon: 'resource://drawable/res_ic_fullscreen',
//   label: 'Fullscreen',
//   autoDismissible: false,
//   showInCompactView: true,
//   actionType: ActionType.KeepOnTop,
// );
bool isShowAds = true;
PrayerTimeData? prayerTimeData;
final double radius = 12.r;

final List<Map<String, String>> azanOptions = [
  {
    'name': 'Azan Munif Hijjaz',
    'file': 'azan_munif_hijjaz',
    'channelId': 'azan_munif_hijjaz_notification',
    'channelName': 'Azan Munif Hijjaz Notifications',
    'channelDescription': 'Play Azan Munif Hijjaz Notifications',
  },
  {
    'name': 'Azan Maghrib Tv3 2018',
    'file': 'azan_maghrib_tv3_2018',
    'channelId': 'azan_maghrib_tv3_notification',
    'channelName': 'Azan Maghrib TV3 Notification',
    'channelDescription': 'Play Azan Maghrib TV3 Notifications',
  },
  // {'name': 'Azan Al-Aqsa', 'file': 'azan_alaqsa.mp3'},
  // {'name': 'Azan Mesir', 'file': 'azan_mesir.mp3'},
  //{'name': 'Azan Turkey', 'file': 'azan_turkey.mp3'},
  //{'name': 'Azan Malaysia', 'file': 'azan_malaysia'},
  // {'name': 'Azan Sheikh Sudais', 'file': 'azan_sudais'},
  // {'name': 'Azan Mishary Rashid', 'file': 'azan_mishary'},
  // {'name': 'Azan Abdul Basit', 'file': 'azan_abdul_basit'},
];
