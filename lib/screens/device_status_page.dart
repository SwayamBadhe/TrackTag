// lib/pages/device_status_page.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:track_tag/services/bluetooth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_tag/services/notification_service.dart';
import 'package:track_tag/services/device_tracking_service.dart';

class DeviceStatusPage extends StatefulWidget {
  final String deviceId;

  const DeviceStatusPage({
    super.key,
    required this.deviceId,
  });

  @override
  DeviceStatusPageState createState() => DeviceStatusPageState();
}

class DeviceStatusPageState extends State<DeviceStatusPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late NotificationService notificationService;
  XFile? _profileImage;
  bool isTracking = false;
  double _tempRange = 15.0;

  @override
  void initState() {
    super.initState();
    notificationService = NotificationService();
    _loadTrackingState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTrackingState() async {
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    final trackingService = Provider.of<DeviceTrackingService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await trackingService.loadTrackingPreferences(userId);
    }
    setState(() {
      isTracking = bluetoothService.getDeviceTrackingInfo(widget.deviceId).isTracking;
      _tempRange = trackingService.userDefinedRange;
    });
  }

  Future<void> _toggleTracking() async {
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    final trackingService = Provider.of<DeviceTrackingService>(context, listen: false);

    try {
      await trackingService.toggleTracking(widget.deviceId, bluetoothService);
      if (mounted) {
        setState(() {
          isTracking = trackingService.isDeviceTracking(widget.deviceId);
        });
      }
    } catch (e) {
      debugPrint("Error toggling tracking: $e");
    }
  }

  Future<void> _updateRange(double value) async {
    final trackingService = Provider.of<DeviceTrackingService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      _tempRange = value;
    });
    trackingService.userDefinedRange = value;
    if (userId != null) {
      await trackingService.saveTrackingPreferences(userId);
    }
    trackingService.notifyListeners();
  }

  Future<void> _toggleLostMode(bool value) async {
    final trackingService = Provider.of<DeviceTrackingService>(context, listen: false);
    await trackingService.toggleLostMode(widget.deviceId, value);
    setState(() {}); // Refresh UI
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        setState(() => _profileImage = pickedFile);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<BluetoothService>(context);
    final trackingService = Provider.of<DeviceTrackingService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Device Status')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _showImagePickerDialog(),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImage != null 
                      ? FileImage(File(_profileImage!.path)) 
                      : null,
                  child: _profileImage == null 
                      ? const Icon(Icons.camera_alt, size: 40) 
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Description:', style: TextStyle(fontSize: 16)),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write a description...'
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Tracking'),
              subtitle: Text(isTracking 
                  ? 'Monitoring device status' 
                  : 'Tracking disabled'),
              value: isTracking,
              onChanged: (value) => _toggleTracking(),
            ),
            if (isTracking) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Lost Mode'),
                subtitle: Text(trackingService.isDeviceInLostMode(widget.deviceId)
                    ? 'Finding device with navigation'
                    : 'Default find mode'),
                value: trackingService.isDeviceInLostMode(widget.deviceId),
                onChanged: (value) => _toggleLostMode(value),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      StreamBuilder<List<DiscoveredDevice>>(
                        stream: bluetoothService.deviceStream,
                        builder: (context, snapshot) {
                          final connectionState = trackingService.getConnectionState(widget.deviceId);
                          final distance = trackingService.getEstimatedDistance(widget.deviceId);
                          final rssi = trackingService.getSmoothedRssi(widget.deviceId);
                          final lastSeen = trackingService.lastSeenMap[widget.deviceId];
                          final direction = trackingService.getLostModeDirection(widget.deviceId);

                          return Column(
                            children: [
                              _buildConnectionStatus(connectionState),
                              const SizedBox(height: 16),
                              _buildStatusRow('Distance', 
                                distance >= 0 ? '${distance.toStringAsFixed(2)} m' : 'Unknown',
                                _getDistanceColor(distance)),
                              const SizedBox(height: 8),
                              _buildStatusRow('Signal Strength', 
                                '$rssi dBm',
                                _getRssiColor(rssi)),
                              const SizedBox(height: 16),
                              _buildLastSeen(lastSeen),
                              if (trackingService.isDeviceInLostMode(widget.deviceId)) ...[
                                const SizedBox(height: 16),
                                _buildStatusRow('Direction', direction, Colors.blue),
                                const SizedBox(height: 16),                                
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('Lost Distance Threshold: ${_tempRange.toStringAsFixed(1)} m'),
                      Slider(
                        value: _tempRange,
                        min: 5.0,
                        max: 30.0,
                        divisions: 25,
                        label: '${_tempRange.toStringAsFixed(1)} m',
                        onChanged: (value) {
                          setState(() {
                            _tempRange = value;
                          });
                        },
                        onChangeEnd: (value) => _updateRange(value),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(TrackedDeviceState state) {
    IconData icon;
    String text;
    Color color;

    switch (state) {
      case TrackedDeviceState.connected:
        icon = Icons.bluetooth_connected;
        text = "Connected";
        color = Colors.green;
        break;
      case TrackedDeviceState.disconnected:
        icon = Icons.bluetooth_disabled;
        text = "Disconnected";
        color = Colors.red;
        break;
      case TrackedDeviceState.lost:
        icon = Icons.warning;
        text = "Lost";
        color = Colors.orange;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLastSeen(DateTime? lastSeen) {
    return Text(
      'Last Seen: ${lastSeen != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(lastSeen) : 'Unknown'}',
      style: const TextStyle(color: Colors.grey),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Color _getDistanceColor(double distance) {
    if (distance < 0) return Colors.grey;
    if (distance <= 3) return Colors.green;
    if (distance <= 5) return Colors.orange;
    return Colors.red;
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
  }
}