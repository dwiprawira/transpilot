import '../../domain/entities/torrent.dart';

class TorrentDto {
  const TorrentDto(this.json);

  final Map<String, dynamic> json;

  Torrent toDomain() {
    final trackers = (json['trackers'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final trackerStats = (json['trackerStats'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final trackerStatsById = <int, Map<String, dynamic>>{
      for (final item in trackerStats) item['id'] as int? ?? -1: item,
    };

    final trackerItems = trackers.map((tracker) {
      final id = tracker['id'] as int? ?? -1;
      final stat = trackerStatsById[id] ?? const <String, dynamic>{};
      return TorrentTracker(
        id: id,
        announce: tracker['announce'] as String? ?? '',
        host: _normalizeTrackerHost(
          stat['host'] as String? ?? tracker['announce'] as String? ?? '',
        ),
        siteName: tracker['sitename'] as String? ?? '',
        tier: tracker['tier'] as int? ?? stat['tier'] as int? ?? 0,
        lastAnnounceResult: stat['lastAnnounceResult'] as String? ?? '',
        lastAnnounceSucceeded: stat['lastAnnounceSucceeded'] as bool? ?? false,
      );
    }).toList();

    final fileEntries = parseFiles(json);
    final peerEntries = parsePeers(json);

    return Torrent(
      id: json['id'] as int? ?? 0,
      hashString: json['hashString'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed torrent',
      status: _statusFromValue(json['status'] as int? ?? 0),
      percentDone: (json['percentDone'] as num? ?? 0).toDouble(),
      metadataPercentComplete: (json['metadataPercentComplete'] as num? ?? 1)
          .toDouble(),
      totalSize: json['totalSize'] as int? ?? 0,
      sizeWhenDone: json['sizeWhenDone'] as int? ?? 0,
      rateDownload: json['rateDownload'] as int? ?? 0,
      rateUpload: json['rateUpload'] as int? ?? 0,
      etaSeconds: json['eta'] as int?,
      uploadRatio: (json['uploadRatio'] as num? ?? 0).toDouble(),
      peersConnected: json['peersConnected'] as int? ?? 0,
      peersSendingToUs: json['peersSendingToUs'] as int? ?? 0,
      peersGettingFromUs: json['peersGettingFromUs'] as int? ?? 0,
      downloadDir: json['downloadDir'] as String?,
      trackers: trackerItems,
      errorCode: json['error'] as int? ?? 0,
      errorMessage: json['errorString'] as String? ?? '',
      addedDate: _timestamp(json['addedDate']),
      doneDate: _timestamp(json['doneDate']),
      activityDate: _timestamp(json['activityDate']),
      bandwidthPriority: BandwidthPriority.fromRpcValue(
        json['bandwidthPriority'] as int? ?? 0,
      ),
      queuePosition: json['queuePosition'] as int? ?? 0,
      isFinished: json['isFinished'] as bool? ?? false,
      downloadedEver: json['downloadedEver'] as int? ?? 0,
      uploadedEver: json['uploadedEver'] as int? ?? 0,
      secondsDownloading: json['secondsDownloading'] as int? ?? 0,
      secondsSeeding: json['secondsSeeding'] as int? ?? 0,
      files: fileEntries,
      peers: peerEntries,
      comment: json['comment'] as String? ?? '',
      creator: json['creator'] as String? ?? '',
      dateCreated: _timestamp(json['dateCreated']),
      magnetLink: json['magnetLink'] as String? ?? '',
    );
  }

  static String primaryTrackerLabel(Torrent torrent) {
    final trackers = [...torrent.trackers];
    trackers.sort((a, b) {
      final tierCompare = a.tier.compareTo(b.tier);
      if (tierCompare != 0) {
        return tierCompare;
      }
      return a.id.compareTo(b.id);
    });
    if (trackers.isEmpty) {
      return 'No Tracker';
    }
    final tracker = trackers.first;
    final label = _normalizeTrackerHost(
      tracker.host.isNotEmpty ? tracker.host : tracker.displayLabel,
    );
    return label.isEmpty ? 'Unknown Tracker' : label;
  }

  static String normalizeTrackerLabel(String value) =>
      _normalizeTrackerHost(value);

  static List<TorrentFileEntry> parseFiles(Map<String, dynamic> json) {
    final files = (json['files'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final fileStats = (json['fileStats'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final fileEntries = <TorrentFileEntry>[];
    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final stat = index < fileStats.length
          ? fileStats[index]
          : const <String, dynamic>{};
      fileEntries.add(
        TorrentFileEntry(
          index: index,
          name: file['name'] as String? ?? 'File ${index + 1}',
          length: file['length'] as int? ?? 0,
          bytesCompleted: file['bytesCompleted'] as int? ?? 0,
          wanted: stat['wanted'] as bool? ?? true,
          priority: BandwidthPriority.fromRpcValue(
            stat['priority'] as int? ?? 0,
          ),
        ),
      );
    }
    return fileEntries;
  }

  static List<TorrentPeer> parsePeers(Map<String, dynamic> json) {
    return (json['peers'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (peer) => TorrentPeer(
            address: peer['address'] as String? ?? '',
            clientName: peer['clientName'] as String? ?? '',
            progress: (peer['progress'] as num? ?? 0).toDouble(),
            rateToClient: peer['rateToClient'] as int? ?? 0,
            rateToPeer: peer['rateToPeer'] as int? ?? 0,
            flags: peer['flagStr'] as String? ?? '',
          ),
        )
        .toList();
  }

  static TorrentStatus _statusFromValue(int status) {
    return switch (status) {
      1 => TorrentStatus.queuedForVerification,
      2 => TorrentStatus.verifying,
      3 => TorrentStatus.queuedForDownload,
      4 => TorrentStatus.downloading,
      5 => TorrentStatus.queuedForSeed,
      6 => TorrentStatus.seeding,
      _ => TorrentStatus.stopped,
    };
  }

  static DateTime? _timestamp(Object? value) {
    final seconds = value as int?;
    if (seconds == null || seconds <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  static String _normalizeTrackerHost(String raw) {
    if (raw.isEmpty) {
      return '';
    }
    try {
      final uri = Uri.tryParse(raw);
      final host = uri?.host;
      if (host != null && host.isNotEmpty) {
        return host.toLowerCase();
      }
    } catch (_) {
      // Ignore parse errors and fall back below.
    }
    return raw
        .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
        .split('/')
        .first
        .toLowerCase();
  }
}
