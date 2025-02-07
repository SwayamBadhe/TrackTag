import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:track_tag/services/bluetooth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceStatusPage extends StatefulWidget {
  final String deviceId;
  const DeviceStatusPage({super.key, required this.deviceId});

  @override
  DeviceStatusPageState createState() => DeviceStatusPageState();
}

class DeviceStatusPageState extends State<DeviceStatusPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  bool isTracking = false;

  @override
  void initState() {
    super.initState();
    _loadTrackingState();
  }

  Future<void> _loadTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isTracking = prefs.getBool('tracking_${widget.deviceId}') ?? false;
    });
  }

  Future<void> _toggleTracking() async {
    setState(() {
      isTracking = !isTracking;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('tracking_${widget.deviceId}', isTracking);
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    if (isTracking) {
      bluetoothService.startScan();
    } else {
      bluetoothService.stopScan();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
    }
  }

  @override

  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<BluetoothService>(context);

    return StreamBuilder<List<DiscoveredDevice>>(
      stream: bluetoothService.deviceStream,
      builder: (context, snapshot) {
        final trackingInfo = bluetoothService.getDeviceTrackingInfo(widget.deviceId);
        final distance = bluetoothService.getEstimatedDistance(widget.deviceId);
        final rssi = bluetoothService.getSmoothedRssi(widget.deviceId);
        
      return Scaffold(
        appBar: AppBar(title: const Text('Device Status')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
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

              // Description Section
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

              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${trackingInfo.isLost ? "Lost" : "Connected"}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: trackingInfo.isLost ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Movement: ${trackingInfo.movementStatus}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Last Seen: ${trackingInfo.lastSeen?.toString() ?? "N/A"}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Distance and Signal Strength
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildStatusRow(
                        'Distance',
                        '${distance.toStringAsFixed(2)} meters',
                        _getDistanceColor(distance),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusRow(
                        'Signal Strength',
                        '$rssi dBm',
                        _getRssiColor(rssi),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => bluetoothService.startActiveSearch(widget.deviceId),
                    icon: const Icon(Icons.search),
                    label: const Text('Find'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: trackingInfo.isLost 
                        ? () => bluetoothService.startActiveSearch(widget.deviceId)
                        : null,
                    icon: const Icon(Icons.location_searching),
                    label: const Text('Lost'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tracking Toggle
              SwitchListTile(
                title: const Text('Enable Tracking'),
                subtitle: Text(trackingInfo.isTracking 
                    ? 'Device is being monitored' 
                    : 'Device tracking is disabled'),
                value: trackingInfo.isTracking,
                onChanged: (value) => bluetoothService.toggleTracking(widget.deviceId),
              ),
            ],
          ),
        ),
      );
      
      },
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

  Color _getDistanceColor(double distance) {
    if (distance <= 3) return Colors.green;
    if (distance <= 5) return Colors.orange;
    return Colors.red;
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
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
}
