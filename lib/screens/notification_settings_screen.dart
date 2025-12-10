// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../services/global_service.dart';
// import '../utils/plugin.dart';

// class NotificationSettingsScreen extends StatefulWidget {
//   const NotificationSettingsScreen({super.key});

//   @override
//   State<NotificationSettingsScreen> createState() =>
//       _NotificationSettingsScreenState();
// }

// class _NotificationSettingsScreenState
//     extends State<NotificationSettingsScreen> {
//   final GlobalService _globalService = GlobalService();

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Tetapan Notifikasi Solat'),
//         elevation: 0,
//       ),
//       body: ListView(
//         children: [
//           // Subuh
//           _buildPrayerSection('Subuh', 'subuh', Icons.wb_twilight, colorScheme),

//           // Zohor
//           _buildPrayerSection('Zohor', 'zohor', Icons.wb_sunny, colorScheme),

//           // Asar
//           _buildPrayerSection('Asar', 'asar', Icons.wb_cloudy, colorScheme),

//           // Maghrib
//           _buildPrayerSection(
//             'Maghrib',
//             'maghrib',
//             Icons.wb_twilight,
//             colorScheme,
//           ),

//           // Isyak
//           _buildPrayerSection('Isyak', 'isyak', Icons.nights_stay, colorScheme),
//         ],
//       ),
//     );
//   }

//   Widget _buildPrayerSection(
//     String prayerName,
//     String prayerKey,
//     IconData icon,
//     ColorScheme colorScheme,
//   ) {
//     final isEnabled = _getPrayerEnabled(prayerKey);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Main Prayer Toggle
//         ListTile(
//           leading: Icon(
//             icon,
//             color: isEnabled
//                 ? colorScheme.primary
//                 : colorScheme.onSurface.withValues(alpha: 0.4),
//           ),
//           title: Text(
//             prayerName,
//             style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
//           ),
//           trailing: Switch(
//             value: isEnabled,
//             onChanged: (value) {
//               _updatePrayerEnabled(prayerKey, value);
//             },
//           ),
//         ),

//         // Sub-options (only show when enabled)
//         if (isEnabled) ...[
//           // Azan Sound
//           ListTile(
//             contentPadding: EdgeInsets.only(left: 72.w, right: 16.w),
//             title: Text('Pilih Azan', style: TextStyle(fontSize: 14.sp)),
//             subtitle: Text(
//               _getAzanName(_getPrayerSound(prayerKey)),
//               style: TextStyle(fontSize: 12.sp, color: colorScheme.primary),
//             ),
//             trailing: Icon(Icons.chevron_right, size: 20.sp),
//             onTap: () => _showAzanPicker(prayerKey, colorScheme),
//           ),

//           // Display Mode
//           ListTile(
//             contentPadding: EdgeInsets.only(left: 72.w, right: 16.w),
//             title: Text('Mod Paparan', style: TextStyle(fontSize: 14.sp)),
//             subtitle: Text(
//               _getPrayerFullscreen(prayerKey) ? 'Skrin Penuh' : 'Notifikasi',
//               style: TextStyle(fontSize: 12.sp, color: colorScheme.primary),
//             ),
//             trailing: Icon(Icons.chevron_right, size: 20.sp),
//             onTap: () => _showDisplayModePicker(prayerKey, colorScheme),
//           ),

//           // Vibration
//           ListTile(
//             contentPadding: EdgeInsets.only(left: 72.w, right: 16.w),
//             title: Text('Getar', style: TextStyle(fontSize: 14.sp)),
//             trailing: Switch(
//               value: _getPrayerVibrate(prayerKey),
//               onChanged: (value) => _updatePrayerVibrate(prayerKey, value),
//             ),
//           ),

//           // LED
//           ListTile(
//             contentPadding: EdgeInsets.only(left: 72.w, right: 16.w),
//             title: Text('Lampu LED', style: TextStyle(fontSize: 14.sp)),
//             trailing: Switch(
//               value: _getPrayerLed(prayerKey),
//               onChanged: (value) => _updatePrayerLed(prayerKey, value),
//             ),
//           ),

//           // Reminder Section Header
//           Padding(
//             padding: EdgeInsets.only(left: 72.w, right: 16.w, top: 8.h),
//             child: Text(
//               'Peringatan Sebelum Azan',
//               style: TextStyle(
//                 fontSize: 12.sp,
//                 fontWeight: FontWeight.w600,
//                 color: colorScheme.onSurface.withValues(alpha: 0.6),
//               ),
//             ),
//           ),

