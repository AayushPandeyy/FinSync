import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  static Future<void> saveList(
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      data.map((entry) => _encodeMap(entry)).toList(),
    );
    await prefs.setString(key, encoded);
  }

  static Future<List<Map<String, dynamic>>?> readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((item) => _decodeMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  static Future<double?> readDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  static Map<String, dynamic> _encodeMap(Map<String, dynamic> map) {
    return map.map((key, value) => MapEntry(key, _encodeValue(value)));
  }

  static dynamic _encodeValue(dynamic value) {
    if (value is Timestamp) {
      return {
        '__offline_type': 'timestamp',
        'value': value.toDate().toIso8601String(),
      };
    } else if (value is DateTime) {
      return {
        '__offline_type': 'datetime',
        'value': value.toIso8601String(),
      };
    } else if (value is Map<String, dynamic>) {
      return _encodeMap(value);
    } else if (value is List) {
      return value.map(_encodeValue).toList();
    } else {
      return value;
    }
  }

  static Map<String, dynamic> _decodeMap(Map<String, dynamic> map) {
    return map.map((key, value) => MapEntry(key, _decodeValue(value)));
  }

  static dynamic _decodeValue(dynamic value) {
    if (value is Map && value['__offline_type'] == 'timestamp') {
      return Timestamp.fromDate(DateTime.parse(value['value'] as String));
    } else if (value is Map && value['__offline_type'] == 'datetime') {
      return DateTime.parse(value['value'] as String);
    } else if (value is Map) {
      return value.map((key, val) => MapEntry(key, _decodeValue(val)));
    } else if (value is List) {
      return value.map(_decodeValue).toList();
    } else {
      return value;
    }
  }
}
