import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCredentialsStorage {
  SecureCredentialsStorage(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  String _keyForProfile(String profileId) => 'server_credentials_$profileId';

  Future<void> save(
    String profileId, {
    required String username,
    required String password,
  }) {
    return _secureStorage.write(
      key: _keyForProfile(profileId),
      value: jsonEncode({'username': username, 'password': password}),
    );
  }

  Future<String?> read(String profileId) {
    return _secureStorage.read(key: _keyForProfile(profileId));
  }

  Future<void> delete(String profileId) {
    return _secureStorage.delete(key: _keyForProfile(profileId));
  }
}
