// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:get/get.dart';

// class BleController extends GetxController {
//   final FlutterReactiveBle _ble = FlutterReactiveBle();
//   final _foundDevices = <DiscoveredDevice>[].obs;

//   Stream<List<DiscoveredDevice>> get scanResults => _foundDevices.stream;

//   void startScan() {
//     _ble.scanForDevices(withServices: []).listen((device) {
//       _foundDevices.add(device);
//     });
//   }
// }


import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';

class BleController extends GetxController {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final _foundDevices = <DiscoveredDevice>[].obs;

  Stream<List<DiscoveredDevice>> get scanResults => _foundDevices.stream;

  void startScan() {
    _ble.scanForDevices(withServices: []).listen((device) {
      // Check if the device is already in the list using its unique id
      if (_foundDevices.indexWhere((d) => d.id == device.id) == -1) {
        _foundDevices.add(device); // Only add the device if it's new
      }
    });
  }
}
