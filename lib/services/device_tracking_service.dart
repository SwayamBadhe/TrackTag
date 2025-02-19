// lib/services/device_tracking_service.dart
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:track_tag/models/device_tracking_info.dart';
import 'package:track_tag/services/notification_service.dart';
import 'package:track_tag/utils/kalman_filter.dart';

enum TrackedDeviceState {
  disconnected,
  connected,
  lost
}

class DeviceTrackingService extends ChangeNotifier {
  final NotificationService notificationService;
  final Map<String, DeviceTrackingInfo> _deviceTracking = {};
  final Map<String, Timer> _activeSearchTimers = {};
  final Map<String, List<int>> _rssiHistory = {};
  final Map<String, double> distanceMap = {};
  final Map<String, int> rssiMap = {};
  final Map<String, DateTime> lastSeenMap = {}; 

  static const Duration rssiTimeout = Duration(seconds: 10);
  static const Duration checkInterval = Duration(seconds: 1);
  static const double LOST_THRESHOLD_METERS = 10.0;
  static const int ACTIVE_SEARCH_INTERVAL = 500;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double userDefinedRange = 10.0; // Default range
  final Map<String, KalmanFilter> filters = {};

  DeviceTrackingService(this.notificationService);

  Future<void> loadTrackingPreferences(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        userDefinedRange = doc['userDefinedRange'] ?? 5.0;
      }
    } catch (e) {
      debugPrint("Error loading tracking preferences: $e");
    }
  }

  Future<void> saveTrackingPreferences(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'userDefinedRange': userDefinedRange,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving tracking preferences: $e");
    }
  }

  KalmanFilter getKalmanFilter(String deviceId) {
    filters.putIfAbsent(deviceId, () => KalmanFilter());
    
    // Cleanup old filters if last seen was long ago
    if (lastSeenMap.containsKey(deviceId) &&
        DateTime.now().difference(lastSeenMap[deviceId]!) > const Duration(minutes: 10)) {
      filters.remove(deviceId);
    }

    return filters[deviceId]!;
  }

  DeviceTrackingInfo getDeviceTrackingInfo(String deviceId) {
    return _deviceTracking.putIfAbsent(deviceId, () => 
      DeviceTrackingInfo(deviceId: deviceId, isTracking: false, lastSeen: DateTime.now()));
  }

  bool isDeviceTracking(String deviceId) {
    return _deviceTracking[deviceId]?.isTracking ?? false;
  }

  // delete later
  void debugDeviceTrackingState(String deviceId) {
    debugPrint("🔍 DeviceTrackingInfo for $deviceId:");
    debugPrint("   isTracking: ${_deviceTracking[deviceId]?.isTracking}");
    debugPrint("   lastSeen: ${_deviceTracking[deviceId]?.lastSeen}");
  }

  // called in device_status_page
  Future<void> toggleTracking(String deviceId) async {
    debugDeviceTrackingState(deviceId);
    debugDeviceTrackingState(deviceId);
  }


/// *****************Distance Calculation*****************///
  double getEstimatedDistance(String deviceId) {
    return distanceMap[deviceId] ?? -1.0;
  }

  double calculateDistance(int? txPower, double rssi) {
    if (rssi >= 0 || rssi < -100) return -1.0; // Reject unrealistic values
    txPower ??= -59; 
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

  @override
  void dispose() {
    for (var timer in _activeSearchTimers.values) {
      timer.cancel();
    }
    _activeSearchTimers.clear();
    super.dispose();
  }
}
