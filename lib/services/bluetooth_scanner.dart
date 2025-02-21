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

  Future<void> startScan(DeviceTrackingService trackingService, bool isForScanAll) async {

    if (_isScanning) return;

    bool hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) {
      debugPrint("Bluetooth permissions not granted.");
      return;
    }

    if (flutterReactiveBle.status != BleStatus.ready) {
      debugPrint("Bluetooth not ready: ${flutterReactiveBle.status}. Requesting enable...");
      await _requestEnableBluetooth();
      await Future.delayed(const Duration(seconds: 2));
      if (flutterReactiveBle.status != BleStatus.ready) {
        debugPrint("Bluetooth still not ready: ${flutterReactiveBle.status}");
        return;
      }
    }

    try {
      _isScanning = true;
      notifyListeners();

      _scanSubscription?.cancel(); // Ensure no lingering subscription
      _scanSubscription = flutterReactiveBle.scanForDevices(
        withServices: [], // Empty list to scan all devices, filter in processing
        scanMode: ScanMode.lowLatency,
        requireLocationServicesEnabled: true,
      ).listen(
        (device) => _processDiscoveredDevice(device, trackingService, isForScanAll),
        onError: _handleScanError,
        onDone: () async {
          debugPrint("Scan completed.");
          if (_isScanning) {
            await Future.delayed(const Duration(seconds: 1)); // Reduced delay for continuity
            startScan(trackingService, isForScanAll);
          } else {
            debugPrint("Scan stopped manually, not restarting.");
            notifyListeners();
          }
        },
      );
      debugPrint("Started scanning with isForScanAll: $isForScanAll");
    } catch (e) {
      debugPrint("❌ Failed to start scan: $e");
      _isScanning = false;
      notifyListeners();
    }
  }

  void _processDiscoveredDevice(DiscoveredDevice device, DeviceTrackingService trackingService, bool isForScanAll) {
    try {
      if (!isForScanAll && !trackingService.getTrackedDevices().contains(device.id)) {
        debugPrint("Filtered out device ${device.id} - not tracked");
        return; // Ignore untracked devices when scanning for tracking
      }

      final String deviceId = device.id;
      final int rssi = device.rssi;

      var filter = trackingService.getKalmanFilter(deviceId);
      double filteredRssi = filter.update(rssi.toDouble());

      int? txPower = trackingService.extractTxPower(device.manufacturerData);
      double estimatedDistance = trackingService.calculateDistance(txPower, filteredRssi);

      final double previousDistance = trackingService.distanceMap[deviceId] ?? -1.0;
      final int previousRssi = trackingService.rssiMap[deviceId] ?? -100;

      if ((filteredRssi - previousRssi).abs() < 1.5 && (estimatedDistance - previousDistance).abs() < 0.2) {
        return; // No significant change, ignore
      }

      trackingService.rssiMap[deviceId] = filteredRssi.toInt();
      trackingService.distanceMap[deviceId] = estimatedDistance;
      trackingService.lastSeenMap[deviceId] = DateTime.now();

      debugPrint("📡 Device $deviceId: RSSI=$rssi, Filtered RSSI=$filteredRssi, Distance=$estimatedDistance");

      // Update existing device or add new one
      final existingDeviceIndex = _devices.indexWhere((d) => d.id == deviceId);
      if (existingDeviceIndex >= 0) {
        _devices[existingDeviceIndex] = device;
      } else {
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
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
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
    notifyListeners();
    debugPrint("Scan stopped.");
  }

   @override
   void dispose() {
    _scanSubscription?.cancel();
    _devicesController.close();
    super.dispose();
  }
}
