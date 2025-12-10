// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../services/prayer_alarm_service.dart';

// /// Dialog to request exact alarm permission on Android 12+
// /// This permission is CRITICAL for prayer alarms to trigger at exact times
// class ExactAlarmPermissionDialog extends StatelessWidget {
//   const ExactAlarmPermissionDialog({super.key});

//   /// Show the permission dialog if needed
//   /// Returns true if dialog was shown, false if not needed
//   static Future<bool> showIfNeeded(BuildContext context) async {
//     // Check if we should request permission
//     final shouldRequest =
//         await PrayerAlarmService.shouldRequestExactAlarmPermission();

//     if (!shouldRequest) {
//       debugPrint('⏭️ Exact alarm permission dialog not needed');
//       return false;
//     }

//     // Check if permission is already granted
//     final canSchedule = await PrayerAlarmService.canScheduleExactAlarms();

//     if (canSchedule) {
//       debugPrint('✅ Exact alarm permission already granted');
//       return false;
//     }

//     if (!context.mounted) return false;

//     // Show the dialog
//     await showDialog(
//       context: context,
//       barrierDismissible: false, // User must make a choice
//       builder: (context) => const ExactAlarmPermissionDialog(),
//     );

//     return true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
//       title: Row(
//         children: [
//           Icon(
//             Icons.alarm,
//             color: Theme.of(context).colorScheme.primary,
//             size: 28.sp,
//           ),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: Text(
//               'Kebenaran Diperlukan',
//               style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Untuk memaparkan azan pada waktu solat yang TEPAT, aplikasi ini memerlukan kebenaran "Alarms & Reminders".',
//               style: TextStyle(fontSize: 14.sp, height: 1.5),
//             ),
//             SizedBox(height: 16.h),
//             _buildWarningBox(context),
//             SizedBox(height: 16.h),
//             _buildInstructions(context),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () async {
//             // User dismissed without granting
//             await PrayerAlarmService.markExactAlarmPermissionAsked(
//               dismissed: true,
//             );
//             if (context.mounted) {
//               Navigator.of(context).pop();
//             }
//           },
//           child: Text(
//             'Nanti',
//             style: TextStyle(fontSize: 14.sp, color: Colors.grey),
//           ),
//         ),
//         ElevatedButton(
//           onPressed: () async {
//             // Open settings
//             await PrayerAlarmService.openExactAlarmSettings();
//             await PrayerAlarmService.markExactAlarmPermissionAsked(
//               dismissed: false,
//             );

//             if (context.mounted) {
//               Navigator.of(context).pop();
//             }
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Theme.of(context).colorScheme.primary,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8.r),
//             ),
//           ),
//           child: Text(
//             'Buka Settings',
//             style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildWarningBox(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(12.r),
//       decoration: BoxDecoration(
//         color: Colors.orange.shade50,
//         borderRadius: BorderRadius.circular(8.r),
//         border: Border.all(color: Colors.orange.shade300, width: 1),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             Icons.warning_amber_rounded,
//             color: Colors.orange.shade700,
//             size: 24.sp,
//           ),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Tanpa kebenaran ini:',
//                   style: TextStyle(
//                     fontSize: 13.sp,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.orange.shade900,
//                   ),
//                 ),
//                 SizedBox(height: 4.h),
//                 _buildBulletPoint('Azan mungkin tertangguh 15-60 minit'),
//                 _buildBulletPoint('Notifikasi tidak muncul bila telefon tidur'),
//                 _buildBulletPoint('Alarm waktu solat tidak boleh dipercayai'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBulletPoint(String text) {
//     return Padding(
//       padding: EdgeInsets.only(top: 2.h),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '• ',
//             style: TextStyle(fontSize: 12.sp, color: Colors.orange.shade900),
//           ),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(fontSize: 12.sp, color: Colors.orange.shade900),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInstructions(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(12.r),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(8.r),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.info_outline,
//                 color: Theme.of(context).colorScheme.primary,
//                 size: 20.sp,
//               ),
//               SizedBox(width: 8.w),
//               Text(
//                 'Cara aktifkan:',
//                 style: TextStyle(
//                   fontSize: 13.sp,
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8.h),
//           _buildInstructionStep('1', 'Tekan butang "Buka Settings"'),
//           _buildInstructionStep('2', 'Cari aplikasi "Aqim" dalam senarai'),
//           _buildInstructionStep('3', 'Aktifkan "Alarms & reminders"'),
//         ],
//       ),
//     );
//   }

//   Widget _buildInstructionStep(String number, String text) {
//     return Padding(
//       padding: EdgeInsets.only(top: 4.h),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 20.w,
//             child: Text(
//               number,
//               style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: Text(text, style: TextStyle(fontSize: 12.sp)),
//           ),
//         ],
//       ),
//     );
//   }
// }
