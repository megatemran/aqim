import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlarmTestPage extends StatefulWidget {
  const AlarmTestPage({super.key});

  @override
  State<AlarmTestPage> createState() => _AlarmTestPageState();
}

class _AlarmTestPageState extends State<AlarmTestPage> {
  Future<void> _testImmediateAlarm() async {
    try {
      const platform = MethodChannel('net.brings2you.aqim/alarm_tester');
      await platform.invokeMethod('testImmediateAlarm');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Test alarm scheduled! Check notifications in 10 seconds.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testAppScheduler() async {
    try {
      const platform = MethodChannel('net.brings2you.aqim/alarm_tester');
      await platform.invokeMethod('testAppScheduler');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AppScheduler test executed!'),
          duration: Duration(seconds: 3),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testAppReceiver() async {
    try {
      const platform = MethodChannel('net.brings2you.aqim/alarm_tester');
      await platform.invokeMethod('testAppReceiver');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AppReceiver test executed!'),
          duration: Duration(seconds: 3),
        ),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, String>> _getPrayerTimes() async {
    const platform = MethodChannel('net.brings2you.aqim/alarm_tester');
    final times = await platform.invokeMethod('getPrayerTimes');
    return Map<String, String>.from(times);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarm System Test')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alarm System Diagnostics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Test the alarm scheduling system to ensure it\'s working correctly.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _testImmediateAlarm,
                    icon: const Icon(Icons.alarm),
                    label: const Text('Test Immediate Alarm (10s)'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _testAppScheduler,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Test AppScheduler'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _testAppReceiver,
                    icon: const Icon(Icons.notifications),
                    label: const Text('Test AppReceiver'),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Prayer Times',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<Map<String, String>>(
                    future: _getPrayerTimes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      final times = snapshot.data ?? {};
                      return Column(
                        children: times.entries.map((entry) {
                          return ListTile(
                            title: Text(entry.key),
                            trailing: Text(entry.value),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
