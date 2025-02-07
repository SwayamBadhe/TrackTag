import 'package:flutter/material.dart';

class AddDeviceCard extends StatelessWidget {
  const AddDeviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            // Handle card tap here
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add New Device button tapped')),
            );
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              height: 200,
              width: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    size: 40,
                    color: Colors.teal,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add New Device',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
