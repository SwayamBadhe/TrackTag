import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:track_tag/services/eddystone_parser.dart';
import 'dart:async';

class BluetoothService extends ChangeNotifier {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final StreamController<List<DiscoveredDevice>> _devicesController =
      StreamController.broadcast();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<DiscoveredDevice> _devices = [];
  final Map<String, int> _rssiMap = {};
  int userDefinedRange = -70; // default RSSI value

  Stream<List<DiscoveredDevice>> get deviceStream => _devicesController.stream;

  List<DiscoveredDevice> get devices => _devices;
  bool get isScanning => _rssiMap.isNotEmpty;

  BluetoothService() {
    _initNotifcations();
    startScan();
  }

  /// Initializes local notifications for the application.
  /// Uses `FlutterLocalNotificationsPlugin` for Android-specific settings.
  Future<void> _initNotifcations() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Starts scanning for BLE devices and filters Eddystone beacons.
  /// Stores unique devices and updates their RSSI values in a map.
  void startScan() {
    _ble.scanForDevices(withServices: []).listen((device) {
      if (EddystoneParser.isEddystone(device)) {
        if (!_devices.any((d) => d.id == device.id)) {
          _devices.add(device);
        }
        _rssiMap[device.id] = device.rssi;
        _devicesController.add(_devices);
        notifyListeners();
        _checkDeviceRange(device);
      }
    }, onError: (error) {
      print("Scan error: $error");
    });
  }

  void stopScan() {
    _rssiMap.clear();
    notifyListeners();
  }

  void _checkDeviceRange(DiscoveredDevice device) {
    if (_rssiMap[device.id]! < userDefinedRange) {
      _triggerAlerts(device);
    }
  }

  Future<void> _triggerAlerts(DiscoveredDevice device) async {
    _showNotification(device);
    Vibration.vibrate(duration: 500);
    print("ALERT: Device out of range - ${device.name}");
  }

  /// Displays a high-priority notification when a Bluetooth device is lost.
  /// Uses Android's notification system to alert the user.
  Future<void> _showNotification(DiscoveredDevice device) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('bluetooth_alerts', 'Bluetooth Alerts',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(0, "Device Lost",
        "${device.name} is out of range", platformChannelSpecifics);
  }

  Future<void> disconnectDevice() async {
    print("Device disconnected.");
  }
}
