// lib/services/device_tracking_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:track_tag/models/device_tracking_info.dart';
import 'package:track_tag/services/bluetooth_service.dart';
import 'package:track_tag/services/notification_service.dart';
import 'package:track_tag/utils/kalman_filter.dart';

enum TrackedDeviceState {
  disconnected,
  connected,
  lost
}

class DeviceTrackingService extends ChangeNotifier {
  bool _isDisposed = false;
  final NotificationService notificationService;
  final GlobalKey<NavigatorState> navigatorKey;
  
  final Map<String, DeviceTrackingInfo> _deviceTracking = {};
  final Map<String, Timer> _activeSearchTimers = {};
  final Map<String, List<int>> _rssiHistory = {};
  final Map<String, double> distanceMap = {};
  final Map<String, int> rssiMap = {};
  final Map<String, DateTime> lastSeenMap = {}; 
  final Set<String> _trackedDevices = {};
  final Map<String, bool> _lostModeMap = {}; 
  final Map<String, int> _lastRssiForLostMode = {};
  final Map<String, TrackedDeviceState> _lastKnownState = {};

  static const Duration rssiTimeout = Duration(seconds: 30);
  static const Duration checkInterval = Duration(seconds: 1);
  static const double LOST_THRESHOLD_METERS = 10.0;
  static const int ACTIVE_SEARCH_INTERVAL = 500;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  double userDefinedRange = 15.0; // Default range
  final Map<String, KalmanFilter> filters = {};

  DeviceTrackingService(this.notificationService, this.navigatorKey) {
    Timer.periodic(checkInterval, (timer) {
      _updateTrackingStates();
    });
    Timer.periodic(const Duration(minutes: 5), (timer) {
      for (var deviceId in _trackedDevices) {
        if (getConnectionState(deviceId) == TrackedDeviceState.connected) {
          _saveDeviceStateToFirebase(deviceId);
        }
      }
    });
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> loadTrackingPreferences(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        userDefinedRange = (doc['userDefinedRange'] as num?)?.toDouble() ?? 15.0;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading tracking preferences: $e");
    }
  }

