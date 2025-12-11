import 'package:flutter/material.dart';
import 'package:aqim/services/prayer_alarm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug screen to test prayer alarms
class PrayerAlarmDebugScreen extends StatefulWidget {
  const PrayerAlarmDebugScreen({super.key});

  @override
  State<PrayerAlarmDebugScreen> createState() => _PrayerAlarmDebugScreenState();
}

class _PrayerAlarmDebugScreenState extends State<PrayerAlarmDebugScreen> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Alarm Debug'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Test buttons
            Text(
              'Quick Tests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            // Schedule test alarm (1 minute from now)
            ElevatedButton.icon(
              icon: Icon(Icons.alarm_add),
              label: Text('Schedule Test Alarm (1 minute)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
              onPressed: _isLoading ? null : () => _scheduleTestAlarm(),
            ),

            SizedBox(height: 12),

            // Manually trigger alarm
            ElevatedButton.icon(
              icon: Icon(Icons.notifications_active),
              label: Text('Trigger Alarm Now (Manual Test)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
              onPressed: _isLoading ? null : () => _manualTrigger(),
            ),

            SizedBox(height: 12),

            // Schedule all prayer alarms
            ElevatedButton.icon(
              icon: Icon(Icons.schedule),
              label: Text('Schedule All Prayer Alarms'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
              onPressed: _isLoading ? null : () => _scheduleAllAlarms(),
            ),

            SizedBox(height: 12),

            // Cancel all alarms
            ElevatedButton.icon(
              icon: Icon(Icons.cancel),
              label: Text('Cancel All Alarms'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
              onPressed: _isLoading ? null : () => _cancelAllAlarms(),
            ),

            SizedBox(height: 24),

            // Current prayer times
            Text(
              'Current Prayer Times',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            FutureBuilder<Map<String, String>>(
              future: _getPrayerTimes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final times = snapshot.data!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTimeRow('Subuh', times['subuh'] ?? '-'),
                        Divider(),
                        _buildTimeRow('Zohor', times['zohor'] ?? '-'),
                        Divider(),
                        _buildTimeRow('Asar', times['asar'] ?? '-'),
                        Divider(),
                        _buildTimeRow('Maghrib', times['maghrib'] ?? '-'),
                        Divider(),
                        _buildTimeRow('Isyak', times['isyak'] ?? '-'),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 24),

            // Instructions
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber.shade700,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('1. Use "Schedule Test Alarm" to test in 2 minutes'),
                    SizedBox(height: 4),
                    Text('2. Check logs: adb logcat | Select-String "PrayerAlarm"'),
                    SizedBox(height: 4),
                    Text('3. Or: adb logcat -s PrayerAlarmReceiver'),
                    SizedBox(height: 4),
                    Text(
                      '4. Make sure "Alarms & reminders" permission is granted',
                    ),
                    SizedBox(height: 4),
                    Text(
                      '5. Test will verify if settings are respected',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String name, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>> _getPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'subuh': prefs.getString('subuh') ?? '-',
      'zohor': prefs.getString('zohor') ?? '-',
      'asar': prefs.getString('asar') ?? '-',
      'maghrib': prefs.getString('maghrib') ?? '-',
      'isyak': prefs.getString('isyak') ?? '-',
    };
  }

  Future<void> _scheduleTestAlarm() async {
    setState(() {
      _isLoading = true;
      _status = 'Scheduling test alarm for 2 minutes from now...';
    });

    try {
      // Get current time + 2 minutes (to allow time for setup)
      final now = DateTime.now();
      final testTime = now.add(Duration(minutes: 2));
      final timeString =
          '${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}';

      // Save to HomeWidgetPreferences (where PrayerAlarmReceiver reads from)
      final prefs = await SharedPreferences.getInstance();

      // Use Asar for test (so it's clear which prayer is being tested)
      await prefs.setString('flutter.HomeWidgetPreferences.asar', timeString);

      debugPrint('🧪 DEBUG: Set test alarm for Asar at $timeString');
      debugPrint('🧪 DEBUG: Current time: ${now.hour}:${now.minute}');

      // Schedule alarm
      final success = await PrayerAlarmService.scheduleAllPrayerAlarms();

      if (!mounted) return;

      setState(() {
        _status = success
            ? '✅ Test alarm (ASAR) scheduled for $timeString\n(${testTime.difference(now).inMinutes} minutes from now)\n\nWatch for:\n• Logcat logs\n• Notification\n• Fullscreen azan'
            : '❌ Failed to schedule alarm';
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🧪 Test alarm set for $timeString (Asar)\nCheck: adb logcat | Select-String "PrayerAlarm"'),
            duration: Duration(seconds: 8),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _manualTrigger() async {
    setState(() {
      _status = 'Manually triggering alarm...';
    });

    // This will call the callback registered in main.dart
    // You'll need to expose a way to manually trigger the callback
    // For now, show dialog directly

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.alarm, color: Colors.teal),
              SizedBox(width: 12),
              Text('Test Alarm'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🕌', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text(
                'This is a manual test',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Waktu Solat ISYAK'),
              Text('6:22 PM'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }

    if (mounted) {
      setState(() {
        _status = '✅ Manual test triggered';
      });
    }
  }

  Future<void> _scheduleAllAlarms() async {
    setState(() {
      _isLoading = true;
      _status = 'Scheduling all prayer alarms...';
    });

    try {
      final success = await PrayerAlarmService.scheduleAllPrayerAlarms();

      if (!mounted) return; // ✅ Check if widget is still mounted

      setState(() {
        _status = success
            ? '✅ All prayer alarms scheduled successfully!\nCheck logcat for details.'
            : '❌ Failed to schedule alarms';
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All prayer alarms scheduled!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return; // ✅ Check if widget is still mounted
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAllAlarms() async {
    setState(() {
      _isLoading = true;
      _status = 'Cancelling all alarms...';
    });

    try {
      final success = await PrayerAlarmService.cancelAllPrayerAlarms();

      if (!mounted) return; // ✅ Check if widget is still mounted

      setState(() {
        _status = success
            ? '✅ All alarms cancelled'
            : '❌ Failed to cancel alarms';
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All alarms cancelled!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return; // ✅ Check if widget is still mounted
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }
}
