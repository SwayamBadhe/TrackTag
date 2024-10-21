import 'package:flutter_blue_plus/flutter_blue_plus.dart' as BluePlus;
import '../models/bluetooth_device_model.dart';

class CustomBluetoothService {
  // Start scanning for BLE devices and return a List of BluetoothDeviceModel
  Future<List<BluetoothDeviceModel>> scanForDevices() async {
    List<BluetoothDeviceModel> devices = [];

    // Start scanning
    await BluePlus.FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

    // Listen for scan results
    var subscription = BluePlus.FlutterBluePlus.scanResults.listen((scanResults) {
      for (var result in scanResults) {
        devices.add(BluetoothDeviceModel.fromScanResult(result));
      }
    });

    // Wait for the scan to complete
    await Future.delayed(Duration(seconds: 10));

    // Stop scanning
    await BluePlus.FlutterBluePlus.stopScan();

    // Cancel the subscription
    await subscription.cancel();

    return devices;
  }

  // Connect to a BLE device
  Future<void> connectToDevice(BluePlus.BluetoothDevice device) async {
    await device.connect();
  }

  // Disconnect from a BLE device
  Future<void> disconnectFromDevice(BluePlus.BluetoothDevice device) async {
    await device.disconnect();
  }

  // Discover services offered by a device
  Future<List<BluePlus.BluetoothService>> discoverServices(BluePlus.BluetoothDevice device) async {
    return await device.discoverServices();
  }
}
