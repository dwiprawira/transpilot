import 'dart:convert';

import '../../core/constants/transmission_fields.dart';
import '../../domain/entities/server_profile.dart';
import '../../domain/entities/session_models.dart';
import '../../domain/entities/torrent.dart';
import '../../domain/repositories/transmission_repository.dart';
import '../dto/session_dto.dart';
import '../dto/torrent_dto.dart';
import '../rpc/transmission_rpc_client.dart';

class TransmissionRepositoryImpl implements TransmissionRepository {
  TransmissionRepositoryImpl(this._client);

  final TransmissionRpcClient _client;

  @override
  ServerProfile get profile => _client.profile;

  @override
  Future<AddTorrentResult> addTorrent({
    String? magnetLink,
    List<int>? metainfo,
    String? downloadDir,
    bool paused = false,
    BandwidthPriority priority = BandwidthPriority.normal,
  }) async {
    final response = await _client.call(
      'torrent-add',
      arguments: {
        if (magnetLink != null && magnetLink.isNotEmpty) 'filename': magnetLink,
        if (metainfo != null && metainfo.isNotEmpty)
          'metainfo': base64Encode(metainfo),
        if (downloadDir != null && downloadDir.isNotEmpty)
          'download-dir': downloadDir,
        'paused': paused,
        'bandwidthPriority': priority.rpcValue,
      },
    );
    final arguments = Map<String, dynamic>.from(
      response['arguments'] as Map? ?? const {},
    );
    final added = arguments['torrent-added'] as Map<String, dynamic>?;
    final duplicate = arguments['torrent-duplicate'] as Map<String, dynamic>?;
    final result = added ?? duplicate ?? const <String, dynamic>{};
    return AddTorrentResult(
      isDuplicate: duplicate != null,
      name: result['name'] as String? ?? 'Torrent',
      id: result['id'] as int?,
    );
  }

  @override
  Future<FreeSpaceInfo> getFreeSpace(String path) async {
    final response = await _client.call(
      'free-space',
      arguments: {'path': path},
    );
    return FreeSpaceDto(
      Map<String, dynamic>.from(response['arguments'] as Map),
    ).toDomain();
  }

  @override
  Future<SessionInfo> getSessionInfo() async {
    final response = await _client.call('session-get');
    return SessionInfoDto(
      Map<String, dynamic>.from(response['arguments'] as Map),
    ).toDomain();
  }

  @override
  Future<SessionStats> getSessionStats() async {
    final response = await _client.call('session-stats');
    return SessionStatsDto(
      Map<String, dynamic>.from(response['arguments'] as Map),
    ).toDomain();
  }

  @override
  Future<Torrent?> getTorrentDetail(int id) async {
    final response = await _client.call(
      'torrent-get',
      arguments: {
        'fields': TransmissionFields.detail,
        'ids': [id],
      },
    );
    final torrents =
        (response['arguments'] as Map<String, dynamic>)['torrents']
            as List<dynamic>? ??
        const [];
    if (torrents.isEmpty) {
      return null;
    }
    return TorrentDto(
      Map<String, dynamic>.from(torrents.first as Map),
    ).toDomain();
  }

  @override
  Future<List<TorrentFileEntry>> getTorrentFiles(int id) async {
    final response = await _client.call(
      'torrent-get',
      arguments: {
        'fields': TransmissionFields.files,
        'ids': [id],
      },
      receiveTimeout: const Duration(seconds: 90),
    );
    final torrents =
        (response['arguments'] as Map<String, dynamic>)['torrents']
            as List<dynamic>? ??
        const [];
    if (torrents.isEmpty) {
      return const <TorrentFileEntry>[];
    }
    return TorrentDto.parseFiles(
      Map<String, dynamic>.from(torrents.first as Map),
    );
  }

  @override
  Future<List<TorrentPeer>> getTorrentPeers(int id) async {
    final response = await _client.call(
      'torrent-get',
      arguments: {
        'fields': TransmissionFields.peers,
        'ids': [id],
      },
      receiveTimeout: const Duration(seconds: 45),
    );
    final torrents =
        (response['arguments'] as Map<String, dynamic>)['torrents']
            as List<dynamic>? ??
        const [];
    if (torrents.isEmpty) {
      return const <TorrentPeer>[];
    }
    return TorrentDto.parsePeers(
      Map<String, dynamic>.from(torrents.first as Map),
    );
  }

  @override
  Future<List<Torrent>> getTorrents() async {
    final response = await _client.call(
      'torrent-get',
      arguments: {'fields': TransmissionFields.list},
    );
    final torrents =
        (response['arguments'] as Map<String, dynamic>)['torrents']
            as List<dynamic>? ??
        const [];
    return torrents
        .whereType<Map<String, dynamic>>()
        .map((json) => TorrentDto(json).toDomain())
        .toList();
  }

