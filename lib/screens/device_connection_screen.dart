import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DeviceConnectionScreen extends StatelessWidget {
  final DiscoveredDevice device;

  const DeviceConnectionScreen({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<BluetoothService>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Connected to ${device.name}")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Device ID: ${device.id}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: bluetoothService.disconnectDevice,
              child: const Text("Disconnect"),
            ),
          ],
        ),
      ),
    );
  }
}
