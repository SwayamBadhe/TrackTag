import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  Future<bool> requestBluetoothPermissions() async {
    final status = await Permission.bluetooth.request();
    final statusLocation = await Permission.location.request();

    // Check if both Bluetooth and Location permissions are granted
    return status.isGranted && statusLocation.isGranted;
  }
}
