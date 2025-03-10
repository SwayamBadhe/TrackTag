// lib/services/background_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:track_tag/services/bluetooth_service.dart';
import 'package:track_tag/services/device_tracking_service.dart';
import 'package:track_tag/services/notification_service.dart';

GlobalKey<NavigatorState>? _navigatorKey;

Future<void> initializeBackgroundService(
    NotificationService notificationService,
    BluetoothService bluetoothService,
    DeviceTrackingService deviceTrackingService,
    GlobalKey<NavigatorState> navigatorKey,
) async {
  final service = FlutterBackgroundService();
  _navigatorKey = navigatorKey;

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      foregroundServiceTypes: const [AndroidForegroundType.connectedDevice],
      notificationChannelId: "ble_tracker_channel",
      initialNotificationTitle: "TrackTag",
      initialNotificationContent: "Initializing background service",
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final notificationService = NotificationService();

  if (_navigatorKey == null) {
    debugPrint("NavigatorKey is null in background service.");
    return;
  }

  final trackingService = DeviceTrackingService(notificationService, _navigatorKey!);
  final bluetoothService = BluetoothService(_navigatorKey!);

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "TrackTag",
      content: "Tracking devices in the background",
    );
  }

  service.on("stopService").listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "TrackTag Active",
        content: "Last scan: ${DateTime.now()}",
      );
    }

    await bluetoothService.startScan(trackingService);
  });
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  return true;
}

Future<void> stopBackgroundService() async {
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();

  if (isRunning) {
    service.invoke("stopService");
  }
}
