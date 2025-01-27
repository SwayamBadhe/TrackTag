import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<BluetoothService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Devices")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: bluetoothService.isScanning ? null : bluetoothService.startScan,
            child: const Text("Start Scan"),
          ),
          ElevatedButton(
            onPressed: bluetoothService.isScanning ? bluetoothService.stopScan : null,
            child: const Text("Stop Scan"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bluetoothService.devices.length,
              itemBuilder: (context, index) {
                final device = bluetoothService.devices[index];
                return ListTile(
                  title: Text(device.name.isNotEmpty ? device.name : "Unknown Device"),
                  subtitle: Text(device.id),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, device.name);
                    },
                    child: const Text("Add"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
