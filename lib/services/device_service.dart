import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> registerDevice(String deviceId, String deviceName) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not signed in');
    }

    final deviceRef = _firestore.collection('devices').doc(deviceId);
    final docSnapshot = await deviceRef.get();

    if (docSnapshot.exists) {
      throw Exception('Device is already registered to another user');
    }

    await deviceRef.set({
      'deviceId': deviceId,
      'deviceName': deviceName,
      'userId': user.uid,
      'registeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isDeviceRegistered(String deviceId) async {
    DocumentSnapshot doc = await _firestore.collection('devices').doc(deviceId).get();
    return doc.exists;
  }

  Future<List<Map<String, dynamic>>> getRegisteredDevices() async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not signed in');
    }

    QuerySnapshot querySnapshot = await _firestore.collection('devices').where('userId', isEqualTo: user.uid).get();

    return querySnapshot.docs.map((doc) => {
      'deviceId': doc.id,
      'deviceName': doc['deviceName'] ?? 'Unknown',
    }).toList();
  }
}
