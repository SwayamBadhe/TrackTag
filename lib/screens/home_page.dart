import 'package:flutter/material.dart';
import 'package:track_tag/screens/menu_page.dart';
import 'package:track_tag/screens/scan_device_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_tag/screens/device_status_page.dart';
import 'package:provider/provider.dart';
import 'package:track_tag/services/device_tracking_service.dart';

class HomePage extends StatefulWidget {
  final List<String> devices; 

  const HomePage({super.key, required this.devices});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<String> _connectedDevices;

  @override
  void initState() {
    super.initState();
    _connectedDevices = widget.devices;
  }

  void _navigateToScanPage() async {
    final newDevice = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const ScanDevicePage()),
    );
    if (newDevice != null && !_connectedDevices.contains(newDevice)) {
      setState(() {
        _connectedDevices.add(newDevice);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingService = Provider.of<DeviceTrackingService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    String? userEmail = user?.email ?? 'No email';
    String? profilePhotoUrl = user?.photoURL ?? '';

    debugPrint("HomePage devices: $_connectedDevices");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MenuPage(
                    userEmail: userEmail,
                    profilePhotoUrl: profilePhotoUrl,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _connectedDevices.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == _connectedDevices.length) {
                  return GestureDetector(
                    onTap: _navigateToScanPage,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 40, color: Colors.teal),
                          SizedBox(height: 8),
                          Text(
                            'Add Device',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  final deviceId = _connectedDevices[index];
                  return FutureBuilder<String>(
                    future: trackingService.getDeviceNameFromDevices(deviceId),
                    builder: (context, snapshot) {
                      final deviceName = snapshot.data ?? deviceId;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceStatusPage(deviceId: deviceId),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.device_hub, size: 40, color: Colors.blue),
                              const SizedBox(height: 8),
                              Text(
                                deviceName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}