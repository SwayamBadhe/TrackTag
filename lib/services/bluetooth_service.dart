// lib/services/bluetooth_service.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_tag/services/notification_service.dart';
import 'package:track_tag/services/bluetooth_scanner.dart';
import 'package:track_tag/services/device_tracking_service.dart';
import 'package:track_tag/services/auth_service.dart';
import 'package:track_tag/models/device_tracking_info.dart';

class BluetoothService extends ChangeNotifier {
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  late final NotificationService _notificationService;
  late final BluetoothScanner _bluetoothScanner;
  late final DeviceTrackingService _deviceTrackingService;
  late final AuthService _authService;
  
  StreamSubscription<BleStatus>? _bluetoothStatusSubscription;
  bool get isScanning => _bluetoothScanner.isScanning;
  Stream<List<DiscoveredDevice>> get deviceStream => _bluetoothScanner.deviceStream;
  List<DiscoveredDevice> get devices => _bluetoothScanner.devices;

  BluetoothService() {
    _notificationService = NotificationService();
    _bluetoothScanner = BluetoothScanner(flutterReactiveBle, _notificationService);
    _deviceTrackingService = DeviceTrackingService(_notificationService);
    _authService = AuthService(_auth);
    _initializeBluetoothMonitoring();
  }


  DeviceTrackingInfo getDeviceTrackingInfo(String deviceId) {
    return _deviceTrackingService.getDeviceTrackingInfo(deviceId);
  }

  Future<void> toggleTracking(String deviceId) async {
    await _deviceTrackingService.toggleTracking(deviceId);
    if (_deviceTrackingService.isDeviceTracking(deviceId)) {
      await startScan();
    }
    notifyListeners();
  }

  Future<void> startScan() => _bluetoothScanner.startScan(_deviceTrackingService);
  void stopScan() => _bluetoothScanner.stopScan();

  Future<User?> signInWithEmail(String email, String password) => 
      _authService.signInWithEmail(email, password);

  Future<void> signOut() => _authService.signOut();

  Future<User?> registerWithEmail(String email, String password) =>
      _authService.registerWithEmail(email, password);

  Future<void> addDevice(String deviceId, User user, BuildContext context) =>
      _authService.addDevice(deviceId, user, context);

  Future<void> connectToDevice(String deviceId) =>
      _bluetoothScanner.connectToDevice(deviceId);

  void trackLostDevice(String deviceId) =>
      _deviceTrackingService.trackLostDevice(deviceId);

  Future<void> disconnectDevice() async {
    print("Device disconnected.");
  }

   double getEstimatedDistance(String deviceId) =>
      _deviceTrackingService.getEstimatedDistance(deviceId);

  int getSmoothedRssi(String deviceId) =>
      _deviceTrackingService.getSmoothedRssi(deviceId);

  void startActiveSearch(String deviceId) =>
      _deviceTrackingService.startActiveSearch(deviceId);
  
  Future<void> _initializeBluetoothMonitoring() async {
    _bluetoothStatusSubscription = flutterReactiveBle.statusStream.listen((status) {
      print('Bluetooth status changed: $status');
      if (status == BleStatus.ready && !isScanning) {
        startScan();
      } else if (status != BleStatus.ready) {
        stopScan();
      }
    });
  }

  @override
  void dispose() {
    _deviceTrackingService.dispose();
    _bluetoothScanner.dispose();
    _bluetoothStatusSubscription?.cancel();
    super.dispose();
  }
}


// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:track_tag/utils/firestore_helper.dart';
// import 'package:vibration/vibration.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:track_tag/services/eddystone_parser.dart';  
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:async';
// import 'dart:math';

// class KalmanFilter {
//   double _estimate = 0;
//   double _errorEstimate = 1;
//   final double _q = 0.1; // Process noise
//   final double _r = 1; // Measurement noise

//   double update(double measurement) {
//     // Prediction
//     double errorEstimate = _errorEstimate + _q;
    
//     // Update
//     double kalmanGain = errorEstimate / (errorEstimate + _r);
//     _estimate += kalmanGain * (measurement - _estimate);
//     _errorEstimate = (1 - kalmanGain) * errorEstimate;
    
//     return _estimate;
//   }
// }

// class DeviceTrackingInfo {
//   bool isTracking;
//   bool isLost;
//   KalmanFilter rssiFilter;
//   DateTime? lastSeen;
//   String movementStatus;
//   double lastDistance;
//   Timer? activeTrackingTimer;

//   DeviceTrackingInfo()
//       : isTracking = false,
//         isLost = false,
//         rssiFilter = KalmanFilter(),
//         movementStatus = 'Stationary',
//         lastDistance = -1;
// }

// class BluetoothService extends ChangeNotifier {
//   final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
//   final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore db = FirebaseFirestore.instance;
  
