// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart'; // Add this package for QR scanning

// class ScanDevicePage extends StatefulWidget {
//   const ScanDevicePage({super.key});

//   @override
//   _ScanDevicePageState createState() => _ScanDevicePageState();
// }

// class _ScanDevicePageState extends State<ScanDevicePage> {
//   final TextEditingController _deviceIdController = TextEditingController();
//   String? _scannedData;

//   // Function to handle QR code scan result
//   void _onScan(String data) {
//     setState(() {
//       _scannedData = data; // Store scanned data
//     });
//     // Here you can proceed to handle the scanned device ID
//     // e.g., navigate to another page or display a message
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Scan Device')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: <Widget>[
//             // Display scanned data
//             if (_scannedData != null)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 child: Text('Scanned Device ID: $_scannedData'),
//               ),
//             // Text field for manual device ID entry
//             TextFormField(
//               controller: _deviceIdController,
//               decoration: const InputDecoration(labelText: 'Enter Device ID'),
//             ),
//             const SizedBox(height: 16),
//             // Button to initiate the QR code scanner
//             ElevatedButton(
//               onPressed: () async {
//                 // Use a QR code scanner package to scan the device
//                 // For example: QRView
//                 // You'll need to implement QR scanning functionality here
//               },
//               child: const Text('Scan QR Code'),
//             ),
//             const SizedBox(height: 16),
//             // Button to submit the device ID
//             ElevatedButton(
//               onPressed: () {
//                 String deviceId = _deviceIdController.text;
//                 if (deviceId.isNotEmpty) {
//                   // Handle the device ID submission logic here
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Device ID submitted: $deviceId')),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Please enter a Device ID')),
//                   );
//                 }
//               },
//               child: const Text('Submit Device ID'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanDevicePage extends StatefulWidget {
  const ScanDevicePage({Key? key}) : super(key: key);

  @override
  _ScanDevicePageState createState() => _ScanDevicePageState();
}

class _ScanDevicePageState extends State<ScanDevicePage> {
  final TextEditingController _deviceIdController = TextEditingController();
  String? _scannedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Device')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Display scanned data
            if (_scannedData != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Scanned Device ID: $_scannedData'),
              ),
            // Text field for manual device ID entry
            TextFormField(
              controller: _deviceIdController,
              decoration: const InputDecoration(labelText: 'Enter Device ID'),
            ),
            const SizedBox(height: 16),
            // Button to initiate the QR code scanner
            ElevatedButton(
              onPressed: _showScanner,
              child: const Text('Scan QR Code'),
            ),
            const SizedBox(height: 16),
            // Button to submit the device ID
            ElevatedButton(
              onPressed: () {
                String deviceId = _deviceIdController.text;
                if (deviceId.isNotEmpty) {
                  // Handle the device ID submission logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Device ID submitted: $deviceId')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a Device ID')),
                  );
                }
              },
              child: const Text('Submit Device ID'),
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
            _scannedData = barcodeCapture.barcodes.first.rawValue; // Store the scanned data
          });
          Navigator.of(context).pop(); // Close scanner after detection
        },
      ),
    ));
  }
}
