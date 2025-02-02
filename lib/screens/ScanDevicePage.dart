import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:track_tag/services/bluetooth_service.dart';
import 'package:track_tag/screens/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanDevicePage extends StatefulWidget {
  const ScanDevicePage({super.key});

  @override
  _ScanDevicePageState createState() => _ScanDevicePageState();
}

class _ScanDevicePageState extends State<ScanDevicePage> {
  final TextEditingController _deviceIdController = TextEditingController();
  String? _scannedData;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    // Start scanning for Bluetooth devices
    Provider.of<BluetoothService>(context, listen: false).startScanning();
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
                  : const Text('Connect to Device'),
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
        // await prefs.setString('device_id', deviceId);
        List<String> deviceIds = prefs.getStringList('device_ids') ?? [];

        if (!deviceIds.contains(deviceId)) {
          deviceIds.add(deviceId); // Add the new device ID
          await prefs.setStringList('device_ids', deviceIds);
        }

        // Notify the user and navigate to the HomePage
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device connected: $deviceId')),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => HomePage(devices: [deviceId])),
        );
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

extension on BluetoothService {
  void startScanning() {
    // Add logic to initiate scanning for BLE devices.
  }

  Future<void> connectToDevice(String deviceId) async {
    // Add logic to connect to the device using its ID.
    print("Connecting to device: $deviceId");
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:provider/provider.dart';
// import 'package:track_tag/services/bluetooth_service.dart';
// import 'package:track_tag/screens/homepage.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ScanDevicePage extends StatefulWidget {
//   const ScanDevicePage({Key? key}) : super(key: key);

//   @override
//   _ScanDevicePageState createState() => _ScanDevicePageState();
// }

// class _ScanDevicePageState extends State<ScanDevicePage> {
//   final TextEditingController _deviceIdController = TextEditingController();
//   String? _scannedData;
//   bool _isConnecting = false;

//   @override
//   void initState() {
//     super.initState();
//     final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
//     bluetoothService.startScanning(); // Start scanning in the background
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bluetoothService = Provider.of<BluetoothService>(context);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Scan Device')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             if (_scannedData != null)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 child: Text('Scanned Device ID: $_scannedData'),
//               ),
//             TextFormField(
//               controller: _deviceIdController,
//               decoration: const InputDecoration(labelText: 'Enter Device ID'),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _showScanner,
//               child: const Text('Scan QR Code'),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => _submitDeviceId(bluetoothService),
//               child: _isConnecting
//                   ? const CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     )
//                   : const Text('Connect to Device'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showScanner() {
//     Navigator.of(context).push(MaterialPageRoute(
//       builder: (context) => MobileScanner(
//         onDetect: (BarcodeCapture barcodeCapture) {
//           setState(() {
//             _scannedData = barcodeCapture.barcodes.first.rawValue;
//             _deviceIdController.text = _scannedData ?? '';
//           });
//           Navigator.of(context).pop();
//         },
//       ),
//     ));
//   }

//   Future<void> _submitDeviceId(BluetoothService bluetoothService) async {
//     final deviceId = _deviceIdController.text.trim();

//     if (deviceId.isNotEmpty) {
//       setState(() {
//         _isConnecting = true;
//       });

//       try {
//         // Check if the device is in the scanned devices list
//         final isValidDevice = bluetoothService.devices.any((device) => device.id == deviceId);

//         if (!isValidDevice) {
//           throw Exception('Device not scanned or invalid Device ID');
//         }

//         // Connect to the device
//         await bluetoothService.connectToDevice(deviceId);

//         // Save the device ID using SharedPreferences
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('device_id', deviceId);

//         // Notify the user and navigate to the HomePage
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Device connected: $deviceId')),
//         );

//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (context) => HomePage(devices: [deviceId])),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       } finally {
//         setState(() {
//           _isConnecting = false;
//         });
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter a valid Device ID')),
//       );
//     }
//   }
// }

//   Future<void> connectToDevice(String deviceId) async {
//     // Logic to connect to the device using its ID
//     print("Connecting to device: $deviceId");
//   }

