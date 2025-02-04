import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class EddystoneParser {
  static bool isEddystone(DiscoveredDevice device) {
    return device.manufacturerData.isNotEmpty &&
        device.manufacturerData.length >= 20 &&
        device.manufacturerData[0] == 0xAA &&
        device.manufacturerData[1] == 0xFE &&
        device.manufacturerData[2] == 0x00;
  }
}
