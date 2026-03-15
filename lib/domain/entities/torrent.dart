enum TorrentStatus {
  stopped,
  queuedForVerification,
  verifying,
  queuedForDownload,
  downloading,
  queuedForSeed,
  seeding,
}

enum BandwidthPriority {
  low(-1),
  normal(0),
  high(1);

  const BandwidthPriority(this.rpcValue);
  final int rpcValue;

  static BandwidthPriority fromRpcValue(int value) {
    if (value <= -1) {
      return BandwidthPriority.low;
    }
    if (value >= 1) {
      return BandwidthPriority.high;
    }
    return BandwidthPriority.normal;
  }
}

class TorrentTracker {
  const TorrentTracker({
    required this.id,
    required this.announce,
    required this.host,
    required this.siteName,
    required this.tier,
    required this.lastAnnounceResult,
    required this.lastAnnounceSucceeded,
  });

  final int id;
  final String announce;
  final String host;
  final String siteName;
  final int tier;
  final String lastAnnounceResult;
  final bool lastAnnounceSucceeded;

  String get displayLabel {
    if (host.isNotEmpty) {
      return host;
    }
    if (siteName.isNotEmpty) {
      return siteName;
    }
    return announce;
  }
}

class TorrentPeer {
  const TorrentPeer({
    required this.address,
    required this.clientName,
    required this.progress,
    required this.rateToClient,
    required this.rateToPeer,
    required this.flags,
  });

  final String address;
  final String clientName;
  final double progress;
  final int rateToClient;
  final int rateToPeer;
  final String flags;
}

class TorrentFileEntry {
  const TorrentFileEntry({
    required this.index,
    required this.name,
    required this.length,
    required this.bytesCompleted,
    required this.wanted,
    required this.priority,
  });

  final int index;
  final String name;
  final int length;
  final int bytesCompleted;
  final bool wanted;
  final BandwidthPriority priority;

  double get progress => length == 0 ? 0 : bytesCompleted / length;
}

class Torrent {
  const Torrent({
    required this.id,
    required this.hashString,
    required this.name,
    required this.status,
    required this.percentDone,
    required this.metadataPercentComplete,
    required this.totalSize,
    required this.sizeWhenDone,
    required this.rateDownload,
    required this.rateUpload,
    required this.etaSeconds,
    required this.uploadRatio,
    required this.peersConnected,
    required this.peersSendingToUs,
    required this.peersGettingFromUs,
    required this.downloadDir,
    required this.trackers,
    required this.errorCode,
    required this.errorMessage,
    required this.addedDate,
    required this.doneDate,
    required this.activityDate,
    required this.bandwidthPriority,
    required this.queuePosition,
    required this.isFinished,
    required this.downloadedEver,
    required this.uploadedEver,
    required this.secondsDownloading,
    required this.secondsSeeding,
    required this.files,
    required this.peers,
    required this.comment,
    required this.creator,
    required this.dateCreated,
    required this.magnetLink,
  });

  final int id;
  final String hashString;
  final String name;
  final TorrentStatus status;
  final double percentDone;
  final double metadataPercentComplete;
  final int totalSize;
  final int sizeWhenDone;
  final int rateDownload;
  final int rateUpload;
  final int? etaSeconds;
  final double uploadRatio;
  final int peersConnected;
  final int peersSendingToUs;
  final int peersGettingFromUs;
  final String? downloadDir;
  final List<TorrentTracker> trackers;
  final int errorCode;
  final String errorMessage;
  final DateTime? addedDate;
  final DateTime? doneDate;
  final DateTime? activityDate;
  final BandwidthPriority bandwidthPriority;
  final int queuePosition;
  final bool isFinished;
  final int downloadedEver;
  final int uploadedEver;
  final int secondsDownloading;
  final int secondsSeeding;
  final List<TorrentFileEntry> files;
  final List<TorrentPeer> peers;
  final String comment;
  final String creator;
  final DateTime? dateCreated;
  final String magnetLink;

  bool get hasError => errorCode != 0 || errorMessage.isNotEmpty;

  bool get isActive => rateDownload > 0 || rateUpload > 0;

  double get effectiveProgress =>
      metadataPercentComplete < 1 ? metadataPercentComplete : percentDone;
}
