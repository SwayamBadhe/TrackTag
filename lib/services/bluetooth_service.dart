import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:track_tag/utils/firestore_helper.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:track_tag/services/eddystone_parser.dart';  
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class BluetoothService extends ChangeNotifier {
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  StreamSubscription? _scanSubscription;

  final List<DiscoveredDevice> _devices = [];
  final Map<String, int> _rssiMap = {};
  final _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();
  
  int userDefinedRange = -90;
  bool _isScanning = false;
  
  // Getters
  Stream<List<DiscoveredDevice>> get deviceStream => _devicesController.stream;
  List<DiscoveredDevice> get devices => List.unmodifiable(_devices);
  bool get isScanning => _isScanning;
  StreamSubscription<BleStatus>? _bluetoothStatusSubscription;

  BluetoothService() {
    _initNotifications();
    _initializeBluetoothMonitoring();
  }

  Future<void> _initializeBluetoothMonitoring() async {
    _bluetoothStatusSubscription = flutterReactiveBle.statusStream.listen((status) {
      print('Bluetooth status changed: $status');
      if (status == BleStatus.ready && !_isScanning) {
        startScan(); // Restart scan if Bluetooth becomes ready
      } else if (status != BleStatus.ready) {
        stopScan(); // Stop scan if Bluetooth becomes unavailable
      }
    });
  }

  Future<bool> _checkAndRequestPermissions() async {
     Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }
  
  Future<void> _initNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _notificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }
  
  /// Starts scanning for BLE devices and filters Eddystone beacons.
  /// Stores unique devices and updates their RSSI values in a map.
  Future<void> startScan() async {
  if (_isScanning) return; // Avoid multiple scans

  bool hasPermission = await _checkAndRequestPermissions();
  if (!hasPermission) {
    print("Bluetooth permissions not granted.");
    return;
  }

  if (flutterReactiveBle.status != BleStatus.ready) {
    print("Bluetooth is not ready. Requesting user to enable it...");
    await _requestEnableBluetooth(); // Prompt user to enable Bluetooth
    return;
  }

  _isScanning = true;
  notifyListeners();

  _scanSubscription = flutterReactiveBle.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).listen(
  (device) {
    final existingDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
    if (existingDeviceIndex == -1) {
      _devices.add(device);
    } else {
      _devices[existingDeviceIndex] = device;
    }
    notifyListeners();
  }, 
  onError: (error) {
    print("Scan error: $error");
    _isScanning = false;
    notifyListeners();
  },
  onDone: () {
    print("Scan stopped. Restarting...");
    startScan();  // ✅ Restart scan when it stops
  }
);

}


  Future<void> _requestEnableBluetooth() async {
    const platform = MethodChannel('flutter_bluetooth');
    try {
      await platform.invokeMethod('requestEnableBluetooth');
    } on PlatformException catch (e) {
      print("Failed to enable Bluetooth: ${e.message}");
    }
  }


  void stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  /// Displays a high-priority notification when a Bluetooth device is lost.
  /// Uses Android's notification system to alert the user.
  Future<void> _showNotification(DiscoveredDevice device) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('bluetooth_alerts', 'Bluetooth Alerts',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(0, "Device Lost",
        "${device.name} is out of range", platformChannelSpecifics);
  }

  /// Firebase Auth: Sign in
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      return userCredential.user;
    } catch (e) {
      print("Error signing in: $e");
      return null;
    }
  }
  
  /// Firebase Auth: Sign out
  Future<void> signOut() async {
  await _auth.signOut();
}

  // Firebase Auth: Register new user
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error registering user: $e");
      return null;
    }
  }

  // Firebase Firestore: Add data to Firestore
  Future<void> addDevice(String deviceId, User user, BuildContext context) async {
  try {
    // Adding device to Firestore and associating it with the current user
    await FirebaseFirestore.instance.collection('devices').add({
      'deviceId': deviceId,       // The device name or ID
      'userId': user.uid,         // Associate the device with the current user
      'timestamp': FieldValue.serverTimestamp(), // To track when the device was added
      'lastSeen': FieldValue.serverTimestamp(), // Add this to track device status
      'rssi': _rssiMap[deviceId], // Add the last known RSSI value
    });

    print("Device added to Firestore");

    // After adding the device, refetch and update the devices for the current user
    fetchUserDevicesAndNavigate(context, user);

  } catch (e) {
    print("Error adding device to Firestore: $e");
  }
}

  Future<void> disconnectDevice() async {
    print("Device disconnected.");
  }

  // Firebase Auth: Check user state (initialization)
 Future<void> connectToDevice(String deviceId) async {
  try {
    print("Connecting to $deviceId...");
    final connectionStream = flutterReactiveBle.connectToDevice(id: deviceId);

    connectionStream.listen((connectionState) {
      print("Connection state: ${connectionState.connectionState}");
    }, onError: (error) {
      print("Connection error: $error");
    });
  } catch (e) {
    print("Error connecting to device: $e");
  }
}

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _bluetoothStatusSubscription?.cancel();
    super.dispose();
  }
}