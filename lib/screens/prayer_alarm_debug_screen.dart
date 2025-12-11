import 'package:flutter/material.dart';
import 'package:aqim/services/prayer_alarm_service.dart';
import 'package:aqim/services/app_review_service.dart';
import 'package:aqim/services/app_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';

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

            // In-App Review Tests
            Text(
              'In-App Review Tests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            // Test in-app review
            ElevatedButton.icon(
              icon: Icon(Icons.star),
              label: Text('Test In-App Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
              onPressed: _isLoading ? null : () => _testInAppReview(),
            ),

            SizedBox(height: 12),

            // Reset review request
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Reset Review Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
              onPressed: _isLoading ? null : () => _resetReviewData(),
            ),

            SizedBox(height: 12),

            // Show review status
            ElevatedButton.icon(
              icon: Icon(Icons.info),
              label: Text('Check Review Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
              onPressed: _isLoading ? null : () => _checkReviewStatus(),
            ),

            SizedBox(height: 12),

            // Open store listing (alternative)
            ElevatedButton.icon(
              icon: Icon(Icons.open_in_new),
              label: Text('Open Play Store (Alternative)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
              onPressed: _isLoading ? null : () => _openStoreListing(),
            ),

            SizedBox(height: 24),

            // In-App Update Tests
            Text(
              'In-App Update Tests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            // Check for update
            ElevatedButton.icon(
              icon: Icon(Icons.system_update),
              label: Text('Check for Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
              onPressed: _isLoading ? null : () => _checkForUpdate(),
            ),

            SizedBox(height: 12),

            // Test flexible update
            ElevatedButton.icon(
              icon: Icon(Icons.download),
              label: Text('Start Flexible Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
              onPressed: _isLoading ? null : () => _startFlexibleUpdate(),
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
                    Text('1. Use "Schedule Test Alarm" to test in 1 minute'),
                    SizedBox(height: 4),
                    Text(
                      '2. Check logs: adb logcat | Select-String "PrayerAlarm"',
                    ),
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
      _status = 'Scheduling test alarm for 1 minute from now...';
    });

    try {
      final now = DateTime.now();
      final testTime = now.add(Duration(minutes: 1));
      final timeString =
          '${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}';

      // Save to HomeWidgetPreferences (where PrayerAlarmReceiver reads from)
      // ✅ IMPORTANT: Use HomeWidget.saveWidgetData, NOT SharedPreferences!
      // Use Asar for test (so it's clear which prayer is being tested)
      await HomeWidget.saveWidgetData<String>('asar', timeString);

      debugPrint('🧪 DEBUG: Set test alarm for Asar at $timeString');
      debugPrint('🧪 DEBUG: Current time: ${now.hour}:${now.minute}');

      // Schedule alarm
      final success = await PrayerAlarmService.scheduleAllPrayerAlarms();

      if (!mounted) return;

      setState(() {
        _status = success
            ? '✅ Test alarm (ASAR) scheduled for $timeString\n(in 1 minute)\n\nWatch for:\n• Logcat logs\n• Notification\n• Fullscreen azan'
            : '❌ Failed to schedule alarm';
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🧪 Test alarm in 1 minute!\nCheck: adb logcat | Select-String "PrayerAlarm"',
            ),
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

  // ========================================================================
  // IN-APP REVIEW TEST FUNCTIONS
  // ========================================================================

  Future<void> _testInAppReview() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing in-app review...';
    });

    try {
      final success = await AppReviewService.requestReview();

      if (!mounted) return;

      if (success) {
        setState(() {
          _status = '✅ In-app review dialog should appear!\n(5-star rating dialog)';
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ In-app review dialog shown!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        setState(() {
          _status = '⚠️ Review dialog NOT available\n\n'
              'Reasons:\n'
              '• Running in debug mode\n'
              '• Not from Play Store\n'
              '• Emulator/device quota\n\n'
              '💡 Use "Open Store Listing" to test manually';
          _isLoading = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(child: Text('Review Not Available')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('In-app review dialog is not available.'),
                  SizedBox(height: 12),
                  Text('Common reasons:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• App is in debug/development mode'),
                  Text('• Not installed from Google Play Store'),
                  Text('• Running on emulator'),
                  Text('• Device quota exceeded (Google limit)'),
                  SizedBox(height: 12),
                  Text('💡 To test:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('1. Build release APK/AAB'),
                  Text('2. Upload to Play Store (Internal Testing)'),
                  Text('3. Install from Play Store'),
                  Text('4. Then test review dialog'),
                  SizedBox(height: 12),
                  Text('Or use "Open Store Listing" button to open Play Store directly.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    AppReviewService.openStoreListing();
                  },
                  child: Text('Open Store Listing'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetReviewData() async {
    setState(() {
      _isLoading = true;
      _status = 'Resetting review data...';
    });

    try {
      await AppReviewService.resetReviewRequest();

      if (!mounted) return;

      setState(() {
        _status = '✅ Review data reset!\nYou can test again now.';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review data reset successfully!'),
            backgroundColor: Colors.grey,
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

  Future<void> _checkReviewStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking review status...';
    });

    try {
      final status = await AppReviewService.getReviewStatus();

      if (!mounted) return;

      setState(() {
        _status = '📊 Review Status:\n$status';
        _isLoading = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 12),
                Text('Review Status'),
              ],
            ),
            content: Text(status),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
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

  Future<void> _openStoreListing() async {
    setState(() {
      _isLoading = true;
      _status = 'Opening Play Store...';
    });

    try {
      await AppReviewService.openStoreListing();

      if (!mounted) return;

      setState(() {
        _status = '✅ Play Store opened!\nUser can review manually.';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Play Store listing opened!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = '❌ Error: $e\n(App might not be on Play Store yet)';
        _isLoading = false;
      });
    }
  }

  // ========================================================================
  // IN-APP UPDATE TEST FUNCTIONS
  // ========================================================================

  Future<void> _checkForUpdate() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking for app updates...';
    });

    try {
      final updateInfo = await AppUpdateService.checkForUpdate();

      if (!mounted) return;

      if (updateInfo == null) {
        setState(() {
          _status = '⚠️ Update check not available\n(Android only feature)';
          _isLoading = false;
        });
        return;
      }

      final availability = updateInfo.updateAvailability.toString().split('.').last;
      final immediate = updateInfo.immediateUpdateAllowed;
      final flexible = updateInfo.flexibleUpdateAllowed;

      setState(() {
        _status = '📱 Update Status:\n'
            'Availability: $availability\n'
            'Immediate: $immediate\n'
            'Flexible: $flexible';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update check complete! See status above.'),
            backgroundColor: Colors.indigo,
            duration: Duration(seconds: 5),
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

  Future<void> _startFlexibleUpdate() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting flexible update...';
    });

    try {
      await AppUpdateService.startFlexibleUpdate();

      if (!mounted) return;

      setState(() {
        _status = '✅ Flexible update started!\nUpdate will download in background.';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flexible update started! Check Play Store.'),
            backgroundColor: Colors.deepPurple,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = '❌ Error: $e\n(Make sure update is available first)';
        _isLoading = false;
      });
    }
  }
}
