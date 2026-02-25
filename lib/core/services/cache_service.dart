import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _boxName = 'app_cache';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static Future<void> set(String key, dynamic value) async {
    final box = Hive.box(_boxName);
    await box.put(key, value);
  }

  static dynamic get(String key) {
    final box = Hive.box(_boxName);
    return box.get(key);
  }

  static Future<void> remove(String key) async {
    final box = Hive.box(_boxName);
    await box.delete(key);
  }

  static Future<void> clear() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }
}
