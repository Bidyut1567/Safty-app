import 'dart:async';
import 'package:flutter/services.dart';

class BluetoothService {
  static const EventChannel _eventChannel = EventChannel(
    'com.safty_gadgate.safty_app/bluetooth_events',
  );

  static const MethodChannel _channel = MethodChannel(
    'com.safty_gadgate.safty_app/bluetooth',
  );

  static Stream<Map<String, String>> get scanDevicesStream {
    return _eventChannel.receiveBroadcastStream().map((device) {
      return Map<String, String>.from(device);
    });
  }

  static Future<bool> connectDevice(String address) async {
    try {
      final bool connected = await _channel.invokeMethod('connectDevice', {
        'address': address,
      });
      return connected;
    } on PlatformException catch (e) {
      print('Failed to connect: ${e.message}');
      return false;
    }
  }

  static Future<bool> isBluetoothOn() async {
    try {
      final bool isOn = await _channel.invokeMethod('checkBluetooth');
      return isOn;
    } on PlatformException catch (e) {
      print('Failed to check Bluetooth: ${e.message}');
      return false;
    }
  }

  static Future<void> enableBluetooth() async {
    try {
      await _channel.invokeMethod('enableBluetooth');
    } on PlatformException catch (e) {
      print('Failed to enable Bluetooth: ${e.message}');
    }
  }
}
