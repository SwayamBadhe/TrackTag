import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:track_tag/services/bluetooth_service.dart';
import 'package:track_tag/screens/register_device_page.dart';
import 'package:track_tag/screens/device_info_card.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_tag/services/device_tracking_service.dart';

class ScanDevicePage extends StatefulWidget {
  const ScanDevicePage({super.key});

  @override
  ScanDevicePageState createState() => ScanDevicePageState();
}

class ScanDevicePageState extends State<ScanDevicePage> {
  final TextEditingController _deviceIdController = TextEditingController();
  String? _scannedData;
  bool _isScanning = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    bluetoothService.addListener(_updateScanningState);
  }

  void _updateScanningState() {
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    if (mounted) {
      setState(() {
        _isScanning = bluetoothService.isScanning;
      });
    }
  }

  @override
  void dispose() {
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    bluetoothService.removeListener(_updateScanningState);
    super.dispose();
  }

  Future<void> _startScanning() async {
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    final trackingService = Provider.of<DeviceTrackingService>(context, listen: false);

    if (bluetoothService.flutterReactiveBle.status == BleStatus.ready) {
      // Ensure we stop any existing scan before starting a new one
      bluetoothService.stopScan();

      // Wait a moment before starting a new scan (to prevent conflicts)
      await Future.delayed(const Duration(milliseconds: 500));

      bluetoothService.startScan(trackingService, isForScanAll: true);
      setState(() {
        _isScanning = true;
      });
    } else {
      debugPrint("Bluetooth is not enabled.");
    }
  }


  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<BluetoothService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Device')),
      body: Column(
        children: [
          TextFormField(
            controller: _deviceIdController,
            decoration: const InputDecoration(labelText: 'Enter Device ID'),
          ),
          ElevatedButton(
            onPressed: _showScanner,
            child: const Text('Scan QR Code'),
          ),
          ElevatedButton(
            onPressed: () => _submitDeviceId(bluetoothService),
            child: _isConnecting
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Text('Register Device'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_isScanning) {
                bluetoothService.stopScan();
                setState(() {
                  _isScanning = false;
                });
              } else {
                _startScanning();
              }
            },
            child: Text(_isScanning ? "Stop Scan" : "Start Scan"),
          ),
          Expanded(
            child: StreamBuilder<List<DiscoveredDevice>>(
              stream: bluetoothService.deviceStream,
              initialData: bluetoothService.devices,
              builder: (context, snapshot) {
                final devices = snapshot.data ?? [];

                if (_isScanning && devices.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (devices.isEmpty) {
                  return const Center(
                    child: Text('No Bluetooth devices found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                
                final sortedDevices = List<DiscoveredDevice>.from(devices)..sort((a, b) => b.rssi.compareTo(a.rssi));

                return ListView.builder(
                  itemCount: sortedDevices.length,
                  itemBuilder: (context, index) {
                    final device = sortedDevices[index];
                    return DeviceInfoCard(
                      key: ValueKey(device.id),
                      device: device,
                      smoothedRssi: device.rssi,
                      onDeviceSelected: (deviceId) {
                        setState(() {
                          _deviceIdController.text = deviceId;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
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
        await bluetoothService.connectToDevice(deviceId);
        final prefs = await SharedPreferences.getInstance();
        List<String> deviceIds = prefs.getStringList('device_ids') ?? [];

        if (!deviceIds.contains(deviceId)) {
          deviceIds.add(deviceId);
          await prefs.setStringList('device_ids', deviceIds);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device connected: $deviceId')),
        );

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
