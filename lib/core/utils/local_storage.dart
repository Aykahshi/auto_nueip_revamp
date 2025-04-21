import 'package:shared_preferences/shared_preferences.dart';

sealed class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

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

    return (_prefs!.get(key) as T?) ?? defaultValue;
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
