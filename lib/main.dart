import 'package:flutter/material.dart';
import 'package:track_tag/screens/device_status_page.dart';
import 'package:track_tag/screens/auth/login_page.dart';
import 'package:track_tag/utils/firestore_helper.dart';
import 'services/bluetooth_service.dart';
import 'services/device_tracking_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_tag/screens/home_page.dart';
import 'package:track_tag/screens/menu_page.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothService()),
        Provider(create: (_) => NotificationService()), 
        ChangeNotifierProvider(
          create: (context) => DeviceTrackingService(
            Provider.of<NotificationService>(context, listen: false), 
          ),
        ),
      ],
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
              fetchUserDevicesAndNavigate(context, user);
              return const CircularProgressIndicator();
            } else {
              return const LoginPage();
            }
          },
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/homepage': (context) => const HomePage(devices: []),
          '/menu': (context) => const MenuPage(
                userEmail: 'user@example.com',
                profilePhotoUrl: 'https://example.com/profile.jpg',
              ),
          '/deviceStatus': (context) => const DeviceStatusPage(deviceId: ''),
        },
      ),
    );
  }
}
