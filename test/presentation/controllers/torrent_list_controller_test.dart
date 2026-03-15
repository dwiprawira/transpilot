import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transpilot/core/logging/app_logger.dart';
import 'package:transpilot/domain/entities/app_preferences.dart';
import 'package:transpilot/domain/entities/server_profile.dart';
import 'package:transpilot/domain/entities/session_models.dart';
import 'package:transpilot/domain/entities/torrent.dart';
import 'package:transpilot/domain/repositories/preferences_repository.dart';
import 'package:transpilot/domain/repositories/profile_repository.dart';
import 'package:transpilot/domain/repositories/transmission_repository.dart';
import 'package:transpilot/presentation/app/providers.dart';
import 'package:transpilot/presentation/controllers/preferences_controller.dart';
import 'package:transpilot/presentation/controllers/profiles_controller.dart';
import 'package:transpilot/presentation/controllers/torrent_list_controller.dart';

void main() {
  test(
    'refreshes torrents from the active profile and applies persisted preferences',
    () async {
      final profile = const ServerProfile(
        id: 'server-1',
        name: 'Home NAS',
        host: 'localhost',
        port: 9091,
        rpcPath: '/transmission/rpc',
        useHttps: false,
        allowInvalidCertificate: false,
        username: '',
        password: '',
      );
      final fakePreferencesRepository = _FakePreferencesRepository(
        AppPreferences.defaults().copyWith(
          themeMode: ThemeMode.dark,
          groupingMode: TorrentGroupingMode.tracker,
          filter: TorrentFilter.active,
          viewMode: TorrentListViewMode.compact,
        ),
      );
      final fakeProfileRepository = _FakeProfileRepository(
        profiles: [profile],
        activeProfileId: profile.id,
      );
      final fakeTransmissionRepository = _FakeTransmissionRepository(profile, [
        _buildTorrent(id: 1, name: 'Alpha', rateDownload: 100),
        _buildTorrent(id: 2, name: 'Beta', rateUpload: 25),
      ]);

      final container = ProviderContainer(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(
            fakePreferencesRepository,
          ),
          profileRepositoryProvider.overrideWithValue(fakeProfileRepository),
          transmissionRepositoryFactoryProvider.overrideWithValue(
            _FakeTransmissionRepositoryFactory(fakeTransmissionRepository),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(preferencesControllerProvider);
      await _flushMicrotasks();
      container.read(profilesControllerProvider);
      await _flushMicrotasks();

      final controller = container.read(torrentListControllerProvider.notifier);
      await controller.refresh(forceLoading: true);

      final state = container.read(torrentListControllerProvider);
      expect(state.isConfigured, isTrue);
      expect(state.groupingMode, TorrentGroupingMode.tracker);
      expect(state.filter, TorrentFilter.active);
      expect(state.viewMode, TorrentListViewMode.compact);
      expect(state.torrents, hasLength(2));
      expect(state.visibleTorrents, hasLength(2));
      expect(state.selectedTorrentId, 1);
    },
  );
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakePreferencesRepository implements PreferencesRepository {
  _FakePreferencesRepository(this.preferences);

  AppPreferences preferences;

  @override
  Future<AppPreferences> load() async => preferences;

  @override
  Future<void> save(AppPreferences nextPreferences) async {
    preferences = nextPreferences;
  }
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({
    required this.profiles,
    required this.activeProfileId,
  });

  final List<ServerProfile> profiles;
  String? activeProfileId;

  @override
  Future<void> deleteProfile(String profileId) async {}

  @override
  Future<String?> loadActiveProfileId() async => activeProfileId;

  @override
  Future<List<ServerProfile>> loadProfiles() async => profiles;

  @override
  Future<void> saveActiveProfileId(String? profileId) async {
    activeProfileId = profileId;
  }

  @override
  Future<void> saveProfile(ServerProfile profile) async {}
}

class _FakeTransmissionRepositoryFactory extends TransmissionRepositoryFactory {
  _FakeTransmissionRepositoryFactory(this.repository) : super(AppLogger());

  final TransmissionRepository repository;

  @override
  TransmissionRepository create(ServerProfile profile) => repository;
}

class _FakeTransmissionRepository implements TransmissionRepository {
  _FakeTransmissionRepository(this.profile, this.torrents);

  @override
  final ServerProfile profile;

  final List<Torrent> torrents;

  @override
  Future<AddTorrentResult> addTorrent({
    String? magnetLink,
    List<int>? metainfo,
    String? downloadDir,
    bool paused = false,
    BandwidthPriority priority = BandwidthPriority.normal,
  }) async {
    return const AddTorrentResult(isDuplicate: false, name: 'Added');
  }

  @override
  Future<FreeSpaceInfo> getFreeSpace(String path) async =>
      FreeSpaceInfo(path: path, sizeBytes: 1000);

  @override
  Future<SessionInfo> getSessionInfo() async => const SessionInfo(
    version: '4.0.0',
    rpcVersion: 17,
    rpcVersionMinimum: 15,
    downloadDir: '/downloads',
    altSpeedEnabled: false,
    altSpeedUp: 0,
    altSpeedDown: 0,
    speedLimitUp: 0,
    speedLimitDown: 0,
    speedLimitUpEnabled: false,
    speedLimitDownEnabled: false,
    encryptionMode: EncryptionMode.preferred,
    downloadQueueEnabled: true,
    downloadQueueSize: 5,
    seedQueueEnabled: true,
    seedQueueSize: 5,
    queueStalledEnabled: true,
    queueStalledMinutes: 30,
    startAddedTorrents: true,
  );

  @override
  Future<SessionStats> getSessionStats() async => const SessionStats(
    activeTorrentCount: 1,
    downloadSpeed: 100,
    uploadSpeed: 20,
    pausedTorrentCount: 0,
    torrentCount: 2,
    cumulativeDownloadedBytes: 1000,
    cumulativeUploadedBytes: 200,
    filesAdded: 2,
    sessionCount: 1,
  );

  @override
  Future<Torrent?> getTorrentDetail(int id) async =>
      torrents.firstWhere((torrent) => torrent.id == id);

  @override
  Future<List<TorrentFileEntry>> getTorrentFiles(int id) async =>
      torrents.firstWhere((torrent) => torrent.id == id).files;

  @override
  Future<List<TorrentPeer>> getTorrentPeers(int id) async =>
      torrents.firstWhere((torrent) => torrent.id == id).peers;

  @override
  Future<List<Torrent>> getTorrents() async => torrents;

  @override
  Future<void> moveData({
    required List<int> ids,
    required String location,
    bool move = true,
  }) async {}

  @override
  Future<void> moveQueue(List<int> ids, QueueMoveDirection direction) async {}

  @override
  Future<void> reannounceTorrents(List<int> ids) async {}

  @override
  Future<void> removeTorrents(
    List<int> ids, {
    bool deleteLocalData = false,
  }) async {}

  @override
  Future<void> renamePath({
    required int torrentId,
    required String path,
    required String name,
  }) async {}

  @override
  Future<void> setBandwidthPriority(
    List<int> ids,
    BandwidthPriority priority,
  ) async {}

  @override
  Future<void> setFilePriority(
    int torrentId, {
    required List<int> high,
    required List<int> normal,
    required List<int> low,
  }) async {}

  @override
  Future<void> setFilesWanted(
    int torrentId, {
    required List<int> wanted,
    required List<int> unwanted,
  }) async {}

  @override
  Future<void> startTorrents(List<int> ids, {bool bypassQueue = false}) async {}

  @override
  Future<void> stopTorrents(List<int> ids) async {}

  @override
  Future<void> testConnection() async {}

  @override
  Future<void> updateSessionInfo(SessionInfo sessionInfo) async {}

  @override
  Future<void> verifyTorrents(List<int> ids) async {}
}

Torrent _buildTorrent({
  required int id,
  required String name,
  int rateDownload = 0,
  int rateUpload = 0,
}) {
  return Torrent(
    id: id,
    hashString: '$id-hash',
    name: name,
    status: rateDownload > 0
        ? TorrentStatus.downloading
        : TorrentStatus.seeding,
    percentDone: rateDownload > 0 ? 0.5 : 1,
    metadataPercentComplete: 1,
    totalSize: 100,
    sizeWhenDone: 100,
    rateDownload: rateDownload,
    rateUpload: rateUpload,
    etaSeconds: null,
    uploadRatio: 0,
    peersConnected: 0,
    peersSendingToUs: 0,
    peersGettingFromUs: 0,
    downloadDir: '/downloads',
    trackers: const [
      TorrentTracker(
        id: 1,
        announce: 'https://tracker.example.com/announce',
        host: 'tracker.example.com',
        siteName: '',
        tier: 0,
        lastAnnounceResult: '',
        lastAnnounceSucceeded: false,
      ),
    ],
    errorCode: 0,
    errorMessage: '',
    addedDate: null,
    doneDate: null,
    activityDate: null,
    bandwidthPriority: BandwidthPriority.normal,
    queuePosition: 0,
    isFinished: rateDownload == 0,
    downloadedEver: 0,
    uploadedEver: 0,
    secondsDownloading: 0,
    secondsSeeding: 0,
    files: const [],
    peers: const [],
    comment: '',
    creator: '',
    dateCreated: null,
    magnetLink: '',
  );
}
