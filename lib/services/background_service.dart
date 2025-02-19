// lib/services/background_service.dart
import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:track_tag/services/bluetooth_service.dart';
import 'package:track_tag/services/device_tracking_service.dart';
import 'package:track_tag/services/notification_service.dart';

Future<void> initializeBackgroundService(NotificationService notificationService, 
                                         BluetoothService bluetoothService, 
                                         DeviceTrackingService trackingService) async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      onBackground: onIosBackground,
      onForeground: onStart,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final notificationService = NotificationService();
  final trackingService = DeviceTrackingService(notificationService);
  final bluetoothService = BluetoothService();

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

