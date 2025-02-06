import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:track_tag/services/bluetooth_service.dart';
import 'package:track_tag/screens/register_device_page.dart';
import 'package:track_tag/screens/homepage.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanDevicePage extends StatefulWidget {
  const ScanDevicePage({super.key});

  @override
  _ScanDevicePageState createState() => _ScanDevicePageState();
}

class _ScanDevicePageState extends State<ScanDevicePage> {
  final TextEditingController _deviceIdController = TextEditingController();
  String? _scannedData;
  bool _isScanning = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartScan();
  }

  Future<void> _checkPermissionsAndStartScan() async {
    // Check and request Bluetooth permissions
    if (await _requestBluetoothPermissions()) {
      Provider.of<BluetoothService>(context, listen: false).startScan();
      setState(() {
        _isScanning = true;
      });
    }
  }

  Future<bool> _requestBluetoothPermissions() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      return true;
    } else {
      // Show alert if permissions are denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions are required')),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<BluetoothService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Device')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_scannedData != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Scanned Device ID: $_scannedData'),
              ),
            TextFormField(
              controller: _deviceIdController,
              decoration: const InputDecoration(labelText: 'Enter Device ID'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showScanner,
              child: const Text('Scan QR Code'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _submitDeviceId(bluetoothService),
              child: _isConnecting
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Register Device'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: bluetoothService.isScanning
                  ? bluetoothService.stopScan
                  : bluetoothService.startScan,
              child: Text(bluetoothService.isScanning ? "Stop Scan" : "Start Scan"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: bluetoothService.devices.length,
                itemBuilder: (context, index) {
                  final device = bluetoothService.devices[index];
                  return ListTile(
                    title: Text(device.name.isNotEmpty ? device.name : "Unknown Device"),
                    subtitle: Text("ID: ${device.id} | RSSI: ${device.rssi}"),
                    onTap: () {
                      setState(() {
                        _deviceIdController.text = device.id;
                      });
                    },
                  );
                },
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  void _showScanner() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MobileScanner(
        onDetect: (BarcodeCapture barcodeCapture) {
          setState(() {
            _scannedData = barcodeCapture.barcodes.first.rawValue;
            _deviceIdController.text = _scannedData ?? '';
          });
          Navigator.of(context).pop();
        },
      ),
    ));
  }

  Future<void> _submitDeviceId(BluetoothService bluetoothService) async {
    final deviceId = _deviceIdController.text.trim();

    if (deviceId.isNotEmpty) {
      setState(() {
        _isConnecting = true;
      });

      try {
        // Connect to the device
        await bluetoothService.connectToDevice(deviceId);

        // Save the device ID using SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        List<String> deviceIds = prefs.getStringList('device_ids') ?? [];

        if (!deviceIds.contains(deviceId)) {
          deviceIds.add(deviceId); // Add the new device ID
          await prefs.setStringList('device_ids', deviceIds);
        }

        // Notify the user and navigate to the HomePage
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device connected: $deviceId')),
        );

        // Navigate to the RegisterDevicePage
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => RegisterDevicePage(deviceId: deviceId),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to device: $deviceId')),
        );
      } finally {
        setState(() {
          _isConnecting = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Device ID')),
      );
    }
  }
}
