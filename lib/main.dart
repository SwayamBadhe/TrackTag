import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:track_tag/screens/device_status_page.dart';
import 'package:track_tag/screens/auth/login_page.dart';
import 'package:track_tag/utils/firestore_helper.dart';
import 'package:track_tag/services/bluetooth_service.dart';
import 'package:track_tag/services/device_tracking_service.dart';
import 'package:track_tag/services/background_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_tag/screens/home_page.dart';
import 'package:track_tag/screens/menu_page.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:track_tag/firebase_options.dart';
import 'package:track_tag/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final notificationService = NotificationService();
  final deviceTrackingService = DeviceTrackingService(notificationService, navigatorKey);
  final bluetoothService = BluetoothService(navigatorKey);

  // Initialize but don’t start yet
  await initializeBackgroundService(notificationService, bluetoothService, deviceTrackingService, navigatorKey);

  runApp(MyAppState(navigatorKey: navigatorKey));
}

// Call this after user interaction (e.g., button press or permission grant)
void startBackgroundService() {
  FlutterBackgroundService().startService();
}

class MyAppState extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyAppState({super.key, required this.navigatorKey});

  @override
  State<MyAppState> createState() => _MyAppState();
}

class _MyAppState extends State<MyAppState> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopBackgroundService();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      stopBackgroundService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyApp(navigatorKey: widget.navigatorKey);
  }
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothService(navigatorKey)),
        Provider(create: (_) => NotificationService()),
        ChangeNotifierProvider(
          create: (context) => DeviceTrackingService(
            Provider.of<NotificationService>(context, listen: false),
            navigatorKey,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TrackTag App',
        theme: ThemeData(primarySwatch: Colors.teal),
        navigatorKey: navigatorKey,
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              final user = snapshot.data!;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                fetchUserDevicesAndNavigate(context, user);
              });
              return const Center(child: CircularProgressIndicator());
            } else {
              return const LoginPage();
            }
          },
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/homepage': (context) => const HomePage(devices: [],),
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