import 'package:flutter/services.dart';

class AppUtils {
  static const MethodChannel _channel = MethodChannel('com.bomanyi.ai/channel');

  static Future<void> moveTaskToBack() async {
    try {
      await _channel.invokeMethod('moveTaskToBack');
    } catch (e) {
      print("Error: $e");
    }
  }
}