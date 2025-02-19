// lib/utils/firestore_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:track_tag/screens/home_page.dart';

Future<void> fetchUserDevicesAndNavigate(BuildContext context, User user) async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('devices')
      .where('userId', isEqualTo: user.uid)
      .get();

    List<String> userDevices = snapshot.docs.map((doc) => doc['deviceId'] as String).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(devices: userDevices),
      ),
    );
  } catch (e) {
    debugPrint("Error fetching user devices: $e");
  }
}
