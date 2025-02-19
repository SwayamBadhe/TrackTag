// lib/models/device_tracking_info.dart
import 'dart:async';
import 'package:track_tag/utils/kalman_filter.dart';

class DeviceTrackingInfo {
  final String deviceId;
  bool isTracking;
  bool isLost;
  KalmanFilter rssiFilter;
  DateTime? lastSeen;
  String movementStatus;
  double lastDistance;
  Timer? activeTrackingTimer;

  // Constructor with default values
  DeviceTrackingInfo({
    required this.deviceId,
    this.isTracking = false,
    this.isLost = false,
    KalmanFilter? rssiFilter,
    this.lastSeen,
    this.movementStatus = 'Stationary',
    this.lastDistance = -1,
  }) : rssiFilter = rssiFilter ?? KalmanFilter();
}

