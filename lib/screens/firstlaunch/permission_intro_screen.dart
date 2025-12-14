// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionIntroScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const PermissionIntroScreen({super.key, required this.onContinue});

  @override
  State<PermissionIntroScreen> createState() => _PermissionIntroScreenState();
}

class _PermissionIntroScreenState extends State<PermissionIntroScreen>
    with WidgetsBindingObserver {
  String _locationStatus = 'denied';
  String _notificationStatus = 'denied';
  String _alarmStatus = 'denied';
  String _batteryStatus = 'denied';

  Future<String> _requestPermission({required Permission permission}) async {
    final status = await permission.status;

    if (status.isGranted) {
      debugPrint('already granted');
      return 'already granted';
    } else if (status.isDenied) {
      final result = await permission.request();
      if (result.isGranted) {
        debugPrint('granted');
        return 'granted';
      } else {
        debugPrint('denied');
        return 'denied';
      }
    } else if (status.isPermanentlyDenied) {
      debugPrint('permanently denied');
      return 'permanently denied';
    } else {
      debugPrint('denied');
      return 'denied';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Re-check permissions when user returns from Settings
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed - rechecking permissions...');
      _checkInitialPermissions();
    }
  }

  static Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme cs,
    required String status,
    required VoidCallback onTap,
  }) {
    final isApproved = status == 'granted' || status == 'already granted';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          splashColor: cs.primary.withValues(alpha: 0.05),
          hoverColor: cs.primary.withValues(alpha: 0.08),
          enabled: !isApproved, // disable if granted
          onTap: isApproved ? null : onTap, // only clickable if not granted
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 24),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
          trailing: Icon(
            isApproved ? Icons.check_circle_rounded : Icons.block_outlined,
            color: isApproved
                ? Colors.green
                : cs.onSurface.withValues(alpha: 100 / 255),
          ),
        ),
      ),
    );
  }

  Future<void> _checkInitialPermissions() async {
    final loc = await Permission.location.status;
    final noti = await Permission.notification.status;
    final alarm = await Permission.scheduleExactAlarm.status;
    final battery = await Permission.ignoreBatteryOptimizations.status;

    setState(() {
      _locationStatus = loc.isGranted ? 'granted' : 'denied';
      _notificationStatus = noti.isGranted ? 'granted' : 'denied';
      _alarmStatus = alarm.isGranted ? 'granted' : 'denied';
      _batteryStatus = battery.isGranted ? 'granted' : 'denied';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final textColorPrimary = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.black54;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white;

    return Scaffold(
      body: Container(
        color: cs.surface,
        width: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF1A5F4F),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Kebenaran Aplikasi',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Untuk pengalaman terbaik',
                          style: TextStyle(
                            fontSize: 15,
                            color: textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Permissions list
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aplikasi ini memerlukan kebenaran berikut:',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColorSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildPermissionItem(
                        icon: Icons.location_on_rounded,
                        title: 'Lokasi',
                        description:
                            'Menentukan waktu solat mengikut kawasan anda',
                        cs: cs,
                        status: _locationStatus,
                        onTap: () async {
                          final result = await _requestPermission(
                            permission: Permission.location,
                          );
                          setState(() => _locationStatus = result);
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildPermissionItem(
                        icon: Icons.notifications_rounded,
                        title: 'Notifikasi',
                        description: 'Mengingatkan anda masuk waktu solat',
                        cs: cs,
                        status: _notificationStatus,
                        onTap: () async {
                          final result = await _requestPermission(
                            permission: Permission.notification,
                          );
                          setState(() => _notificationStatus = result);
                        },
                      ),
                      // Only show exact alarm permission on Android 12-13
                      // Android 14+ auto-grants USE_EXACT_ALARM for alarm apps
                      if (_alarmStatus != 'granted') ...[
                        const SizedBox(height: 20),
                        _buildPermissionItem(
                          icon: Icons.alarm_rounded,
                          title: 'Alarm Tepat',
                          description:
                              'Memastikan azan berbunyi tepat pada waktunya',
                          cs: cs,
                          status: _alarmStatus,
                          onTap: () async {
                            final result = await _requestPermission(
                              permission: Permission.scheduleExactAlarm,
                            );
                            setState(() => _alarmStatus = result);
                          },
                        ),
                      ],
                      _buildPermissionItem(
                        icon: Icons.battery_saver_rounded,
                        title: 'Battery Optimization',
                        description:
                            'Pastikan azan tidak terhalang ketika skrin mati',
                        cs: cs,
                        status: _batteryStatus,
                        onTap: () async {
                          final result = await _requestPermission(
                            permission: Permission.ignoreBatteryOptimizations,
                          );
                          setState(() => _batteryStatus = result);
                        },
                      ),
                    ],
                  ),

                  // Info note for Android 14+ (exact alarm auto-granted)
                  // if (_alarmStatus == 'granted' ||
                  //     _alarmStatus == 'already granted') ...[
                  //   const SizedBox(height: 16),
                  //   Container(
                  //     padding: const EdgeInsets.all(12),
                  //     decoration: BoxDecoration(
                  //       color: Colors.green.withValues(alpha: 0.1),
                  //       borderRadius: BorderRadius.circular(12),
                  //       border: Border.all(
                  //         color: Colors.green.withValues(alpha: 0.3),
                  //       ),
                  //     ),
                  //     child: Row(
                  //       children: [
                  //         Icon(
                  //           Icons.info_outline,
                  //           color: Colors.green.shade700,
                  //           size: 20,
                  //         ),
                  //         const SizedBox(width: 12),
                  //         Expanded(
                  //           child: Text(
                  //             'Alarm tepat telah diaktifkan automatik untuk aplikasi waktu solat',
                  //             style: TextStyle(
                  //               fontSize: 12,
                  //               color: Colors.green.shade900,
                  //             ),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ],
                  const SizedBox(height: 40),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_locationStatus == 'granted' ||
                                  _locationStatus == 'already granted') &&
                              (_notificationStatus == 'granted' ||
                                  _notificationStatus == 'already granted') &&
                              (_alarmStatus == 'granted' ||
                                  _alarmStatus == 'already granted') &&
                              (_batteryStatus == 'granted' ||
                                  _batteryStatus == 'already granted')
                          ? widget.onContinue
                          : null,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white
                            : const Color(0xFF1A5F4F),
                        foregroundColor: isDark
                            ? const Color(0xFF1A5F4F)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Teruskan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Data anda selamat dan dilindungi',
                    style: TextStyle(fontSize: 12, color: textColorSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
