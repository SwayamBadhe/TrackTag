// lib/services/bluetooth_service.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_tag/services/notification_service.dart';
import 'package:track_tag/services/bluetooth_scanner.dart';
import 'package:track_tag/services/device_tracking_service.dart';
import 'package:track_tag/services/auth_service.dart';
import 'package:track_tag/models/device_tracking_info.dart';

class BluetoothService extends ChangeNotifier {
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  late final NotificationService _notificationService;
  late final BluetoothScanner _bluetoothScanner;
  late final DeviceTrackingService _deviceTrackingService;
  late final AuthService _authService;
  
  StreamSubscription<BleStatus>? _bluetoothStatusSubscription;
  bool get isScanning => _bluetoothScanner.isScanning;
  Stream<List<DiscoveredDevice>> get deviceStream => _bluetoothScanner.deviceStream;
  List<DiscoveredDevice> get devices => _bluetoothScanner.devices;

  BluetoothService() {
    _notificationService = NotificationService();
    _bluetoothScanner = BluetoothScanner(flutterReactiveBle, _notificationService);
    _deviceTrackingService = DeviceTrackingService(_notificationService);
    _authService = AuthService(_auth);
    _initializeBluetoothMonitoring();
  }


  DeviceTrackingInfo getDeviceTrackingInfo(String deviceId) {
    return _deviceTrackingService.getDeviceTrackingInfo(deviceId);
  }

  Future<void> toggleTracking(String deviceId) async {
    await _deviceTrackingService.toggleTracking(deviceId);
    if (_deviceTrackingService.isDeviceTracking(deviceId)) {
      await startScan();
    }
    notifyListeners();
  }

  Future<void> startScan() async {
    if (!isScanning) {
        await _bluetoothScanner.startScan(_deviceTrackingService);
        notifyListeners();
    }
  }

  void stopScan() {
      if (isScanning) {
          _bluetoothScanner.stopScan();
          notifyListeners();
      }
  }

  Future<User?> signInWithEmail(String email, String password) => 
      _authService.signInWithEmail(email, password);

  Future<void> signOut() => _authService.signOut();

  Future<User?> registerWithEmail(String email, String password) =>
      _authService.registerWithEmail(email, password);

  Future<void> addDevice(String deviceId, User user, BuildContext context) =>
      _authService.addDevice(deviceId, user, context);

  Future<void> connectToDevice(String deviceId) =>
      _bluetoothScanner.connectToDevice(deviceId);

  void trackLostDevice(String deviceId) =>
      _deviceTrackingService.trackLostDevice(deviceId);

  Future<void> disconnectDevice() async {
    print("Device disconnected.");
  }

   double getEstimatedDistance(String deviceId) =>
      _deviceTrackingService.getEstimatedDistance(deviceId);

  int getSmoothedRssi(String deviceId) =>
      _deviceTrackingService.getSmoothedRssi(deviceId);

  void startActiveSearch(String deviceId) =>
      _deviceTrackingService.startActiveSearch(deviceId);
  
  Future<void> _initializeBluetoothMonitoring() async {
    _bluetoothStatusSubscription = flutterReactiveBle.statusStream.listen((status) {
      print('Bluetooth status changed: $status');
      if (status == BleStatus.ready && !isScanning) {
        startScan();
      } else if (status != BleStatus.ready) {
        stopScan();
      }
    });
  }

  @override
  void dispose() {
    _deviceTrackingService.dispose();
    _bluetoothScanner.dispose();
    _bluetoothStatusSubscription?.cancel();
    super.dispose();
  }
}

