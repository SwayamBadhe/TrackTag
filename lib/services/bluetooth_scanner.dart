// lib/services/bluetooth_scanner.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:track_tag/services/device_tracking_service.dart';
import 'package:track_tag/services/eddystone_parser.dart';
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
      print("Bluetooth permissions not granted.");
      return;
    }

    if (flutterReactiveBle.status != BleStatus.ready) {
      print("Bluetooth is not ready. Requesting user to enable it...");
      await _requestEnableBluetooth();
      return;
    }

    _isScanning = true;
    _scanSubscription = flutterReactiveBle.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: true,
    ).listen(
      (device) => _processDiscoveredDevice(device, trackingService),
      onError: _handleScanError,
      onDone: () => startScan(trackingService),
    );
  }

  void _processDiscoveredDevice(DiscoveredDevice device, DeviceTrackingService trackingService) {
  try {
    final String deviceId = device.id;
    final String localName = device.name.isNotEmpty ? device.name : "Unknown";
    final List<String> serviceUuids = device.serviceUuids.map((uuid) => uuid.toString()).toList();
    final List<int> manufacturerData = device.manufacturerData;
    final int rssi = device.rssi;

    var trackingInfo = trackingService.getDeviceTrackingInfo(deviceId);
    double filteredRssi = trackingInfo.rssiFilter.update(rssi.toDouble());

    int? txPower = trackingService.extractTxPower(manufacturerData);
    double estimatedDistance = trackingService.calculateDistance(txPower, filteredRssi);

    // Store RSSI & estimated distance
    trackingService.rssiMap[deviceId] = filteredRssi.toInt();
    trackingService.distanceMap[deviceId] = estimatedDistance;

    print('\n🔹 Device Found:');
    print('ID: $deviceId');
    print('Name: $localName');
    print('RSSI: $rssi dBm (Filtered: ${filteredRssi.toStringAsFixed(1)})');
    print('Estimated Distance: ${estimatedDistance.toStringAsFixed(2)} meters');

    if (serviceUuids.isNotEmpty) {
      print('   🔧 Service UUIDs:');
      for (var uuid in serviceUuids) {
        print('      - $uuid');
      }
    }

    if (manufacturerData.isNotEmpty) {
      print('Manufacturer Data:');
      print('- Raw: ${manufacturerData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

      try {
        final eddystoneData = EddystoneParser.parseManufacturerData(manufacturerData);
        if (eddystoneData != null) {
          print('- Eddystone Format Detected:');
          print('Frame Type: ${eddystoneData['frameType']}');
        }
      } catch (e) {
        print('- Not Eddystone format');
      }
    }

    // 🔹 Update and check device status
    trackingService.updateDeviceStatus(deviceId);
    trackingService.checkDeviceStatus(deviceId); 

    // 🔹 Store device in the list (update or add new)
    final existingDeviceIndex = _devices.indexWhere((d) => d.id == deviceId);
    if (existingDeviceIndex == -1) {
      _devices.add(device);
    } else {
      _devices[existingDeviceIndex] = device;
    }

    // Notify UI
    _devicesController.add(_devices);
    notifyListeners();

    // 🔹 Alert user if within range
    if (estimatedDistance < trackingService.userDefinedRange) {
      _notificationService.showNotification(device);
      Vibration.vibrate();
    }
  } catch (e) {
    print('Error processing device data: $e');
  }
}

  void _handleScanError(dynamic error) {
    print("❌ Scan error: $error");
    _isScanning = false;
  }

  Future<bool> _checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> _requestEnableBluetooth() async {
    const platform = MethodChannel('flutter_bluetooth');
    try {
      await platform.invokeMethod('requestEnableBluetooth');
    } on PlatformException catch (e) {
      print("Failed to enable Bluetooth: ${e.message}");
    }
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      print("Connecting to $deviceId...");
      final connectionStream = flutterReactiveBle.connectToDevice(id: deviceId);

      connectionStream.listen((connectionState) {
        print("Connection state: ${connectionState.connectionState}");
      }, onError: (error) {
        print("Connection error: $error");
      });
    } catch (e) {
      print("Error connecting to device: $e");
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
