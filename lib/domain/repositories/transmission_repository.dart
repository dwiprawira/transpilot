import '../entities/server_profile.dart';
import '../entities/session_models.dart';
import '../entities/torrent.dart';

enum QueueMoveDirection { top, up, down, bottom }

class AddTorrentResult {
  const AddTorrentResult({
    required this.isDuplicate,
    required this.name,
    this.id,
  });

  final bool isDuplicate;
  final String name;
  final int? id;
}

abstract class TransmissionRepository {
  ServerProfile get profile;

  Future<void> testConnection();
  Future<List<Torrent>> getTorrents();
  Future<Torrent?> getTorrentDetail(int id);
  Future<List<TorrentFileEntry>> getTorrentFiles(int id);
  Future<List<TorrentPeer>> getTorrentPeers(int id);
  Future<SessionInfo> getSessionInfo();
  Future<void> updateSessionInfo(SessionInfo sessionInfo);
  Future<SessionStats> getSessionStats();
  Future<FreeSpaceInfo> getFreeSpace(String path);
  Future<AddTorrentResult> addTorrent({
    String? magnetLink,
    List<int>? metainfo,
    String? downloadDir,
    bool paused = false,
    BandwidthPriority priority = BandwidthPriority.normal,
  });
  Future<void> startTorrents(List<int> ids, {bool bypassQueue = false});
  Future<void> stopTorrents(List<int> ids);
  Future<void> verifyTorrents(List<int> ids);
  Future<void> reannounceTorrents(List<int> ids);
  Future<void> removeTorrents(List<int> ids, {bool deleteLocalData = false});
  Future<void> setBandwidthPriority(List<int> ids, BandwidthPriority priority);
  Future<void> setFilesWanted(
    int torrentId, {
    required List<int> wanted,
    required List<int> unwanted,
  });
  Future<void> setFilePriority(
    int torrentId, {
    required List<int> high,
    required List<int> normal,
    required List<int> low,
  });
  Future<void> moveQueue(List<int> ids, QueueMoveDirection direction);
  Future<void> renamePath({
    required int torrentId,
    required String path,
    required String name,
  });
  Future<void> moveData({
    required List<int> ids,
    required String location,
    bool move = true,
  });
}