//           // 5 minutes before
//           ListTile(
//             contentPadding: EdgeInsets.only(left: 72.w, right: 16.w),
//             title: Text('5 minit sebelum', style: TextStyle(fontSize: 14.sp)),
//             trailing: Switch(
//               value: _getPrayerReminder5Min(prayerKey),
//               onChanged: (value) => _updatePrayerReminder5Min(prayerKey, value),
//             ),
//           ),

//           // 10 minutes before
//           ListTile(
//             contentPadding: EdgeInsets.only(left: 72.w, right: 16.w),
//             title: Text('10 minit sebelum', style: TextStyle(fontSize: 14.sp)),
//             trailing: Switch(
//               value: _getPrayerReminder10Min(prayerKey),
//               onChanged: (value) =>
//                   _updatePrayerReminder10Min(prayerKey, value),
//             ),
//           ),

//           // 15 minutes before
//           ListTile(
//             contentPadding: EdgeInsets.only(left: 72.w, right: 16.w),
//             title: Text('15 minit sebelum', style: TextStyle(fontSize: 14.sp)),
//             trailing: Switch(
//               value: _getPrayerReminder15Min(prayerKey),
//               onChanged: (value) =>
//                   _updatePrayerReminder15Min(prayerKey, value),
//             ),
//           ),

//           Divider(height: 1.h, indent: 16.w),
//         ] else
//           Divider(height: 1.h, indent: 16.w),
//       ],
//     );
//   }

//   String _getAzanName(String azanFile) {
//     final azan = azanOptions.firstWhere(
//       (a) => a['file'] == azanFile,
//       orElse: () => azanOptions[0],
//     );
//     return azan['name']!;
//   }

//   void _showAzanPicker(String prayerKey, ColorScheme colorScheme) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         final currentSound = _getPrayerSound(prayerKey);
//         return Container(
//           padding: EdgeInsets.symmetric(vertical: 16.h),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//                 child: Text(
//                   'Pilih Azan',
//                   style: TextStyle(
//                     fontSize: 18.sp,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               Divider(height: 1.h),
//               ...azanOptions.map((azan) {
//                 final isSelected = currentSound == azan['file'];
//                 return ListTile(
//                   leading: Icon(
//                     isSelected
//                         ? Icons.radio_button_checked
//                         : Icons.radio_button_unchecked,
//                     color: isSelected ? colorScheme.primary : null,
//                   ),
//                   title: Text(azan['name']!),
//                   trailing: isSelected
//                       ? Icon(Icons.check, color: colorScheme.primary)
//                       : null,
//                   onTap: () {
//                     _updatePrayerSound(prayerKey, azan['file']!);
//                     Navigator.pop(context);
//                   },
//                 );
//               }),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _showDisplayModePicker(String prayerKey, ColorScheme colorScheme) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         final isFullscreen = _getPrayerFullscreen(prayerKey);
//         return Container(
//           padding: EdgeInsets.symmetric(vertical: 16.h),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//                 child: Text(
//                   'Mod Paparan',
//                   style: TextStyle(
//                     fontSize: 18.sp,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               Divider(height: 1.h),
//               ListTile(
//                 leading: Icon(
//                   isFullscreen
//                       ? Icons.radio_button_checked
//                       : Icons.radio_button_unchecked,
//                   color: isFullscreen ? colorScheme.primary : null,
//                 ),
//                 title: const Text('Skrin Penuh'),
//                 subtitle: const Text('Paparkan azan dalam mod skrin penuh'),
//                 trailing: isFullscreen
//                     ? Icon(Icons.check, color: colorScheme.primary)
//                     : null,
//                 onTap: () {
//                   _updatePrayerFullscreen(prayerKey, true);
//                   Navigator.pop(context);
//                 },
//               ),
//               ListTile(
//                 leading: Icon(
//                   !isFullscreen
//                       ? Icons.radio_button_checked
//                       : Icons.radio_button_unchecked,
//                   color: !isFullscreen ? colorScheme.primary : null,
//                 ),
//                 title: const Text('Notifikasi Sahaja'),
//                 subtitle: const Text('Paparkan notifikasi kecil sahaja'),
//                 trailing: !isFullscreen
//                     ? Icon(Icons.check, color: colorScheme.primary)
//                     : null,
//                 onTap: () {
//                   _updatePrayerFullscreen(prayerKey, false);
//                   Navigator.pop(context);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ========================================================================
//   // GETTERS
//   // ========================================================================

//   bool _getPrayerEnabled(String prayerKey) {
//     switch (prayerKey) {
//       case 'subuh':
//         return _globalService.subuhEnabled;
//       case 'zohor':
//         return _globalService.zohorEnabled;
//       case 'asar':
//         return _globalService.asarEnabled;
//       case 'maghrib':
//         return _globalService.maghribEnabled;
//       case 'isyak':
//         return _globalService.isyakEnabled;
//       default:
//         return false;
//     }
//   }

