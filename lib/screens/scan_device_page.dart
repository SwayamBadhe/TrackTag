import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:track_tag/services/bluetooth_service.dart';
import 'package:track_tag/screens/register_device_page.dart';
import 'package:track_tag/screens/device_info_card.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_tag/services/device_tracking_service.dart';
import 'package:image_picker/image_picker.dart';

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
  late BluetoothService? _bluetoothService;
  bool _isFlashOn = false;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    _bluetoothService?.addListener(_updateScanningState);
  }

  void _updateScanningState() {
    if (mounted && _bluetoothService != null) {
      setState(() {
        _isScanning = _bluetoothService!.isScanning;
      });
    }
  }

  @override
  void dispose() {
    _bluetoothService?.removeListener(_updateScanningState);
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _startScanning() async {
    final bluetoothService =
        Provider.of<BluetoothService>(context, listen: false);
    final trackingService =
        Provider.of<DeviceTrackingService>(context, listen: false);

    if (bluetoothService.flutterReactiveBle.status == BleStatus.ready) {
      bluetoothService.stopScan();
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        _bluetoothService?.startScan(trackingService, isForScanAll: true);
        setState(() {
          _isScanning = true;
        });
      } catch (e) {
        debugPrint("Failed to start scan: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start scanning: $e')),
        );
      }
    } else {
      debugPrint("Bluetooth is not enabled.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable Bluetooth')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<BluetoothService>(context);
    final trackingService = Provider.of<DeviceTrackingService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Device')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(
                12.0), // Adds margin around the TextFormField
            child: TextFormField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: 'Enter Device ID',
                border:
                    OutlineInputBorder(), // Adds a box around the text field
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0), // Adds padding inside the text field
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.all(12.0), // Adds margin around the button
            child: SizedBox(
              width: double.infinity, // Makes the button full-width
              child: ElevatedButton(
                onPressed: _showScanner,
                child: const Text('Scan QR Code'),
              ),
            ),
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
                    child: Text(
                      'No Bluetooth devices found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final sortedDevices = List<DiscoveredDevice>.from(devices)
                  ..sort((a, b) => b.rssi.compareTo(a.rssi));

                return ListView.builder(
                  itemCount: sortedDevices.length,
                  itemBuilder: (context, index) {
                    final device = sortedDevices[index];
                    final isLost =
                        trackingService.isDeviceInLostMode(device.id);
                    return DeviceInfoCard(
                      key: ValueKey(device.id),
                      device: device,
                      smoothedRssi: device.rssi,
                      onDeviceSelected: (deviceId) {
                        setState(() {
                          _deviceIdController.text = deviceId;
                        });
                      },
                      trailing: isLost
                          ? const Icon(Icons.warning, color: Colors.orange)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _submitDeviceId(bluetoothService),
        label: _isConnecting
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text('Register Device'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showScanner() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('QR Scanner')),
        body: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: (BarcodeCapture barcodeCapture) {
                setState(() {
                  _scannedData = barcodeCapture.barcodes.first.rawValue;
                  _deviceIdController.text = _scannedData ?? '';
                });
                Navigator.of(context).pop();
              },
            ),
            // Center(
            //   child: Container(
            //     width: 200,
            //     height: 200,
            //     decoration: BoxDecoration(
            //       border: Border.all(color: Colors.blue, width: 4),
            //     ),
            //   ),
            // ),
            Center(
              child: Container(
                width: 250, // Adjust size as needed
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3),
                  borderRadius: BorderRadius.circular(
                      20), // Rounded edges like Google Lens
                  color: Colors.transparent, // Transparent inside
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.5 -
                  28, // Adjust positioning accordingly
              right: 10,
              child: Column(
                children: [
                  SizedBox(
                    width: 40, // Set desired width
                    height: 40, // Set desired height
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          _isFlashOn = !_isFlashOn;
                        });
                        _scannerController.toggleTorch();
                      },
                      child: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off,
                          size: 20), // Adjust icon size if needed
                    ),
                  ),
                  const SizedBox(height: 10), // Space between buttons
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: FloatingActionButton(
                      onPressed: _pickQRImage,
                      child: const Icon(Icons.image, size: 20),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    ));
  }

  Future<void> _pickQRImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Handle QR code image processing here
    }
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
