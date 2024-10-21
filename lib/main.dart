// // import 'package:flutter/material.dart';
// // import 'package:track_tag/my_home_page.dart'; // Import the new file
// // import 'register_page.dart';
// // import 'login_page.dart';

// // void main() {
// //   runApp(MyApp());
// // }

// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Flutter Auth',
// //       theme: ThemeData(primarySwatch: Colors.blue),
// //       home: MyHomePage(), // Set BLE Scanner page as the initial page
// //       routes: {
// //         '/home': (context) =>  MyHomePage(),
// //         '/register': (context) => RegisterPage(),
// //         '/login': (context) => LoginPage(),
// //       },
// //     );
// //   }
// // }


// import 'package:flutter/material.dart';
// import 'package:track_tag/login_page.dart';
// import 'package:track_tag/register_page.dart';
// import 'package:track_tag/scanner/ScanDevicePage.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Device Scanner App',
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const RegisterPage(),
//         '/login': (context) => const LoginPage(),
//         '/scan': (context) => const ScanDevicePage(),
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:track_tag/login_page.dart';
import 'package:track_tag/register_page.dart';
import 'package:track_tag/scanner/ScanDevicePage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Scanner App',
      initialRoute: '/',
      routes: {
        // '/': (context) => const RegisterPage(), // Your registration page
        '/login': (context) => const LoginPage(), // Your login page
        '/': (context) => const ScanDevicePage(),
      },
    );
  }
}
