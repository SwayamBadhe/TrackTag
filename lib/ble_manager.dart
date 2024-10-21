import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleManager {
  // Use the FlutterBluePlus directly instead of an instance
  static final FlutterBluePlus flutterBlue = FlutterBluePlus();

  // Stream for scanning results
  Stream<List<ScanResult>> get scanResultsStream => FlutterBluePlus.scanResults; // Use static access

  // Scan for BLE devices
  Future<void> startScan({List<Guid>? serviceUuids, Duration timeout = const Duration(seconds: 10)}) async {
    await FlutterBluePlus.startScan(
      withServices: serviceUuids ?? [], // Use an empty list if serviceUuids is null
      timeout: timeout,
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // Check if Bluetooth is available on the device
  Future<bool> isBluetoothSupported() async {
    return FlutterBluePlus.isSupported;
  }

  // Get connected devices
  Future<List<BluetoothDevice>> getConnectedDevices() async {
    return await FlutterBluePlus.connectedDevices; // Use static access
  }

  // Stream for Bluetooth adapter state changes
  Stream<BluetoothAdapterState> get adapterStateStream => FlutterBluePlus.adapterState; // Use static access
}
