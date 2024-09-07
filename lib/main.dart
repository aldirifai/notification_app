import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:io';

void main() {
  // Inisialisasi port untuk komunikasi dengan TaskHandler.
  FlutterForegroundTask.initCommunicationPort();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotification();
    _requestPermissions();
    _initForegroundService();
  }

  // Meminta izin notifikasi dan izin terkait foreground service
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final NotificationPermission notificationPermissionStatus =
      await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermissionStatus != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  Future<void> _initializeNotification() async {
    var initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      fullScreenIntent: true,
    );
    var platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'Title', 'This is a message every 20 seconds', platformChannelSpecifics);
  }

  // Menginisialisasi layanan foreground task
  void _initForegroundService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
        'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(20000), // 20 detik dalam milidetik
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    // Memulai layanan foreground
    FlutterForegroundTask.startService(
      notificationTitle: 'Foreground Service Running',
      notificationText: 'Foreground service is active.',
      callback: startCallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Notification App'),
        ),
        body: Center(
          child: Text('Foreground Notification Every 20 seconds'),
        ),
      ),
    );
  }
}

// Fungsi callback untuk task handler
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(CustomTaskHandler());
}

class CustomTaskHandler extends TaskHandler {
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp) async {
    _timer = Timer.periodic(Duration(seconds: 20), (timer) async {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'channel_id', 'channel_name',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          fullScreenIntent: true);
      var platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(0, 'Title',
          'This is a message every 20 seconds', platformChannelSpecifics);
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _timer?.cancel();
  }

  @override
  Future<void> onEvent(DateTime timestamp) async {
    // Implement logic when events occur
  }

  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Implement logic for repeated events
  }
}
