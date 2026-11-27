import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../models/domain.dart';

abstract class LocalCache {
  Workspace? read(String userId);
  Future<void> write(String userId, Workspace data);
  Future<void> clear(String userId);
  bool get compact;
  Future<void> setCompact(bool value);
}

class HiveCache implements LocalCache {
  HiveCache(this.box);
  final Box<String> box;
  @override
  Workspace? read(String userId) {
    final raw = box.get('workspace:$userId');
    if (raw == null) return null;
    return Workspace.fromJson(jsonDecode(raw));
  }

  @override
  Future<void> write(String userId, Workspace data) =>
      box.put('workspace:$userId', jsonEncode(data.toJson()));
  @override
  Future<void> clear(String userId) => box.delete('workspace:$userId');
  @override
  bool get compact => box.get('compact') == 'true';
  @override
  Future<void> setCompact(bool value) => box.put('compact', '$value');
}