  @override
  Future<void> moveData({
    required List<int> ids,
    required String location,
    bool move = true,
  }) async {
    await _client.call(
      'torrent-set-location',
      arguments: {'ids': ids, 'location': location, 'move': move},
    );
  }

  @override
  Future<void> moveQueue(List<int> ids, QueueMoveDirection direction) async {
    final method = switch (direction) {
      QueueMoveDirection.top => 'queue-move-top',
      QueueMoveDirection.up => 'queue-move-up',
      QueueMoveDirection.down => 'queue-move-down',
      QueueMoveDirection.bottom => 'queue-move-bottom',
    };
    await _client.call(method, arguments: {'ids': ids});
  }

  @override
  Future<void> reannounceTorrents(List<int> ids) async {
    await _client.call('torrent-reannounce', arguments: {'ids': ids});
  }

  @override
  Future<void> removeTorrents(
    List<int> ids, {
    bool deleteLocalData = false,
  }) async {
    await _client.call(
      'torrent-remove',
      arguments: {'ids': ids, 'delete-local-data': deleteLocalData},
    );
  }

  @override
  Future<void> renamePath({
    required int torrentId,
    required String path,
    required String name,
  }) async {
    await _client.call(
      'torrent-rename-path',
      arguments: {
        'ids': [torrentId],
        'path': path,
        'name': name,
      },
    );
  }

  @override
  Future<void> setBandwidthPriority(
    List<int> ids,
    BandwidthPriority priority,
  ) async {
    await _client.call(
      'torrent-set',
      arguments: {'ids': ids, 'bandwidthPriority': priority.rpcValue},
    );
  }

  @override
  Future<void> setFilePriority(
    int torrentId, {
    required List<int> high,
    required List<int> normal,
    required List<int> low,
  }) async {
    await _client.call(
      'torrent-set',
      arguments: {
        'ids': [torrentId],
        if (high.isNotEmpty) 'priority-high': high,
        if (normal.isNotEmpty) 'priority-normal': normal,
        if (low.isNotEmpty) 'priority-low': low,
      },
    );
  }

  @override
  Future<void> setFilesWanted(
    int torrentId, {
    required List<int> wanted,
    required List<int> unwanted,
  }) async {
    await _client.call(
      'torrent-set',
      arguments: {
        'ids': [torrentId],
        if (wanted.isNotEmpty) 'files-wanted': wanted,
        if (unwanted.isNotEmpty) 'files-unwanted': unwanted,
      },
    );
  }

  @override
  Future<void> startTorrents(List<int> ids, {bool bypassQueue = false}) async {
    await _client.call(
      bypassQueue ? 'torrent-start-now' : 'torrent-start',
      arguments: {'ids': ids},
    );
  }

  @override
  Future<void> stopTorrents(List<int> ids) async {
    await _client.call('torrent-stop', arguments: {'ids': ids});
  }

  @override
  Future<void> testConnection() async {
    await _client.call('session-get');
  }

  @override
  Future<void> updateSessionInfo(SessionInfo sessionInfo) async {
    await _client.call(
      'session-set',
      arguments: {
        'download-dir': sessionInfo.downloadDir,
        'alt-speed-enabled': sessionInfo.altSpeedEnabled,
        'alt-speed-up': sessionInfo.altSpeedUp,
        'alt-speed-down': sessionInfo.altSpeedDown,
        'speed-limit-up': sessionInfo.speedLimitUp,
        'speed-limit-down': sessionInfo.speedLimitDown,
        'speed-limit-up-enabled': sessionInfo.speedLimitUpEnabled,
        'speed-limit-down-enabled': sessionInfo.speedLimitDownEnabled,
        'encryption': SessionInfoDto.encryptionModeValue(
          sessionInfo.encryptionMode,
        ),
        'download-queue-enabled': sessionInfo.downloadQueueEnabled,
        'download-queue-size': sessionInfo.downloadQueueSize,
        'seed-queue-enabled': sessionInfo.seedQueueEnabled,
        'seed-queue-size': sessionInfo.seedQueueSize,
        'queue-stalled-enabled': sessionInfo.queueStalledEnabled,
        'queue-stalled-minutes': sessionInfo.queueStalledMinutes,
        'start-added-torrents': sessionInfo.startAddedTorrents,
      },
    );
  }

  @override
  Future<void> verifyTorrents(List<int> ids) async {
    await _client.call('torrent-verify', arguments: {'ids': ids});
  }
}
