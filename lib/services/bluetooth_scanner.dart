// lib/services/bluetooth_scanner.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:track_tag/services/device_tracking_service.dart';
import 'package:track_tag/utils/kalman_filter.dart';
import 'package:vibration/vibration.dart';
import 'package:track_tag/services/notification_service.dart';

class BluetoothScanner extends ChangeNotifier {
  final FlutterReactiveBle flutterReactiveBle;
  final NotificationService _notificationService;
  StreamSubscription? _scanSubscription;
  final List<DiscoveredDevice> _devices = [];
  final _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();
  bool _isScanning = false;

  BluetoothScanner(this.flutterReactiveBle, this._notificationService);

  Stream<List<DiscoveredDevice>> get deviceStream => _devicesController.stream;
  List<DiscoveredDevice> get devices => List.unmodifiable(_devices);
  bool get isScanning => _isScanning;

  Future<void> startScan(DeviceTrackingService trackingService) async {
    if (_isScanning) return;

    bool hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) {
      debugPrint("Bluetooth permissions not granted.");
      return;
    }

    if (flutterReactiveBle.status != BleStatus.ready) {
      debugPrint("Bluetooth is not ready. Requesting user to enable it...");
      await _requestEnableBluetooth();
      return;
    }

    _isScanning = true;
    _scanSubscription = flutterReactiveBle.scanForDevices(
      withServices: [], // specific UUID services to scan for 
      scanMode: ScanMode.lowLatency, 
      requireLocationServicesEnabled: true,
    ).listen(
      (device) => _processDiscoveredDevice(device, trackingService),
      onError: _handleScanError,
      onDone: () async {
        _isScanning = false;
        await Future.delayed(const Duration(seconds: 5));
        startScan(trackingService);
      },
    );
  }

  void _processDiscoveredDevice(DiscoveredDevice device, DeviceTrackingService trackingService) {
    try {
      final String deviceId = device.id;
      final int rssi = device.rssi;

      var filter = trackingService.getKalmanFilter(deviceId);
      double filteredRssi = filter.update(rssi.toDouble());

      int? txPower = trackingService.extractTxPower(device.manufacturerData);
      double estimatedDistance = trackingService.calculateDistance(txPower, filteredRssi);

      final double previousDistance = trackingService.distanceMap[deviceId] ?? -1.0;
      final int previousRssi = trackingService.rssiMap[deviceId] ?? -100;

      if ((filteredRssi - previousRssi).abs() < 1.5 && (estimatedDistance - previousDistance).abs() < 0.5) {
        return; // No significant change, ignore
      }

      trackingService.rssiMap[deviceId] = filteredRssi.toInt();
      trackingService.distanceMap[deviceId] = estimatedDistance;

      debugPrint("📡 Device $deviceId: RSSI=$rssi, Filtered RSSI=$filteredRssi, Distance=$estimatedDistance");

      // Update existing device or add new one
      final existingDeviceIndex = _devices.indexWhere((d) => d.id == deviceId);
      if (existingDeviceIndex >= 0) {
        // Update existing device
        _devices[existingDeviceIndex] = device;
      } else {
        // Add new device
        _devices.add(device);
      }

      _devicesController.add(_devices);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error processing device: $e');
    }
  }

  void _handleScanError(dynamic error) async {
    debugPrint("❌ Scan error: $error");
    _isScanning = false;
    await Future.delayed(const Duration(seconds: 5));
  }

  Future<bool> _checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location
    ].request();

    for (var entry in statuses.entries) {
      debugPrint("Permission ${entry.key}: ${entry.value}");
    }

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> _requestEnableBluetooth() async {
    const platform = MethodChannel('flutter_bluetooth');
    try {
      await platform.invokeMethod('requestEnableBluetooth');
    } on PlatformException catch (e) {
      debugPrint("Failed to enable Bluetooth: ${e.message}");
    }
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      debugPrint("Connecting to $deviceId...");
      final connectionStream = flutterReactiveBle.connectToDevice(id: deviceId);

      connectionStream.listen((connectionState) {
        debugPrint("Connection state: ${connectionState.connectionState}");
      }, onError: (error) {
        debugPrint("Connection error: $error");
      });
    } catch (e) {
      debugPrint("Error connecting to device: $e");
    }
  }

  void stopScan() {
    if (!_isScanning) return;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    flutterReactiveBle.deinitialize();
  }

   @override
   void dispose() {
    _scanSubscription?.cancel();
    _devicesController.close();
    super.dispose();
  }
}
