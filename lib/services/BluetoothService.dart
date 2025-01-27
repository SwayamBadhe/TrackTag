import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter/material.dart';

class BluetoothService with ChangeNotifier {
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<DiscoveredDevice> _scanStreamSubscription;
  final List<DiscoveredDevice> _devices = [];
  List<DiscoveredDevice> get devices => _devices;
  
  BluetoothService? connectedDevice;

  BluetoothService() {
    _startScanning();
  }

  void _startScanning() {
    _scanStreamSubscription = flutterReactiveBle.scanForDevices(
      withServices: [], // Optional: You can specify services to scan for
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (!_devices.any((d) => d.id == device.id)) {
        _devices.add(device);
        notifyListeners(); // Notify listeners when a new device is found
      }
    }, onError: (error) {
      print("Scanning error: $error");
    });
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    try {
      final connection = await flutterReactiveBle.connectToDevice(
        id: device.id,
        servicesWithCharacteristicsToDiscover: {},
        connectionTimeout: Duration(seconds: 10),
      );

      connectedDevice = device as BluetoothService?;
      print('Connected to ${device.name}');
      notifyListeners();
    } catch (e) {
      print('Connection failed: $e');
    }
  }

  void stopScanning() {
    _scanStreamSubscription.cancel();
  }
}
