import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveDb {
  final List<String> boxesStr = ['fav', 'other'];

  Future<void> init() async {
    if (kIsWeb) {
      await Hive.initFlutter("WeebHQ");
    } else {
      final suppDir = await getApplicationSupportDirectory();
      await Hive.initFlutter(suppDir.path);
    }
    for (String i in boxesStr) {
      await Hive.openBox(i);
    }
  }

  getData(dynamic key, [String boxName = "other"]) {
    final box = Hive.box(boxName);
    final data = box.get(key);
    return data;
  }

  putData(key, data, [String boxName = "other"]) {
    final box = Hive.box(boxName);
    if (key == null) {
      box.putAll(data);
    } else {
      box.put(key, data);
    }
  }

  void deleteItem(key, String boxName) {
    final box = Hive.box(boxName);
    box.delete(key);
  }

  void clearBox(String boxName) {
    final box = Hive.box(boxName);
    box.clear();
  }

  Map box2map(String boxName) {
    final box = Hive.box(boxName);
    return box.toMap();
  }

  Stream getBoxStream(String boxName) {
    final box = Hive.box(boxName);
    return box.watch();
  }

  bool isBoxNULL(String boxName, key) {
    try {
      final box = Hive.box(boxName);
      final i = box.get(key) != null;
      return i;
    } catch (e) {
      return false;     
    }
  }

  void clearAllData() {
    for (var name in boxesStr) {
      final box = Hive.box(name);
      box.clear();
    }
  }
}