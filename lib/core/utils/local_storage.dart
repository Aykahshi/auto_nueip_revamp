import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

sealed class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool isInitialized() => _prefs != null;

  static Future<bool> set<T>(String key, T value) async {
    if (_prefs == null) throw Exception("SharedPreferences is not initialized");

    if (value is int) {
      return await _prefs!.setInt(key, value);
    } else if (value is double) {
      return await _prefs!.setDouble(key, value);
    } else if (value is bool) {
      return await _prefs!.setBool(key, value);
    } else if (value is String) {
      return await _prefs!.setString(key, value);
    } else if (value is List<String>) {
      return await _prefs!.setStringList(key, value);
    } else {
      throw Exception("Unsupported type");
    }
  }

  static T get<T>(String key, {required T defaultValue}) {
    if (_prefs == null) throw Exception("SharedPreferences is not initialized");

    if (T == List<String>) {
      final List<String>? value = _prefs!.getStringList(key);
      return (value ?? defaultValue) as T;
    } else {
      final Object? value = _prefs!.get(key);
      try {
        return (value as T?) ?? defaultValue;
      } catch (e) {
        debugPrint(
          "LocalStorage.get: Cast failed for key '$key' to type $T. Returning default. Error: $e",
        );
        return defaultValue;
      }
    }
  }

  static Future<bool> remove(String key) async {
    if (_prefs == null) throw Exception("SharedPreferences is not initialized");
    return await _prefs!.remove(key);
  }

  static Future<bool> clear() async {
    if (_prefs == null) throw Exception("SharedPreferences is not initialized");
    return await _prefs!.clear();
  }
}
