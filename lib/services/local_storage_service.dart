import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

class LocalStorageService {
  static Box? _userBox;
  static Box? _cacheBox;

  static Future<void> init() async {
    _userBox = await Hive.openBox(AppConstants.userBoxName);
    _cacheBox = await Hive.openBox(AppConstants.cacheBoxName);
  }

  // User Box
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _userBox?.put('current_user', user);
  }

  static Map<String, dynamic>? getUser() {
    final data = _userBox?.get('current_user');
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static Future<void> deleteUser() async {
    await _userBox?.delete('current_user');
  }

  // Cache Box
  static Future<void> saveCache(String key, dynamic value) async {
    await _cacheBox?.put(key, value);
  }

  static dynamic getCache(String key) {
    return _cacheBox?.get(key);
  }

  static Future<void> deleteCache(String key) async {
    await _cacheBox?.delete(key);
  }

  static Future<void> clearCache() async {
    await _cacheBox?.clear();
  }

  static Future<void> clearAll() async {
    await _userBox?.clear();
    await _cacheBox?.clear();
  }
}
