import 'package:flutter/material.dart';
import 'package:track_tag/screens/DeviceStatusPage.dart';
import 'package:track_tag/screens/auth/login_page.dart';
import 'services/bluetooth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_tag/screens/homepage.dart';
import 'package:track_tag/screens/MenuPage.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BluetoothService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TrackTag App',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasData) {
              final user = snapshot.data!;
              // Fetch devices after login
              _fetchUserDevicesAndNavigate(context, user);
              return const CircularProgressIndicator();  // Or any loading widget until the devices are fetched
            } else {
              return LoginPage();
            }
          },
        ),
        routes: {
          '/login': (context) => LoginPage(),
          '/homepage': (context) => const HomePage(devices: []), 
          '/menu': (context) => MenuPage(userEmail: 'user@example.com', profilePhotoUrl: 'https://example.com/profile.jpg'),
          '/deviceStatus': (context) => DeviceStatusPage(deviceId: ''),
        },
      ),
    );
  }
}

Future<void> _fetchUserDevicesAndNavigate(BuildContext context, User user) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('devices')
        .where('userId', isEqualTo: user.uid)
        .get();

    List<String> devices = snapshot.docs
        .map((doc) => doc['deviceId'] as String)
        .toList();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(devices: devices)),
    );
  } catch (e) {
    print("Error fetching user devices: $e");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(devices: [])), // Fallback
    );
  }
}
