// lib/models/device_tracking_info.dart
import 'dart:async';
import 'package:track_tag/utils/kalman_filter.dart';

class DeviceTrackingInfo {
  bool isTracking;
  bool isLost;
  KalmanFilter rssiFilter;
  DateTime? lastSeen;
  String movementStatus;
  double lastDistance;
  Timer? activeTrackingTimer;

  DeviceTrackingInfo()
      : isTracking = false,
        isLost = false,
        rssiFilter = KalmanFilter(),
        movementStatus = 'Stationary',
        lastDistance = -1;
}
