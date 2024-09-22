// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as BluePlus;
// import '../services/custom_bluetooth_service.dart';
// import '../models/bluetooth_device_model.dart';
// import 'device_screen.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   CustomBluetoothService _bluetoothService = CustomBluetoothService();
//   List<BluetoothDeviceModel> _devices = [];

//   @override
//   void initState() {
//     super.initState();
//     _startScan();
//   }

//   void _startScan() async {
//     var scannedDevices = await _bluetoothService.scanForDevices();
//     setState(() {
//       _devices = scannedDevices;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Flutter Blue Plus')),
//       body: _devices.isEmpty
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               itemCount: _devices.length,
//               itemBuilder: (context, index) {
//                 var device = _devices[index];
//                 return ListTile(
//                   title: Text(device.name),  // Assuming device.name is non-nullable
//                   subtitle: Text(device.id),
//                   onTap: () {
//                     Navigator.of(context).push(
//                       MaterialPageRoute(
//                         builder: (context) => DeviceScreen(device: device),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as BluePlus;
import '../services/custom_bluetooth_service.dart';
import '../models/bluetooth_device_model.dart';
import 'device_screen.dart';
import 'login_page.dart'; // Import your login screen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CustomBluetoothService _bluetoothService = CustomBluetoothService();
  List<BluetoothDeviceModel> _devices = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    var scannedDevices = await _bluetoothService.scanForDevices();
    setState(() {
      _devices = scannedDevices;
    });
  }

  void _onButtonPressed() {
    // Navigate to the login screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoginPage(), // Replace with your actual LoginScreen widget
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Blue Plus'),
        actions: [
          IconButton(
            icon: Icon(Icons.add), // Change this to your preferred icon
            onPressed: _onButtonPressed, // Action when the button is pressed
          ),
        ],
      ),
      body: _devices.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                var device = _devices[index];
                return ListTile(
                  title: Text(device.name),  // Assuming device.name is non-nullable
                  subtitle: Text(device.id),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DeviceScreen(device: device),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
