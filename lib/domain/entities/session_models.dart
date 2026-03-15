enum EncryptionMode { required, preferred, tolerated }

class SessionInfo {
  const SessionInfo({
    required this.version,
    required this.rpcVersion,
    required this.rpcVersionMinimum,
    required this.downloadDir,
    required this.altSpeedEnabled,
    required this.altSpeedUp,
    required this.altSpeedDown,
    required this.speedLimitUp,
    required this.speedLimitDown,
    required this.speedLimitUpEnabled,
    required this.speedLimitDownEnabled,
    required this.encryptionMode,
    required this.downloadQueueEnabled,
    required this.downloadQueueSize,
    required this.seedQueueEnabled,
    required this.seedQueueSize,
    required this.queueStalledEnabled,
    required this.queueStalledMinutes,
    required this.startAddedTorrents,
  });

  final String version;
  final int rpcVersion;
  final int rpcVersionMinimum;
  final String downloadDir;
  final bool altSpeedEnabled;
  final int altSpeedUp;
  final int altSpeedDown;
  final int speedLimitUp;
  final int speedLimitDown;
  final bool speedLimitUpEnabled;
  final bool speedLimitDownEnabled;
  final EncryptionMode encryptionMode;
  final bool downloadQueueEnabled;
  final int downloadQueueSize;
  final bool seedQueueEnabled;
  final int seedQueueSize;
  final bool queueStalledEnabled;
  final int queueStalledMinutes;
  final bool startAddedTorrents;

  SessionInfo copyWith({
    String? version,
    int? rpcVersion,
    int? rpcVersionMinimum,
    String? downloadDir,
    bool? altSpeedEnabled,
    int? altSpeedUp,
    int? altSpeedDown,
    int? speedLimitUp,
    int? speedLimitDown,
    bool? speedLimitUpEnabled,
    bool? speedLimitDownEnabled,
    EncryptionMode? encryptionMode,
    bool? downloadQueueEnabled,
    int? downloadQueueSize,
    bool? seedQueueEnabled,
    int? seedQueueSize,
    bool? queueStalledEnabled,
    int? queueStalledMinutes,
    bool? startAddedTorrents,
  }) {
    return SessionInfo(
      version: version ?? this.version,
      rpcVersion: rpcVersion ?? this.rpcVersion,
      rpcVersionMinimum: rpcVersionMinimum ?? this.rpcVersionMinimum,
      downloadDir: downloadDir ?? this.downloadDir,
      altSpeedEnabled: altSpeedEnabled ?? this.altSpeedEnabled,
      altSpeedUp: altSpeedUp ?? this.altSpeedUp,
      altSpeedDown: altSpeedDown ?? this.altSpeedDown,
      speedLimitUp: speedLimitUp ?? this.speedLimitUp,
      speedLimitDown: speedLimitDown ?? this.speedLimitDown,
      speedLimitUpEnabled: speedLimitUpEnabled ?? this.speedLimitUpEnabled,
      speedLimitDownEnabled:
          speedLimitDownEnabled ?? this.speedLimitDownEnabled,
      encryptionMode: encryptionMode ?? this.encryptionMode,
      downloadQueueEnabled: downloadQueueEnabled ?? this.downloadQueueEnabled,
      downloadQueueSize: downloadQueueSize ?? this.downloadQueueSize,
      seedQueueEnabled: seedQueueEnabled ?? this.seedQueueEnabled,
      seedQueueSize: seedQueueSize ?? this.seedQueueSize,
      queueStalledEnabled: queueStalledEnabled ?? this.queueStalledEnabled,
      queueStalledMinutes: queueStalledMinutes ?? this.queueStalledMinutes,
      startAddedTorrents: startAddedTorrents ?? this.startAddedTorrents,
    );
  }
}

class SessionStats {
  const SessionStats({
    required this.activeTorrentCount,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.pausedTorrentCount,
    required this.torrentCount,
    required this.cumulativeDownloadedBytes,
    required this.cumulativeUploadedBytes,
    required this.filesAdded,
    required this.sessionCount,
  });

  final int activeTorrentCount;
  final int downloadSpeed;
  final int uploadSpeed;
  final int pausedTorrentCount;
  final int torrentCount;
  final int cumulativeDownloadedBytes;
  final int cumulativeUploadedBytes;
  final int filesAdded;
  final int sessionCount;
}

class FreeSpaceInfo {
  const FreeSpaceInfo({required this.path, required this.sizeBytes});

  final String path;
  final int sizeBytes;
}
