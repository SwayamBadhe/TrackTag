// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_tag/utils/firestore_helper.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth;
  
  AuthService(this._auth);

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Error signing in: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Error registering user: $e");
      return null;
    }
  }

  Future<void> addDevice(String deviceId, User user, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('devices').add({
        'deviceId': deviceId,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });

      debugPrint("Device added to Firestore");
      fetchUserDevicesAndNavigate(context, user);

    } catch (e) {
      debugPrint("Error adding device to Firestore: $e");
    }
  }
}