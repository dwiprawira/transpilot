import '../../domain/entities/session_models.dart';

class SessionInfoDto {
  const SessionInfoDto(this.json);

  final Map<String, dynamic> json;

  SessionInfo toDomain() {
    return SessionInfo(
      version: json['version'] as String? ?? 'Unknown',
      rpcVersion: json['rpc-version'] as int? ?? 0,
      rpcVersionMinimum: json['rpc-version-minimum'] as int? ?? 0,
      downloadDir: json['download-dir'] as String? ?? '',
      altSpeedEnabled: json['alt-speed-enabled'] as bool? ?? false,
      altSpeedUp: json['alt-speed-up'] as int? ?? 0,
      altSpeedDown: json['alt-speed-down'] as int? ?? 0,
      speedLimitUp: json['speed-limit-up'] as int? ?? 0,
      speedLimitDown: json['speed-limit-down'] as int? ?? 0,
      speedLimitUpEnabled: json['speed-limit-up-enabled'] as bool? ?? false,
      speedLimitDownEnabled: json['speed-limit-down-enabled'] as bool? ?? false,
      encryptionMode: _encryptionMode(
        json['encryption'] as String? ?? 'preferred',
      ),
      downloadQueueEnabled: json['download-queue-enabled'] as bool? ?? false,
      downloadQueueSize: json['download-queue-size'] as int? ?? 0,
      seedQueueEnabled: json['seed-queue-enabled'] as bool? ?? false,
      seedQueueSize: json['seed-queue-size'] as int? ?? 0,
      queueStalledEnabled: json['queue-stalled-enabled'] as bool? ?? false,
      queueStalledMinutes: json['queue-stalled-minutes'] as int? ?? 0,
      startAddedTorrents: json['start-added-torrents'] as bool? ?? true,
    );
  }

  static EncryptionMode _encryptionMode(String raw) {
    switch (raw) {
      case 'required':
        return EncryptionMode.required;
      case 'tolerated':
        return EncryptionMode.tolerated;
      case 'preferred':
      default:
        return EncryptionMode.preferred;
    }
  }

  static String encryptionModeValue(EncryptionMode mode) {
    switch (mode) {
      case EncryptionMode.required:
        return 'required';
      case EncryptionMode.preferred:
        return 'preferred';
      case EncryptionMode.tolerated:
        return 'tolerated';
    }
  }
}

class SessionStatsDto {
  const SessionStatsDto(this.json);

  final Map<String, dynamic> json;

  SessionStats toDomain() {
    final cumulative = json['cumulative-stats'] as Map<String, dynamic>? ?? {};
    final current = json['current-stats'] as Map<String, dynamic>? ?? {};
    return SessionStats(
      activeTorrentCount: current['activeTorrentCount'] as int? ?? 0,
      downloadSpeed: current['downloadSpeed'] as int? ?? 0,
      uploadSpeed: current['uploadSpeed'] as int? ?? 0,
      pausedTorrentCount: json['pausedTorrentCount'] as int? ?? 0,
      torrentCount: json['torrentCount'] as int? ?? 0,
      cumulativeDownloadedBytes: cumulative['downloadedBytes'] as int? ?? 0,
      cumulativeUploadedBytes: cumulative['uploadedBytes'] as int? ?? 0,
      filesAdded: cumulative['filesAdded'] as int? ?? 0,
      sessionCount: cumulative['sessionCount'] as int? ?? 0,
    );
  }
}

class FreeSpaceDto {
  const FreeSpaceDto(this.json);

  final Map<String, dynamic> json;

  FreeSpaceInfo toDomain() {
    return FreeSpaceInfo(
      path: json['path'] as String? ?? '',
      sizeBytes: json['size-bytes'] as int? ?? 0,
    );
  }
}
