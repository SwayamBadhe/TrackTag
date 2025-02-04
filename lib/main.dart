import 'package:flutter/material.dart';
import 'package:track_tag/screens/auth_screen.dart';
import 'package:track_tag/screens/homepage.dart';
import 'services/bluetooth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

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
        home: const AuthScreen(),
        // home: const DeviceStatusPage(),
      ),
    );
  }
}
