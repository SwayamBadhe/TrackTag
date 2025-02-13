import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DeviceInfoCard extends StatelessWidget {
  final DiscoveredDevice device;
  final Function(String) onDeviceSelected;

  final double? estimatedDistance;
  final int smoothedRssi;

  const DeviceInfoCard({
    super.key,
    required this.device,
    this.estimatedDistance,
    required this.smoothedRssi,
    required this.onDeviceSelected,
  });


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        title: Text(
          device.name.isNotEmpty ? device.name : "Unknown Device",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Signal Strength: ${device.rssi} dBm',
          style: TextStyle(
            color: _getRssiColor(device.rssi),
          ),
        ),
        leading: Icon(
          Icons.bluetooth,
          color: _getRssiColor(device.rssi),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection('Device ID', device.id),
                _buildInfoSection(
                  'Signal Strength',
                  '${device.rssi} dBm (${_getSignalQuality(device.rssi)})',
                ),
                _buildInfoSection(
                  'Smoothed RSSI',
                  '$smoothedRssi dBm',
                ),
                if (estimatedDistance != null)
                  _buildInfoSection(
                    'Estimated Distance',
                    '${estimatedDistance!.toStringAsFixed(2)} meters',
                  ),
                if (device.serviceUuids.isNotEmpty)
                  _buildServicesList('Service UUIDs', device.serviceUuids),
                if (device.manufacturerData.isNotEmpty)
                  _buildManufacturerData('Manufacturer Data', device.manufacturerData),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => onDeviceSelected(device.id),
                      child: const Text('Select Device'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(String title, List<Uuid> uuids) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          ...uuids.map((uuid) => Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                child: Text(
                  '• ${uuid.toString()}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildManufacturerData(String title, List<int> data) {
    final hexData = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
    return _buildInfoSection(title, hexData);
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
  }

  String _getSignalQuality(int rssi) {
    if (rssi >= -60) return 'Excellent';
    if (rssi >= -70) return 'Good';
    if (rssi >= -80) return 'Fair';
    if (rssi >= -90) return 'Poor';
    return 'Very Poor';
  }
}