//   StreamSubscription? _scanSubscription;

//   final List<DiscoveredDevice> _devices = [];
//   final Map<String, int> _rssiMap = {};
//   final _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();
  
//   int userDefinedRange = -90;
//   bool _isScanning = false;
  
//   // Getters
//   Stream<List<DiscoveredDevice>> get deviceStream => _devicesController.stream;
//   List<DiscoveredDevice> get devices => List.unmodifiable(_devices);
//   bool get isScanning => _isScanning;
//   StreamSubscription<BleStatus>? _bluetoothStatusSubscription;

//   final Map<String, DeviceTrackingInfo> _deviceTracking = {};
//   final Map<String, Timer> _activeSearchTimers = {};
  
//   // Constants for tracking
//   static const double LOST_THRESHOLD_METERS = 10.0;
//   static const int ACTIVE_SEARCH_INTERVAL = 500; // milliseconds
//   static const int NORMAL_SCAN_INTERVAL = 2000; // milliseconds

//   BluetoothService() {
//     _initNotifications();
//     _initializeBluetoothMonitoring();
//   }

//   DeviceTrackingInfo getDeviceTrackingInfo(String deviceId) {
//     return _deviceTracking.putIfAbsent(deviceId, () => DeviceTrackingInfo());
//   }

//   // Toggle tracking for a specific device
//   Future<void> toggleTracking(String deviceId) async {
//     var trackingInfo = getDeviceTrackingInfo(deviceId);
//     trackingInfo.isTracking = !trackingInfo.isTracking;

//     if (trackingInfo.isTracking) {
//       await startScan(); // Start scanning if not already scanning
//     } else {
//       _stopActiveSearch(deviceId);
//     }
//     notifyListeners();
//   }

  

//   // Start active search for a device
//   void startActiveSearch(String deviceId) {
//     var trackingInfo = getDeviceTrackingInfo(deviceId);
//     trackingInfo.activeTrackingTimer?.cancel();
    
//     // Increase scan frequency
//     trackingInfo.activeTrackingTimer = Timer.periodic(
//       const Duration(milliseconds: ACTIVE_SEARCH_INTERVAL),
//       (_) => _updateDeviceStatus(deviceId)
//     );
    
//     notifyListeners();
//   }

//   void _stopActiveSearch(String deviceId) {
//     _activeSearchTimers[deviceId]?.cancel();
//     _activeSearchTimers.remove(deviceId);
//   }

//   DiscoveredDevice? getDeviceById(String deviceId) {
//     final index = _devices.indexWhere((device) => device.id == deviceId);
//     return index >= 0 ? _devices[index] : null;
//   }

//   // Update device tracking status
//   void _updateDeviceStatus(String deviceId) {
//     var trackingInfo = getDeviceTrackingInfo(deviceId);
//     var currentDistance = getEstimatedDistance(deviceId);
    
//     if (currentDistance > 0) {
//       // Update movement status
//       if (trackingInfo.lastDistance > 0) {
//         double difference = currentDistance - trackingInfo.lastDistance;
//         if (difference.abs() > 0.5) { // Threshold for movement detection
//           trackingInfo.movementStatus = difference < 0 ? 'Getting Closer' : 'Moving Away';
//         } else {
//           trackingInfo.movementStatus = 'Stationary';
//         }
//       }
      
//       // Update lost status
//       trackingInfo.isLost = currentDistance > LOST_THRESHOLD_METERS;
//       trackingInfo.lastDistance = currentDistance;
//       trackingInfo.lastSeen = DateTime.now();
      
//       if (trackingInfo.isLost && trackingInfo.isTracking) {
//         final device = getDeviceById(deviceId);
//         if (device != null) {
//           _showNotification(device);
//         }
//         Vibration.vibrate();
//       }
//     }
    
//     notifyListeners();
//   }

//   Future<void> _initializeBluetoothMonitoring() async {
//     _bluetoothStatusSubscription = flutterReactiveBle.statusStream.listen((status) {
//       print('Bluetooth status changed: $status');
//       if (status == BleStatus.ready && !_isScanning) {
//         startScan(); // Restart scan if Bluetooth becomes ready
//       } else if (status != BleStatus.ready) {
//         stopScan(); // Stop scan if Bluetooth becomes unavailable
//       }
//     });
//   }

//   Future<bool> _checkAndRequestPermissions() async {
//      Map<Permission, PermissionStatus> statuses = await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.location
//     ].request();

//     return statuses.values.every((status) => status.isGranted);
//   }
  
//   Future<void> _initNotifications() async {
//     try {
//       const AndroidInitializationSettings initializationSettingsAndroid =
//           AndroidInitializationSettings('@mipmap/ic_launcher');
//       const InitializationSettings initializationSettings =
//           InitializationSettings(android: initializationSettingsAndroid);
//       await _notificationsPlugin.initialize(initializationSettings);
//     } catch (e) {
//       print('Error initializing notifications: $e');
//     }
//   }

