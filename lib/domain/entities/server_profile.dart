import 'dart:convert';

class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.rpcPath,
    required this.useHttps,
    required this.username,
    required this.password,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String rpcPath;
  final bool useHttps;
  final String username;
  final String password;

  String get normalizedRpcPath {
    final trimmed = rpcPath.trim();
    if (trimmed.isEmpty) {
      return '/transmission/rpc';
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  Uri get rpcUri => Uri.parse(
    '${useHttps ? 'https' : 'http'}://$host:$port$normalizedRpcPath',
  );

  ServerProfile copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? rpcPath,
    bool? useHttps,
    String? username,
    String? password,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      rpcPath: rpcPath ?? this.rpcPath,
      useHttps: useHttps ?? this.useHttps,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMetadataJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'rpcPath': rpcPath,
      'useHttps': useHttps,
    };
  }

  Map<String, String> toCredentialsJson() {
    return {'username': username, 'password': password};
  }

  static ServerProfile fromStored({
    required Map<String, dynamic> metadata,
    required String credentialsJson,
  }) {
    final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
    return ServerProfile(
      id: metadata['id'] as String? ?? '',
      name: metadata['name'] as String? ?? '',
      host: metadata['host'] as String? ?? '',
      port: metadata['port'] as int? ?? 9091,
      rpcPath: metadata['rpcPath'] as String? ?? '/transmission/rpc',
      useHttps: metadata['useHttps'] as bool? ?? false,
      username: credentials['username'] as String? ?? '',
      password: credentials['password'] as String? ?? '',
    );
  }
}

class ProfilesState {
  const ProfilesState({required this.profiles, required this.activeProfileId});

  final List<ServerProfile> profiles;
  final String? activeProfileId;

  ServerProfile? get activeProfile {
    for (final profile in profiles) {
      if (profile.id == activeProfileId) {
        return profile;
      }
    }
    return null;
  }

  ProfilesState copyWith({
    List<ServerProfile>? profiles,
    String? activeProfileId,
    bool clearActiveProfile = false,
  }) {
    return ProfilesState(
      profiles: profiles ?? this.profiles,
      activeProfileId: clearActiveProfile
          ? null
          : activeProfileId ?? this.activeProfileId,
    );
  }
}
