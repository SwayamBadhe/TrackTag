// import 'package:flutter/material.dart';
// import 'package:track_tag/login_page.dart';
// import 'package:track_tag/register_page.dart';
// import 'package:track_tag/scanner/ScanDevicePage.dart';
// import 'package:track_tag/screens/card_page_screen.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Device Scanner App',
//       initialRoute: '/cardPageScreen',
//       routes: {
//         // '/': (context) => const RegisterPage(), // Your registration page
//         '/login': (context) => const LoginPage(), // Your login page
//         // '/': (context) => const ScanDevicePage(),
//         '/cardPageScreen': (context) => HomePage(),
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:track_tag/screens/DeviceStatusPage.dart';
import 'package:track_tag/screens/homepage.dart';
import 'services/bluetooth_service.dart';
import 'package:provider/provider.dart';

void main() {
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
        home: const HomePage(devices: []),
        // home: const DeviceStatusPage(),
      ),
    );
  }
}