//   // Store recent RSSI readings for smoothing
// final Map<String, List<int>> _rssiHistory = {};
// final Map<String, double> _distanceMap = {};

// // Moving average filter to smooth out RSSI fluctuations
// double _calculateDistance(int? txPower, double rssi) {
//   if (txPower == null) txPower = -59; 
//   if (rssi == 0) return -1.0; 

//   const double pathLossExponent = 2.7; 

//   double distance = pow(10, (txPower - rssi) / (10 * pathLossExponent)).toDouble();

//   return distance; 
// }


// int? _extractTxPower(List<int> manufacturerData) {
//   if (manufacturerData.isEmpty) return null;

//   // Many BLE devices store TxPower in the last byte
//   return manufacturerData.last; 
// }

// double _applyMovingAverage(String deviceId, double newRssi) {
//   const int windowSize = 5;
//   _rssiHistory.putIfAbsent(deviceId, () => []);
//   List<int> history = _rssiHistory[deviceId]!;

//   if (history.length >= windowSize) {
//     history.removeAt(0);
//   }
//   history.add(newRssi.toInt());

//   return history.reduce((a, b) => a + b) / history.length; // Smoothed RSSI
// }

// double getEstimatedDistance(String deviceId) {
//   return _distanceMap[deviceId] ?? -1.0; // Return stored distance or default -1.0 if not found
// }

// int getSmoothedRssi(String deviceId) {
//   return _rssiMap[deviceId] ?? -100; // Return stored RSSI or default -100 if not found
// }

  
//   /// Starts scanning for BLE devices and filters Eddystone beacons.
//   /// Stores unique devices and updates their RSSI values in a map.
//   Future<void> startScan() async {
//   if (_isScanning) return;

//   bool hasPermission = await _checkAndRequestPermissions();
//   if (!hasPermission) {
//     print("Bluetooth permissions not granted.");
//     return;
//   }

//   if (flutterReactiveBle.status != BleStatus.ready) {
//     print("Bluetooth is not ready. Requesting user to enable it...");
//     await _requestEnableBluetooth();
//     return;
//   }

//   _isScanning = true;
//   notifyListeners();

//   _scanSubscription = flutterReactiveBle.scanForDevices(
//     withServices: [],
//     scanMode: ScanMode.lowLatency,
//     requireLocationServicesEnabled: true,
//   ).listen(
//     (device) {
//       try {
//         final String deviceId = device.id;
//         final String localName = device.name.isNotEmpty ? device.name : "Unknown";
//         final List<String> serviceUuids = device.serviceUuids.map((uuid) => uuid.toString()).toList();
//         final List<int> manufacturerData = device.manufacturerData;
//         final int rssi = device.rssi;

//         // Apply Kalman filter to RSSI
//         var trackingInfo = getDeviceTrackingInfo(deviceId);
//         double filteredRssi = trackingInfo.rssiFilter.update(rssi.toDouble());

//         // Extract TxPower from Manufacturer Data (if available)
//         int? txPower = _extractTxPower(manufacturerData);

//         // Calculate distance with filtered RSSI
//         double estimatedDistance = _calculateDistance(txPower, filteredRssi);

//         // Store RSSI & distance values
//         _rssiMap[deviceId] = filteredRssi.toInt();
//         _distanceMap[deviceId] = estimatedDistance;

//         print('\n🔹 Device Found:');
//         print('ID: $deviceId');
//         print('Name: $localName');
//         print('RSSI: $rssi dBm (Filtered: ${filteredRssi.toStringAsFixed(1)})');
//         print('Estimated Distance: ${estimatedDistance.toStringAsFixed(2)} meters');

//         if (serviceUuids.isNotEmpty) {
//           print('   🔧 Service UUIDs:');
//           for (var uuid in serviceUuids) {
//             print('      - $uuid');
//           }
//         }

//         if (manufacturerData.isNotEmpty) {
//           print('Manufacturer Data:');
//           print('- Raw: ${manufacturerData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

//           try {
//             final eddystoneData = EddystoneParser.parseManufacturerData(manufacturerData);
//             if (eddystoneData != null) {
//               print('- Eddystone Format Detected:');
//               print('Frame Type: ${eddystoneData['frameType']}');
//             }
//           } catch (e) {
//             print('- Not Eddystone format');
//           }
//         }

//         // Update device tracking status
//         if (trackingInfo.isTracking) {
//           _updateDeviceStatus(deviceId);
//         }

//         final existingDeviceIndex = _devices.indexWhere((d) => d.id == deviceId);
//         if (existingDeviceIndex == -1) {
//           _devices.add(device);
//         } else {
//           _devices[existingDeviceIndex] = device;
//         }

