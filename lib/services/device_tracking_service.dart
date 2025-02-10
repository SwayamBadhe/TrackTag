// lib/services/device_tracking_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:track_tag/models/device_tracking_info.dart';
import 'package:vibration/vibration.dart';
import 'package:track_tag/services/notification_service.dart';

class DeviceTrackingService {
  final NotificationService notificationService;
  final Map<String, DeviceTrackingInfo> _deviceTracking = {};
  final Map<String, Timer> _activeSearchTimers = {};
  final Map<String, List<int>> _rssiHistory = {};
  final Map<String, double> distanceMap = {};
  final Map<String, int> rssiMap = {};
  final Map<String, DateTime> lastSeenMap = {}; 
  final Duration rssiTimeout = const Duration(seconds: 10);

  static const double LOST_THRESHOLD_METERS = 10.0;
  static const int ACTIVE_SEARCH_INTERVAL = 500;
  int userDefinedRange = -90;

  DeviceTrackingService(this.notificationService);

  void checkDeviceStatus(String deviceId) {
    final lastSeen = lastSeenMap[deviceId];
    if (lastSeen == null || DateTime.now().difference(lastSeen) > rssiTimeout) {
      print("⚠️ Device $deviceId is lost (RSSI timeout exceeded).");
      trackLostDevice(deviceId);
    }
  }

  void checkRssiTimeout() {
    DateTime now = DateTime.now();
    lastSeenMap.forEach((deviceId, lastSeen) {
      if (now.difference(lastSeen) > rssiTimeout) {
        print("🔴 RSSI timeout exceeded for device: $deviceId.");
        trackLostDevice(deviceId);
      }
    });
  }

  DeviceTrackingInfo getDeviceTrackingInfo(String deviceId) {
    return _deviceTracking.putIfAbsent(deviceId, () => DeviceTrackingInfo());
  }

  bool isDeviceTracking(String deviceId) {
    return _deviceTracking[deviceId]?.isTracking ?? false;
  }

   Future<void> toggleTracking(String deviceId) async {
    var trackingInfo = getDeviceTrackingInfo(deviceId);
    trackingInfo.isTracking = !trackingInfo.isTracking;

    if (trackingInfo.isTracking) {
      startActiveSearch(deviceId);
    } else {
      _stopActiveSearch(deviceId);
    }
  }

  // Add trackLostDevice method
  void trackLostDevice(String deviceId) {
    if (!rssiMap.containsKey(deviceId)) {
        print("Device $deviceId not found in scan data.");
        return;
    }

    int rssi = rssiMap[deviceId] ?? -100;
    double distance = distanceMap[deviceId] ?? -1.0;

    print("Tracking lost device $deviceId...");
    print("Last known RSSI: $rssi dBm, Estimated Distance: ${distance.toStringAsFixed(2)} meters");

    // Check if the device is outside the user-defined range
    if (rssi < userDefinedRange || distance < 0) {
        print("🚨 Marking device $deviceId as lost.");
        notificationService.showNotification(DiscoveredDevice(
          id: deviceId,
          name: "Lost Device",
          manufacturerData: Uint8List(0),
          rssi: rssi,
          serviceUuids: const [],
          serviceData: const {},
        ));
        
        notificationService.showNotification(DiscoveredDevice(
            id: deviceId,
            name: "Lost Device",
            manufacturerData: Uint8List(0),
            rssi: rssi,
            serviceUuids: const [],
            serviceData: const {},
        ));

        Vibration.vibrate();
        print("Device $deviceId is lost!");
    }
  }

  // Add these tracking-related methods from the original file
  void startActiveSearch(String deviceId) {
    var trackingInfo = getDeviceTrackingInfo(deviceId);
    trackingInfo.activeTrackingTimer?.cancel();
    
    trackingInfo.activeTrackingTimer = Timer.periodic(
      const Duration(milliseconds: ACTIVE_SEARCH_INTERVAL),
      (_) => updateDeviceStatus(deviceId)
    );
  }

  void _stopActiveSearch(String deviceId) {
    _activeSearchTimers[deviceId]?.cancel();
    _activeSearchTimers.remove(deviceId);
  }

  void updateDeviceStatus(String deviceId) {
    var trackingInfo = getDeviceTrackingInfo(deviceId);
    var currentDistance = getEstimatedDistance(deviceId);

    // Update last seen timestamp
    lastSeenMap[deviceId] = DateTime.now();

    if (currentDistance > 0) {
        if (trackingInfo.lastDistance > 0) {
            double difference = currentDistance - trackingInfo.lastDistance;
            if (difference.abs() > 0.5) {
                trackingInfo.movementStatus = difference < 0 ? 'Getting Closer' : 'Moving Away';
            } else {
                trackingInfo.movementStatus = 'Stationary';
            }
        }

        trackingInfo.isLost = currentDistance > LOST_THRESHOLD_METERS;
        trackingInfo.lastDistance = currentDistance;
        trackingInfo.lastSeen = DateTime.now();

        // Trigger vibration alert if lost
        if (trackingInfo.isLost && trackingInfo.isTracking) {
            Vibration.vibrate();
        }
    }
}

  double getEstimatedDistance(String deviceId) {
    return distanceMap[deviceId] ?? -1.0;
  }

 double calculateDistance(int? txPower, double rssi) {
    if (txPower == null) txPower = -59; 
    if (rssi == 0) return -1.0; 

    const double pathLossExponent = 2.7; 
    return pow(10, (txPower - rssi) / (10 * pathLossExponent)).toDouble();
  }

  int? extractTxPower(List<int> manufacturerData) {
    if (manufacturerData.isEmpty) return null;
    return manufacturerData.last;
  }

  double applyMovingAverage(String deviceId, double newRssi) {
    const int windowSize = 5;
    _rssiHistory.putIfAbsent(deviceId, () => []);
    List<int> history = _rssiHistory[deviceId]!;

    if (history.length >= windowSize) {
      history.removeAt(0);
    }
    history.add(newRssi.toInt());

    return history.reduce((a, b) => a + b) / history.length;
  }

  int getSmoothedRssi(String deviceId) {
    return rssiMap[deviceId] ?? -100;
  }

  void dispose() {
    for (var timer in _activeSearchTimers.values) {
      timer.cancel();
    }
    _activeSearchTimers.clear();
  }
}