//   String _getPrayerSound(String prayerKey) {
//     switch (prayerKey) {
//       case 'subuh':
//         return _globalService.subuhSound;
//       case 'zohor':
//         return _globalService.zohorSound;
//       case 'asar':
//         return _globalService.asarSound;
//       case 'maghrib':
//         return _globalService.maghribSound;
//       case 'isyak':
//         return _globalService.isyakSound;
//       default:
//         return 'azan_isyak_munif_hijjaz';
//     }
//   }

//   bool _getPrayerVibrate(String prayerKey) {
//     switch (prayerKey) {
//       case 'subuh':
//         return _globalService.subuhVibrate;
//       case 'zohor':
//         return _globalService.zohorVibrate;
//       case 'asar':
//         return _globalService.asarVibrate;
//       case 'maghrib':
//         return _globalService.maghribVibrate;
//       case 'isyak':
//         return _globalService.isyakVibrate;
//       default:
//         return true;
//     }
//   }

//   bool _getPrayerLed(String prayerKey) {
//     switch (prayerKey) {
//       case 'subuh':
//         return _globalService.subuhLed;
//       case 'zohor':
//         return _globalService.zohorLed;
//       case 'asar':
//         return _globalService.asarLed;
//       case 'maghrib':
//         return _globalService.maghribLed;
//       case 'isyak':
//         return _globalService.isyakLed;
//       default:
//         return true;
//     }
//   }

//   bool _getPrayerFullscreen(String prayerKey) {
//     switch (prayerKey) {
//       case 'subuh':
//         return _globalService.subuhFullscreen;
//       case 'zohor':
//         return _globalService.zohorFullscreen;
//       case 'asar':
//         return _globalService.asarFullscreen;
//       case 'maghrib':
//         return _globalService.maghribFullscreen;
//       case 'isyak':
//         return _globalService.isyakFullscreen;
//       default:
//         return true;
//     }
//   }

//   bool _getPrayerReminder5Min(String prayerKey) {
//     switch (prayerKey) {
//       case 'subuh':
//         return _globalService.subuhReminder5Min;
//       case 'zohor':
//         return _globalService.zohorReminder5Min;
//       case 'asar':
//         return _globalService.asarReminder5Min;
//       case 'maghrib':
//         return _globalService.maghribReminder5Min;
//       case 'isyak':
//         return _globalService.isyakReminder5Min;
//       default:
//         return false;
//     }
//   }

//   bool _getPrayerReminder10Min(String prayerKey) {
//     switch (prayerKey) {
//       case 'subuh':
//         return _globalService.subuhReminder10Min;
//       case 'zohor':
//         return _globalService.zohorReminder10Min;
//       case 'asar':
//         return _globalService.asarReminder10Min;
//       case 'maghrib':
//         return _globalService.maghribReminder10Min;
//       case 'isyak':
//         return _globalService.isyakReminder10Min;
//       default:
//         return false;
//     }
//   }

//   bool _getPrayerReminder15Min(String prayerKey) {
//     switch (prayerKey) {
//       case 'subuh':
//         return _globalService.subuhReminder15Min;
//       case 'zohor':
//         return _globalService.zohorReminder15Min;
//       case 'asar':
//         return _globalService.asarReminder15Min;
//       case 'maghrib':
//         return _globalService.maghribReminder15Min;
//       case 'isyak':
//         return _globalService.isyakReminder15Min;
//       default:
//         return false;
//     }
//   }

//   // ========================================================================
//   // UPDATERS
//   // ========================================================================

//   Future<void> _updatePrayerEnabled(String prayerKey, bool value) async {
//     String prefKey;
//     switch (prayerKey) {
//       case 'subuh':
//         prefKey = prefSubuhEnabled;
//         break;
//       case 'zohor':
//         prefKey = prefZohorEnabled;
//         break;
//       case 'asar':
//         prefKey = prefAsarEnabled;
//         break;
//       case 'maghrib':
//         prefKey = prefMaghribEnabled;
//         break;
//       case 'isyak':
//         prefKey = prefIsyakEnabled;
//         break;
//       default:
//         return;
//     }

//     await _globalService.updateSetting(prefKey, value);
//     setState(() {});
//   }