//         _devicesController.add(_devices);
//         notifyListeners();

//         if (estimatedDistance < userDefinedRange) {
//           _showNotification(device);
//           Vibration.vibrate();
//         }

//       } catch (e) {
//         print('Error processing device data: $e');
//       }
//     },
//     onError: (error) {
//       print("❌ Scan error: $error");
//       _isScanning = false;
//       notifyListeners();
//     },
//     onDone: () {
//       print("📡 Scan stopped. Restarting...");
//       startScan();
//     },
//   );
// }

//   Future<void> _requestEnableBluetooth() async {
//     const platform = MethodChannel('flutter_bluetooth');
//     try {
//       await platform.invokeMethod('requestEnableBluetooth');
//     } on PlatformException catch (e) {
//       print("Failed to enable Bluetooth: ${e.message}");
//     }
//   }


//   void stopScan() {
//     _scanSubscription?.cancel();
//     _scanSubscription = null;
//     _isScanning = false;
//     notifyListeners();
//   }

//   /// Displays a high-priority notification when a Bluetooth device is lost.
//   /// Uses Android's notification system to alert the user.
//   Future<void> _showNotification(DiscoveredDevice device) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails('bluetooth_alerts', 'Bluetooth Alerts',
//             importance: Importance.max,
//             priority: Priority.high,
//             showWhen: false);
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
//     await _notificationsPlugin.show(0, "Device Lost",
//         "${device.name} is out of range", platformChannelSpecifics);
//   }

//   /// Firebase Auth: Sign in
//   Future<User?> signInWithEmail(String email, String password) async {
//     try {
//       final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password
//       );
//       return userCredential.user;
//     } catch (e) {
//       print("Error signing in: $e");
//       return null;
//     }
//   }
  
//   /// Firebase Auth: Sign out
//   Future<void> signOut() async {
//   await _auth.signOut();
// }

//   // Firebase Auth: Register new user
//   Future<User?> registerWithEmail(String email, String password) async {
//     try {
//       final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return userCredential.user;
//     } catch (e) {
//       print("Error registering user: $e");
//       return null;
//     }
//   }

//   // Firebase Firestore: Add data to Firestore
//   Future<void> addDevice(String deviceId, User user, BuildContext context) async {
//   try {
//     // Adding device to Firestore and associating it with the current user
//     await FirebaseFirestore.instance.collection('devices').add({
//       'deviceId': deviceId,       // The device name or ID
//       'userId': user.uid,         // Associate the device with the current user
//       'timestamp': FieldValue.serverTimestamp(), // To track when the device was added
//       'lastSeen': FieldValue.serverTimestamp(), // Add this to track device status
//       'rssi': _rssiMap[deviceId], // Add the last known RSSI value
//     });

//     print("Device added to Firestore");

//     // After adding the device, refetch and update the devices for the current user
//     fetchUserDevicesAndNavigate(context, user);

//   } catch (e) {
//     print("Error adding device to Firestore: $e");
//   }
// }

//   Future<void> disconnectDevice() async {
//     print("Device disconnected.");
//   }

//   // Firebase Auth: Check user state (initialization)
//  Future<void> connectToDevice(String deviceId) async {
//   try {
//     print("Connecting to $deviceId...");
//     final connectionStream = flutterReactiveBle.connectToDevice(id: deviceId);

//     connectionStream.listen((connectionState) {
//       print("Connection state: ${connectionState.connectionState}");
//     }, onError: (error) {
//       print("Connection error: $error");
//     });
//   } catch (e) {
//     print("Error connecting to device: $e");
//   }
// }

// void trackLostDevice(String deviceId) {
//   if (!_rssiMap.containsKey(deviceId)) {
//     print("Device $deviceId not found in scan data.");
//     return;
//   }

//   int rssi = _rssiMap[deviceId] ?? -100;
//   double distance = _distanceMap[deviceId] ?? -1.0;

//   print("Tracking lost device $deviceId...");
//   print("Last known RSSI: $rssi dBm, Estimated Distance: ${distance.toStringAsFixed(2)} meters");

//   if (rssi < userDefinedRange || distance < 0) {
//     _showNotification(DiscoveredDevice(
//       id: deviceId,
//       name: "Lost Device",
//       manufacturerData: Uint8List(0),
//       rssi: rssi,
//       serviceUuids: [],
//       serviceData: {}, // Add this line
//     ));
//     Vibration.vibrate();
//     print("Device $deviceId is lost!");
//   }
// }


//   @override
//   void dispose() {
//     for (var timer in _activeSearchTimers.values) {
//       timer.cancel();
//     }
//     _activeSearchTimers.clear();
//     _scanSubscription?.cancel();
//     _bluetoothStatusSubscription?.cancel();
//     super.dispose();
//   }
// }