import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController {
  final FlutterReactiveBle ble = FlutterReactiveBle();

  // This will hold the list of discovered devices
  final RxList<DiscoveredDevice> _discoveredDevices = <DiscoveredDevice>[].obs;

  // This Function will help users scan nearby BLE devices and get the list of Bluetooth devices.
  Future<void> scanDevices() async {
    if (await Permission.bluetoothScan.request().isGranted) {
      if (await Permission.bluetoothConnect.request().isGranted) {
        ble.scanForDevices(withServices: []).listen((device) {
          if (!_discoveredDevices.any((d) => d.id == device.id)) {
            _discoveredDevices.add(device); // Add new devices only
          }
        });
        // Stopping scan after 15 seconds
        await Future.delayed(Duration(seconds: 15), () {
          ble.deinitialize();
        });
      }
    }
  }

  // This function will help user connect to BLE devices.
  Future<void> connectToDevice(DiscoveredDevice device) async {
    final connection = ble.connectToDevice(id: device.id);

    connection.listen((connectionState) {
      if (connectionState.connectionState == DeviceConnectionState.connecting) {
        print("Device connecting to: ${device.name}");
      } else if (connectionState.connectionState ==
          DeviceConnectionState.connected) {
        print("Device connected: ${device.name}");
      } else if (connectionState.connectionState ==
          DeviceConnectionState.disconnected) {
        print("Device Disconnected: ${device.name}");
      }
    });
  }

  // Getter for discovered devices
  List<DiscoveredDevice> get scanResults => _discoveredDevices;
}