//   Future<void> _updatePrayerSound(String prayerKey, String value) async {
//     String prefKey;
//     switch (prayerKey) {
//       case 'subuh':
//         prefKey = prefSubuhSound;
//         break;
//       case 'zohor':
//         prefKey = prefZohorSound;
//         break;
//       case 'asar':
//         prefKey = prefAsarSound;
//         break;
//       case 'maghrib':
//         prefKey = prefMaghribSound;
//         break;
//       case 'isyak':
//         prefKey = prefIsyakSound;
//         break;
//       default:
//         return;
//     }

//     await _globalService.updateSetting(prefKey, value);
//     setState(() {});
//   }

//   Future<void> _updatePrayerVibrate(String prayerKey, bool value) async {
//     String prefKey;
//     switch (prayerKey) {
//       case 'subuh':
//         prefKey = prefSubuhVibrate;
//         break;
//       case 'zohor':
//         prefKey = prefZohorVibrate;
//         break;
//       case 'asar':
//         prefKey = prefAsarVibrate;
//         break;
//       case 'maghrib':
//         prefKey = prefMaghribVibrate;
//         break;
//       case 'isyak':
//         prefKey = prefIsyakVibrate;
//         break;
//       default:
//         return;
//     }

//     await _globalService.updateSetting(prefKey, value);
//     setState(() {});
//   }

//   Future<void> _updatePrayerLed(String prayerKey, bool value) async {
//     String prefKey;
//     switch (prayerKey) {
//       case 'subuh':
//         prefKey = prefSubuhLed;
//         break;
//       case 'zohor':
//         prefKey = prefZohorLed;
//         break;
//       case 'asar':
//         prefKey = prefAsarLed;
//         break;
//       case 'maghrib':
//         prefKey = prefMaghribLed;
//         break;
//       case 'isyak':
//         prefKey = prefIsyakLed;
//         break;
//       default:
//         return;
//     }

//     await _globalService.updateSetting(prefKey, value);
//     setState(() {});
//   }

//   Future<void> _updatePrayerFullscreen(String prayerKey, bool value) async {
//     String prefKey;
//     switch (prayerKey) {
//       case 'subuh':
//         prefKey = prefSubuhFullscreen;
//         break;
//       case 'zohor':
//         prefKey = prefZohorFullscreen;
//         break;
//       case 'asar':
//         prefKey = prefAsarFullscreen;
//         break;
//       case 'maghrib':
//         prefKey = prefMaghribFullscreen;
//         break;
//       case 'isyak':
//         prefKey = prefIsyakFullscreen;
//         break;
//       default:
//         return;
//     }

//     await _globalService.updateSetting(prefKey, value);
//     setState(() {});
//   }

//   Future<void> _updatePrayerReminder5Min(String prayerKey, bool value) async {
//     String prefKey;
//     switch (prayerKey) {
//       case 'subuh':
//         prefKey = prefSubuhReminder5Min;
//         break;
//       case 'zohor':
//         prefKey = prefZohorReminder5Min;
//         break;
//       case 'asar':
//         prefKey = prefAsarReminder5Min;
//         break;
//       case 'maghrib':
//         prefKey = prefMaghribReminder5Min;
//         break;
//       case 'isyak':
//         prefKey = prefIsyakReminder5Min;
//         break;
//       default:
//         return;
//     }

//     await _globalService.updateSetting(prefKey, value);
//     setState(() {});
//   }

//   Future<void> _updatePrayerReminder10Min(String prayerKey, bool value) async {
//     String prefKey;
//     switch (prayerKey) {
//       case 'subuh':
//         prefKey = prefSubuhReminder10Min;
//         break;
//       case 'zohor':
//         prefKey = prefZohorReminder10Min;
//         break;
//       case 'asar':
//         prefKey = prefAsarReminder10Min;
//         break;
//       case 'maghrib':
//         prefKey = prefMaghribReminder10Min;
//         break;
//       case 'isyak':
//         prefKey = prefIsyakReminder10Min;
//         break;
//       default:
//         return;
//     }

//     await _globalService.updateSetting(prefKey, value);
//     setState(() {});
//   }

//   Future<void> _updatePrayerReminder15Min(String prayerKey, bool value) async {
//     String prefKey;
//     switch (prayerKey) {
//       case 'subuh':
//         prefKey = prefSubuhReminder15Min;
//         break;
//       case 'zohor':
//         prefKey = prefZohorReminder15Min;
//         break;
//       case 'asar':
//         prefKey = prefAsarReminder15Min;
//         break;
//       case 'maghrib':
//         prefKey = prefMaghribReminder15Min;
//         break;
//       case 'isyak':
//         prefKey = prefIsyakReminder15Min;
//         break;
//       default:
//         return;
//     }

//     await _globalService.updateSetting(prefKey, value);
//     setState(() {});
//   }
// }
