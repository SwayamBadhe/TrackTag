import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/bluetooth_device_model.dart';

// Renamed to avoid conflict with BluetoothService in flutter_blue_plus
class CustomBluetoothService {
  // No need to create an instance of FlutterBluePlus
  // All access will be static

  // Start scanning for BLE devices
  Stream<List<BluetoothDeviceModel>> scanForDevices() async* {
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

    // Collect scan results as they come in
    await for (var scanResults in FlutterBluePlus.scanResults) {
      final devices = scanResults.map((result) {
        return BluetoothDeviceModel.fromScanResult(result);
      }).toList();
      yield devices;
    }

    // Stop scanning after the duration ends
    await FlutterBluePlus.stopScan();
  }

  // Connect to a BLE device
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
  }

  // Disconnect from a BLE device
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    await device.disconnect();
  }

  // Discover services offered by a device
  Future<List<BluetoothService>> discoverServices(BluetoothDevice device) async {
    return await device.discoverServices();
  }
}
