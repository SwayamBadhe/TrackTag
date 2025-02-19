// lib/services/eddystone_parser.dart
import 'package:flutter/foundation.dart';

class EddystoneParser {
  static const int EDDYSTONE_UUID = 0xFEAA;
  
  static Map<String, dynamic>? parseManufacturerData(List<int> data) {
    if (data.length < 2) return null;

    try {
      // Check for Eddystone UUID
      int uuid = (data[1] << 8) | data[0];
      if (uuid != EDDYSTONE_UUID) return null;

      // Get frame type
      int frameType = data[2];
      
      switch (frameType) {
        case 0x00:
          return _parseUIDFrame(data);
        case 0x10:
          return _parseURLFrame(data);
        case 0x20:
          return _parseTLMFrame(data);
        case 0x30:
          return _parseEIDFrame(data);
        default:
          return {
            'frameType': 'Unknown',
            'rawData': data,
          };
      }
    } catch (e) {
      debugPrint('Error parsing Eddystone data: $e');
      return null;
    }
  }

  static Map<String, dynamic> _parseUIDFrame(List<int> data) {
    if (data.length < 20) return {'frameType': 'UID-Invalid Length'};

    return {
      'frameType': 'UID',
      'txPower': data[3],
      'namespaceId': data.sublist(4, 14).map((b) => b.toRadixString(16).padLeft(2, '0')).join(''),
      'instanceId': data.sublist(14, 20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(''),
    };
  }

  static Map<String, dynamic> _parseURLFrame(List<int> data) {
    if (data.length < 4) return {'frameType': 'URL-Invalid Length'};

    // URL scheme prefixes
    const urlSchemes = [
      'http://www.',
      'https://www.',
      'http://',
      'https://',
    ];

    // URL encodings
    const urlEncodings = [
      '.com/',
      '.org/',
      '.edu/',
      '.net/',
      '.info/',
      '.biz/',
      '.gov/',
      '.com',
      '.org',
      '.edu',
      '.net',
      '.info',
      '.biz',
      '.gov'
    ];

    try {
      int txPower = data[3];
      int urlScheme = data[4];
      String url = urlSchemes[urlScheme];

      // Build the URL
      for (int i = 5; i < data.length; i++) {
        if (data[i] < urlEncodings.length) {
          url += urlEncodings[data[i]];
        } else {
          url += String.fromCharCode(data[i]);
        }
      }

      return {
        'frameType': 'URL',
        'txPower': txPower,
        'url': url,
      };
    } catch (e) {
      return {
        'frameType': 'URL-Parse Error',
        'error': e.toString(),
      };
    }
  }

  static Map<String, dynamic> _parseTLMFrame(List<int> data) {
    if (data.length < 14) return {'frameType': 'TLM-Invalid Length'};

    try {
      int versionByte = data[3];
      int battery = (data[4] << 8) | data[5];
      double temp = (data[6] << 8 | data[7]) / 256.0;
      int advCount = (data[8] << 24) | (data[9] << 16) | (data[10] << 8) | data[11];
      int secCount = (data[12] << 24) | (data[13] << 16) | (data[14] << 8) | data[15];

      return {
        'frameType': 'TLM',
        'version': versionByte,
        'battery': battery,
        'temperature': temp,
        'advertisementCount': advCount,
        'secondsSinceReset': secCount,
      };
    } catch (e) {
      return {
        'frameType': 'TLM-Parse Error',
        'error': e.toString(),
      };
    }
  }

  static Map<String, dynamic> _parseEIDFrame(List<int> data) {
    if (data.length < 10) return {'frameType': 'EID-Invalid Length'};

    return {
      'frameType': 'EID',
      'txPower': data[3],
      'eid': data.sublist(4, 12).map((b) => b.toRadixString(16).padLeft(2, '0')).join(''),
    };
  }
}