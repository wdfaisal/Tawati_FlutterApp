import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalMuteService {
  static const _storageKey = 'muted_group_ids';
  static const _storage = FlutterSecureStorage();

  Future<Set<String>> loadMutedGroupIds() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || raw.isEmpty) return <String>{};
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _saveMutedGroupIds(Set<String> ids) async {
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(ids.toList()),
    );
  }

  Future<void> setGroupMuted(String groupId, bool muted) async {
    if (kIsWeb) return;
    final ids = await loadMutedGroupIds();
    if (muted) {
      ids.add(groupId);
    } else {
      ids.remove(groupId);
    }
    await _saveMutedGroupIds(ids);
  }
}
