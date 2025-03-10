import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_tag/services/bluetooth_service.dart'; 
import 'package:track_tag/screens/home_page.dart';
import 'package:provider/provider.dart';
import 'package:track_tag/services/device_tracking_service.dart';
import 'package:track_tag/services/notification_service.dart';

class RegisterDevicePage extends StatefulWidget {
  final String deviceId;

  const RegisterDevicePage({super.key, required this.deviceId});

  @override
  RegisterDevicePageState createState() => RegisterDevicePageState();
}

class RegisterDevicePageState extends State<RegisterDevicePage> {
  final TextEditingController _deviceNameController = TextEditingController();
  bool _isRegistering = false;
  String? _errorMessage;

  Future<void> _registerDevice() async {
    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });
    try {
      final trackingService = Provider.of<DeviceTrackingService>(context, listen: false);
      final bluetoothService = Provider.of<BluetoothService>(context, listen: false);

      if (!trackingService.getTrackedDevices().contains(widget.deviceId)) {
        await trackingService.toggleTracking(widget.deviceId, bluetoothService);
      }
      await trackingService.renameDevice(widget.deviceId, _deviceNameController.text);

      final prefs = await SharedPreferences.getInstance();
      List<String> deviceIds = prefs.getStringList('device_ids') ?? [];
      if (!deviceIds.contains(widget.deviceId)) {
        deviceIds.add(widget.deviceId);
        await prefs.setStringList('device_ids', deviceIds);
      }

      await Provider.of<NotificationService>(context, listen: false).showSimpleNotification(
        title: 'Device Registered',
        body: '${_deviceNameController.text} has been added',
        payload: widget.deviceId,
        id: widget.deviceId.hashCode,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage(devices: deviceIds)),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
      });
      await Provider.of<NotificationService>(context, listen: false).showSimpleNotification(
        title: 'Registration Failed',
        body: 'Error: ${e.toString()}',
        payload: widget.deviceId,
        id: widget.deviceId.hashCode,
      );
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Device")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Device ID: ${widget.deviceId}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: _deviceNameController,
              decoration: const InputDecoration(labelText: "Device Name"),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRegistering ? null : _registerDevice,
                child: _isRegistering
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register Device"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}