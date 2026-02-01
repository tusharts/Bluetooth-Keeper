import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart' hide AVAudioSessionCategory;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_helper/audio_helper.dart';

import 'silent_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'Bluetooth Keep Alive', // title
    description: 'Silent audio service to keep speaker alive',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Bluetooth Keeper',
      initialNotificationContent: 'Service is ready',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Audio Session for Ambient mixing (Play over music without interrupting)
  final session = await AudioSession.instance;
  await session.configure(
    const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidWillPauseWhenDucked: false,
    ),
  );

  final player = AudioPlayer();

  // Load settings
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int intervalSeconds = prefs.getInt('interval') ?? 300; // 5 min default
  bool onlyBluetooth = prefs.getBool('only_bluetooth') ?? true;
  bool serviceRunning = true;

  // Listen to service control events from UI
  service.on('stopService').listen((event) {
    serviceRunning = false;
    service.stopSelf();
  });

  service.on('updateSettings').listen((event) {
    if (event != null) {
      intervalSeconds = event['interval'] ?? 300;
      onlyBluetooth = event['only_bluetooth'] ?? true;
    }
  });

  debugPrint("Service loop started");

  while (serviceRunning) {
    // 1. Check whether the required Bluetooth speaker is connected.
    if (onlyBluetooth) {
      bool isBt = await AudioHelper.isBluetoothConnected();
      if (!isBt) {
        // If it is not connected, wait for a short time (30s) and then check again.
        debugPrint("Bluetooth not connected. Waiting 30s.");
        await Future.delayed(const Duration(seconds: 30));
        continue;
      }
    }

    // 2. If the speaker is connected, check whether any media audio is currently playing.
    bool isMusic = await AudioHelper.isMusicActive();
    if (isMusic) {
      // If media is playing, do nothing and keep checking periodically (wait 10s).
      debugPrint("Media is playing. Checking again in 10s.");
      await Future.delayed(const Duration(seconds: 10));
      continue;
    }

    // 3. If the speaker is connected and no media is playing:
    // Wait for a few minutes (around 3–5 minutes) while keeping the process awake.
    debugPrint("Silence detected. Waiting ${intervalSeconds}s.");

    // Smart wait loop to allow breaking if service stops or settings change significantly
    int elapsed = 0;
    // Check every second
    while (elapsed < intervalSeconds && serviceRunning) {
      await Future.delayed(const Duration(seconds: 1));
      elapsed++;
      // If interval changes to be shorter than elapsed, break immediately
      if (elapsed >= intervalSeconds) break;
    }

    if (!serviceRunning) break;

    // 4. After the waiting period, check again whether media playback has started.
    bool mediaStarted = await AudioHelper.isMusicActive();
    if (mediaStarted) {
      // If media has started, return to monitoring and do not play any sound.
      debugPrint("Media started during wait. Returning to monitor.");
      continue;
    }

    // 5. If media is still not playing after the delay:
    // Play a very short, low-volume audio sound (a “ping”)
    debugPrint("Pinging silent audio...");
    try {
      await player.play(BytesSource(base64Decode(silentAudioBase64)));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }

    // 6. Wait briefly (around 10–15 seconds) then return to the start of the loop.
    await Future.delayed(const Duration(seconds: 15));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData.dark(useMaterial3: true),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isRunning = false;
  int _intervalSeconds = 300;
  bool _onlyBluetooth = true;
  final TextEditingController _intervalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      // Request Bluetooth permissions for Android 12+
      if (await Permission.bluetoothConnect.status.isDenied) {
        await Permission.bluetoothConnect.request();
      }
    }
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _intervalSeconds = prefs.getInt('interval') ?? 300;
      _onlyBluetooth = prefs.getBool('only_bluetooth') ?? true;
      _intervalController.text = (_intervalSeconds / 60).toString();
    });

    bool running = await FlutterBackgroundService().isRunning();
    setState(() {
      _isRunning = running;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('interval', _intervalSeconds);
    await prefs.setBool('only_bluetooth', _onlyBluetooth);

    // Notify Service
    FlutterBackgroundService().invoke('updateSettings', {
      'interval': _intervalSeconds,
      'only_bluetooth': _onlyBluetooth,
    });
  }

  Future<void> _toggleService(bool value) async {
    final service = FlutterBackgroundService();
    if (value) {
      await service.startService();
    } else {
      service.invoke('stopService');
    }
    setState(() {
      _isRunning = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Keeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Enable Keep Alive"),
              value: _isRunning,
              onChanged: _toggleService,
            ),
            const Divider(),
            ListTile(
              title: const Text('Ping Interval (Minutes)'),
              subtitle: Text(
                '${(_intervalSeconds / 60).toStringAsFixed(1)} minutes',
              ),
            ),
            Slider(
              value: _intervalSeconds.toDouble(),
              min: 60,
              max: 1200, // 20 mins
              divisions: 19,
              label: '${(_intervalSeconds / 60).round()} min',
              onChanged: (val) {
                setState(() {
                  _intervalSeconds = val.toInt();
                });
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text("Only when Bluetooth Connected"),
              subtitle: const Text(
                "Checks for A2DP device. Disable if detection fails.",
              ),
              value: _onlyBluetooth,
              onChanged: (val) {
                setState(() {
                  _onlyBluetooth = val;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Note: Please disable 'Battery Optimization' for this app in Android Settings to ensure it runs reliably in the background.",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
