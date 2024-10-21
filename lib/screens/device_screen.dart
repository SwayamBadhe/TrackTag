import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as BluePlus; // Alias for flutter_blue_plus
import '../services/bluetooth_service.dart' as CustomBluetoothService; // Alias for your custom Bluetooth service
import '../models/bluetooth_device_model.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDeviceModel device;

  DeviceScreen({required this.device});

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  CustomBluetoothService.CustomBluetoothService _bluetoothService = CustomBluetoothService.CustomBluetoothService();
  BluePlus.BluetoothDevice? _connectedDevice;
  List<BluePlus.BluetoothService> _services = [];

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  void _connectToDevice() async {
    BluePlus.BluetoothDevice device = BluePlus.BluetoothDevice.fromId(widget.device.id);
    
    try {
      await _bluetoothService.connectToDevice(device);
      setState(() {
        _connectedDevice = device;
      });
      _discoverServices(device);
    } catch (e) {
      // Handle connection errors here, such as showing a message to the user
      print('Connection error: $e');
    }
  }

  void _discoverServices(BluePlus.BluetoothDevice device) async {
    try {
      var services = await _bluetoothService.discoverServices(device);
      setState(() {
        _services = services;
      });
    } catch (e) {
      // Handle service discovery errors
      print('Service discovery error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Device Details')),
      body: _connectedDevice == null
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _services.length,
              itemBuilder: (context, index) {
                var service = _services[index];
                return ListTile(
                  title: Text(service.uuid.toString()),
                  subtitle: Text('Service'),
                );
              },
            ),
    );
  }
}
