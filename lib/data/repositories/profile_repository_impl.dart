import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/server_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../storage/secure_credentials_storage.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._sharedPreferences, this._credentialsStorage);

  static const _profilesKey = 'server_profiles_v1';
  static const _activeProfileIdKey = 'active_profile_id';

  final SharedPreferences _sharedPreferences;
  final SecureCredentialsStorage _credentialsStorage;

  @override
  Future<void> deleteProfile(String profileId) async {
    final profiles = await loadProfiles();
    final remaining = profiles
        .where((profile) => profile.id != profileId)
        .toList();
    await _sharedPreferences.setString(
      _profilesKey,
      jsonEncode(remaining.map((profile) => profile.toMetadataJson()).toList()),
    );
    await _credentialsStorage.delete(profileId);

    final activeProfileId = await loadActiveProfileId();
    if (activeProfileId == profileId) {
      await saveActiveProfileId(remaining.isEmpty ? null : remaining.first.id);
    }
  }

  @override
  Future<String?> loadActiveProfileId() async {
    return _sharedPreferences.getString(_activeProfileIdKey);
  }

  @override
  Future<List<ServerProfile>> loadProfiles() async {
    final raw = _sharedPreferences.getString(_profilesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    final profiles = <ServerProfile>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final profileId = item['id'] as String?;
      if (profileId == null || profileId.isEmpty) {
        continue;
      }
      final credentialsJson = await _credentialsStorage.read(profileId);
      if (credentialsJson == null || credentialsJson.isEmpty) {
        continue;
      }
      profiles.add(
        ServerProfile.fromStored(
          metadata: item,
          credentialsJson: credentialsJson,
        ),
      );
    }
    return profiles;
  }

  @override
  Future<void> saveActiveProfileId(String? profileId) async {
    if (profileId == null) {
      await _sharedPreferences.remove(_activeProfileIdKey);
      return;
    }
    await _sharedPreferences.setString(_activeProfileIdKey, profileId);
  }

  @override
  Future<void> saveProfile(ServerProfile profile) async {
    final profiles = await loadProfiles();
    final updatedProfiles = [
      for (final existing in profiles)
        if (existing.id != profile.id) existing,
      profile,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    await _sharedPreferences.setString(
      _profilesKey,
      jsonEncode(updatedProfiles.map((item) => item.toMetadataJson()).toList()),
    );
    await _credentialsStorage.save(
      profile.id,
      username: profile.username,
      password: profile.password,
    );
  }
}
