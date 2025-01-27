import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DeviceStatusPage extends StatefulWidget {
  const DeviceStatusPage({Key? key, required String deviceId}) : super(key: key);

  @override
  _DeviceStatusPageState createState() => _DeviceStatusPageState();
}

class _DeviceStatusPageState extends State<DeviceStatusPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  double _batteryPercentage = 75; // Mock battery percentage
  double _deviceDistance = 6; // Mock device distance

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
    }
  }

  Color _getDistanceColor(double distance) {
    if (distance <= 3) {
      return Colors.green;
    } else if (distance <= 5) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Status'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showImagePickerDialog(),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          _profileImage != null ? FileImage(File(_profileImage!.path)) : null,
                      child: _profileImage == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload Profile Photo',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle Find Button Action
                  },
                  child: const Text('Find'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle Lost Button Action
                  },
                  child: const Text('Lost'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Battery Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Battery Percentage:', style: TextStyle(fontSize: 16)),
                Text(
                  '$_batteryPercentage%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _batteryPercentage > 20 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Distance Indicator
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 30,
                    color: _deviceDistance <= 3 ? Colors.green : Colors.grey,
                    child: const Center(child: Text('Close')),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 30,
                    color: (_deviceDistance > 3 && _deviceDistance <= 5)
                        ? Colors.yellow
                        : Colors.grey,
                    child: const Center(child: Text('Medium')),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 30,
                    color: _deviceDistance > 5 ? Colors.red : Colors.grey,
                    child: const Center(child: Text('Far')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description Section
            const Text('Description:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write a description...',
              ),
            ),
          ],
        ),
      ),
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
}
