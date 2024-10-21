import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceModel {
  final String name;
  final String id;

  BluetoothDeviceModel({required this.name, required this.id});

  factory BluetoothDeviceModel.fromScanResult(ScanResult result) {
    return BluetoothDeviceModel(
      name: result.device.name,
      id: result.device.remoteId.toString(),
    );
  }
}
