import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_tag/services/device_service.dart';
import 'package:track_tag/screens/home_page.dart';

class RegisterDevicePage extends StatefulWidget {
  final String deviceId; // Device ID to register

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
      final deviceService = DeviceService();
      await deviceService.registerDevice(widget.deviceId, _deviceNameController.text);

      // Save the device locally
      final prefs = await SharedPreferences.getInstance();
      List<String> deviceIds = prefs.getStringList('device_ids') ?? [];

      if (!deviceIds.contains(widget.deviceId)) {
        deviceIds.add(widget.deviceId);
        await prefs.setStringList('device_ids', deviceIds);
      }

      // Navigate to HomePage with updated device list
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(devices: deviceIds),
        ),
        (route) => false, // Removes all previous routes from the stack
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}"; // Show specific error message
      });
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