  Future<void> saveTrackingPreferences(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'userDefinedRange': userDefinedRange,
      }, SetOptions(merge: true));
      debugPrint("Saved userDefinedRange: $userDefinedRange to Firebase");
    } catch (e) {
      debugPrint("Error saving tracking preferences: $e");
    }
  }

  Future<Map<String, dynamic>> loadDeviceDetails(String deviceId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return {'description': '', 'imageUrl': null};

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trackedDevices')
          .doc(deviceId)
          .get();

      if (doc.exists) {
        return {
          'description': doc['description'] ?? '',
          'imageUrl': doc['imageUrl'],
          'lostMode': doc['lostMode'] ?? false,
        };
      }
      return {'description': '', 'imageUrl': null};
    } catch (e) {
      debugPrint("Error loading device details: $e");
      return {'description': '', 'imageUrl': null};
    }
  }

  Future<void> saveDeviceDetails(String deviceId, {String? description, File? imageFile}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint("No user signed in, skipping Firebase save for $deviceId");
        return;
      }

      final data = <String, dynamic>{};
      String? imageUrl;

      // Upload image to Firebase Storage if provided
      if (imageFile != null) {
        final ref = _storage.ref().child('device_images/$userId/$deviceId');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
        data['imageUrl'] = imageUrl;
      }

      if (description != null) {
        data['description'] = description;
      }

      if (data.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('trackedDevices')
            .doc(deviceId)
            .set(data, SetOptions(merge: true));
        debugPrint("Saved device details for $deviceId: $data");
      }
    } catch (e) {
      debugPrint("Error saving device details to Firebase: $e");
    }
  }

  KalmanFilter getKalmanFilter(String deviceId) {
    return filters.putIfAbsent(deviceId, () => KalmanFilter());
  }

  DeviceTrackingInfo getDeviceTrackingInfo(String deviceId) {
    return _deviceTracking.putIfAbsent(deviceId, () => 
      DeviceTrackingInfo(deviceId: deviceId, isTracking: false, lastSeen: DateTime.now()))
      ..isTracking = _trackedDevices.contains(deviceId);
  }

  bool isDeviceTracking(String deviceId) => _trackedDevices.contains(deviceId);

  bool isDeviceInLostMode(String deviceId) => _lostModeMap[deviceId] ?? false;

  Set<String> getTrackedDevices() => _trackedDevices;

  // delete later
  void debugDeviceTrackingState(String deviceId) {
    debugPrint("🔍 DeviceTrackingInfo for $deviceId:");
    debugPrint("   isTracking: ${_deviceTracking[deviceId]?.isTracking}");
    debugPrint("   lostMode: ${_lostModeMap[deviceId]}");
    debugPrint("   lastSeen: ${_deviceTracking[deviceId]?.lastSeen}");
    debugPrint("   distance: ${distanceMap[deviceId]}");
    debugPrint("   rssi: ${rssiMap[deviceId]}");
    debugPrint("   connectionState: ${getConnectionState(deviceId)}");
  }

  // called in device_status_page
  Future<void> toggleTracking(String deviceId, BluetoothService bluetoothService) async {
    debugDeviceTrackingState(deviceId);
    final prefs = await SharedPreferences.getInstance();
    final trackingInfo = getDeviceTrackingInfo(deviceId);

    bool wasTracking = _trackedDevices.contains(deviceId);

    if (_trackedDevices.contains(deviceId)) {
      await _saveDeviceStateToFirebase(deviceId);
      _trackedDevices.remove(deviceId);
      trackingInfo.isTracking = false;
      await prefs.setBool('tracking_$deviceId', false);
      if (wasTracking && _trackedDevices.isEmpty) {
        bluetoothService.stopScan();
      }
    } else {
      _trackedDevices.add(deviceId);
      trackingInfo.isTracking = true;
      await prefs.setBool('tracking_$deviceId', true);
      bluetoothService.startScan(this, isForScanAll: false);
    }

    notifyListeners();
    debugDeviceTrackingState(deviceId);
  }

  Future<void> toggleLostMode(String deviceId, bool enableLostMode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _lostModeMap[deviceId] = enableLostMode;
    await _saveDeviceStateToFirebase(deviceId); 
    notifyListeners();

    if (enableLostMode && isDeviceTracking(deviceId)) {
      _lastRssiForLostMode[deviceId] = getSmoothedRssi(deviceId); 
    }
  }

  String getLostModeDirection(String deviceId) {
    if (!isDeviceInLostMode(deviceId) || !isDeviceTracking(deviceId)) return "N/A";
    
    final currentRssi = getSmoothedRssi(deviceId);
    final lastRssi = _lastRssiForLostMode[deviceId] ?? currentRssi;

    if (currentRssi > lastRssi) {
      return "Moving Closer";
  } else if (currentRssi < lastRssi) {
      return "Moving Away";
    } else {
      return "No Change";
    }
  }

  TrackedDeviceState getConnectionState(String deviceId) {
    final isTracked = isDeviceTracking(deviceId);

    if (!isTracked) {
      return TrackedDeviceState.disconnected;
    }

    final lastSeen = lastSeenMap[deviceId];
    final rssi = getSmoothedRssi(deviceId);
    final distance = getEstimatedDistance(deviceId);

    if (lastSeen == null || DateTime.now().difference(lastSeen) > rssiTimeout) {
      return TrackedDeviceState.disconnected;  
    }

    if (distance > userDefinedRange && distance >= 0 && rssi > -100) {
      return TrackedDeviceState.lost;
    }

    if (rssi > -100) {
      return TrackedDeviceState.connected;
    }

    return TrackedDeviceState.disconnected;
  }

  void _updateTrackingStates() async {
    for (var deviceId in _trackedDevices) {
      final currentState = getConnectionState(deviceId);
      final previousState = _lastKnownState[deviceId] ?? TrackedDeviceState.disconnected;

      if (currentState != previousState) {
        _lastKnownState[deviceId] = currentState;
        if (currentState == TrackedDeviceState.disconnected || currentState == TrackedDeviceState.lost) {
          await _saveDeviceStateToFirebase(deviceId);
        }
      }

      // Update Lost Mode direction if active
      if (isDeviceInLostMode(deviceId) && currentState == TrackedDeviceState.connected) {
        final currentRssi = getSmoothedRssi(deviceId);
        if (_lastRssiForLostMode.containsKey(deviceId)) {
          _lastRssiForLostMode[deviceId] = currentRssi;
        }
      }
      notifyListeners();
    }
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

/// *****************Firebase*****************///
  Future<void> _saveDeviceStateToFirebase(String deviceId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint("No user signed in, skipping Firebase save for $deviceId");
        return;
      }

      final stateData = {
        'deviceId': deviceId,
        'status': getConnectionState(deviceId).toString().split('.').last,
        'distance': distanceMap[deviceId] ?? -1.0,
        'signalStrength': rssiMap[deviceId] ?? -100,
        'lastSeen': lastSeenMap[deviceId]?.toIso8601String() ?? null,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
        .collection('users')
        .doc(userId)
        .collection('trackedDevices')
        .doc(deviceId)
        .set(stateData, SetOptions(merge: true));

      debugPrint("Saved state to Firebase for $deviceId: $stateData");
    } catch (e) {
      debugPrint("Error saving device state to Firebase: $e");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (var timer in _activeSearchTimers.values) {
      timer.cancel();
    }
    _activeSearchTimers.clear();
    super.dispose();
  }
}
