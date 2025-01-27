import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothService extends ChangeNotifier {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  late DiscoveredDevice _connectedDevice;

  List<DiscoveredDevice> devices = [];
  bool isScanning = false;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;

  get connectedDeviceId => null;

  void startScan() {
    if (isScanning) return;

    isScanning = true;
    devices = [];
    notifyListeners();

    _scanSubscription = _ble.scanForDevices(withServices: []).listen((device) {
      if (devices.every((d) => d.id != device.id)) {
        devices.add(device);
        notifyListeners();
      }
    }, onDone: stopScan);
  }

  void stopScan() {
    _scanSubscription?.cancel();
    isScanning = false;
    notifyListeners();
  }

  Future<void> connectToDevice(String deviceId) async {
    _connectionSubscription = _ble.connectToDevice(id: deviceId).listen((connectionState) {
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        _connectedDevice = devices.firstWhere((d) => d.id == deviceId);
        notifyListeners();
      }
    }, onError: (error) {
      print("Connection error: $error");
    });
  }

  Future<void> disconnectDevice() async {
    _connectionSubscription?.cancel();
    notifyListeners();
  }

  void startScanning() {}

  void stopScanning() {}
}
