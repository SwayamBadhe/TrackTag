// import 'package:flutter/material.dart';

// class MenuPage extends StatelessWidget {
//   final String userEmail;
//   final String profilePhotoUrl;

//   const MenuPage({
//     Key? key,
//     required this.userEmail,
//     required this.profilePhotoUrl,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Menu'),
//         centerTitle: true,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16.0),
//         children: [
//           // User Details
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               CircleAvatar(
//                 radius: 50,
//                 backgroundImage: NetworkImage(profilePhotoUrl),
//                 onBackgroundImageError: (_, __) => const Icon(Icons.person, size: 50),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 userEmail,
//                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           const Divider(height: 30, thickness: 1),

//           // Add Another User
//           ListTile(
//             leading: const Icon(Icons.person_add),
//             title: const Text('Add Another User'),
//             onTap: () {
//               // Navigate to Add Another User page
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AddUserPage()),
//               );
//             },
//           ),
//           const Divider(height: 10, thickness: 1),

//           // Contact Us
//           ListTile(
//             leading: const Icon(Icons.phone),
//             title: const Text('Contact Us'),
//             onTap: () {
//               // Show Contact Us info
//               showDialog(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   title: const Text('Contact Us'),
//                   content: const Text('Email: support@example.com\nPhone: +1234567890'),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('Close'),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//           const Divider(height: 10, thickness: 1),

//           // About Us
//           ListTile(
//             leading: const Icon(Icons.info),
//             title: const Text('About Us'),
//             onTap: () {
//               // Show About Us info
//               showDialog(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   title: const Text('About Us'),
//                   content: const Text(
//                     'This app helps users manage Bluetooth devices and other functionality.',
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('Close'),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//           const Divider(height: 10, thickness: 1),

//           // Log Out
//           ListTile(
//             leading: const Icon(Icons.logout),
//             title: const Text('Log Out'),
//             onTap: () {
//               // Handle logout logic
//               Navigator.of(context).pushReplacementNamed('/login');
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// class AddUserPage extends StatelessWidget {
//   const AddUserPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add Another User'),
//       ),
//       body: Center(
//         child: const Text('Add Another User functionality goes here.'),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MenuPage extends StatefulWidget {
  final String userEmail;
  final String profilePhotoUrl;

  const MenuPage({
    super.key,
    required this.userEmail,
    required this.profilePhotoUrl,
  });

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  File? _profileImage;

  /// Function to pick an image from the camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle errors (e.g., permissions)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick an image: $e")),
      );
    }
  }

  /// Function to show a dialog for choosing the image source
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Choose Image Source"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_album),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!) as ImageProvider
                      : NetworkImage(widget.profilePhotoUrl),
                  onBackgroundImageError: (_, __) =>
                      const Icon(Icons.person, size: 50),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 24,
                    color: Colors.white,
                  ), // Optional camera icon overlay
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.userEmail,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 30, thickness: 1),

          // Add Another User
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Add Another User'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddUserPage()),
              );
            },
          ),
          const Divider(height: 10, thickness: 1),

          // Contact Us
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Contact Us'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Contact Us'),
                  content: const Text(
                      'Email: support@example.com\nPhone: +1234567890'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 10, thickness: 1),

          // About Us
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Us'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Us'),
                  content: const Text(
                    'This app helps users manage Bluetooth devices and other functionality.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 10, thickness: 1),

          // Log Out
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}

class AddUserPage extends StatelessWidget {
  const AddUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Another User'),
      ),
      body: const Center(
        child: Text('Add Another User functionality goes here.'),
      ),
    );
  }
}
