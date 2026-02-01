import 'package:flutter/services.dart';

class AudioHelper {
  static const MethodChannel _channel =
      MethodChannel('com.example.audio_helper');

  static Future<bool> isMusicActive() async {
    try {
      final bool result = await _channel.invokeMethod('isMusicActive');
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isBluetoothConnected() async {
    try {
      final bool result = await _channel.invokeMethod('isBluetoothConnected');
      return result;
    } catch (_) {
      return false;
    }
  }
}
