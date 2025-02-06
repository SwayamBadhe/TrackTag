import 'package:flutter/material.dart';
import 'package:track_tag/screens/MenuPage.dart';
import 'package:track_tag/screens/ScanDevicePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_tag/screens/DeviceStatusPage.dart';

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
    if (newDevice != null) {
      setState(() {
        _connectedDevices.add(newDevice);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user from Firebase Authentication
    final user = FirebaseAuth.instance.currentUser;
    String? userEmail = user?.email ?? 'No email'; // Default fallback
    String? profilePhotoUrl = user?.photoURL ?? ''; // Default fallback

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
                    userEmail: userEmail, // Pass actual user email
                    profilePhotoUrl: profilePhotoUrl, // Pass actual profile photo URL
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
                  // Connected Device Card
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeviceStatusPage(
                              deviceId: _connectedDevices[index]),
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
                          const Icon(Icons.device_hub,
                              size: 40, color: Colors.blue),
                          const SizedBox(height: 8),
                          Text(
                            _connectedDevices[index],
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
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
