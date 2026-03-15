import 'package:flutter_test/flutter_test.dart';
import 'package:transpilot/domain/entities/app_preferences.dart';
import 'package:transpilot/domain/entities/torrent.dart';
import 'package:transpilot/shared/logic/torrent_list_logic.dart';

void main() {
  group('TorrentListLogic', () {
    final downloading = _torrent(
      id: 1,
      name: 'Alpha',
      status: TorrentStatus.downloading,
      downloadDir: '/downloads/a',
      rateDownload: 100,
      percentDone: 0.2,
      trackers: const [
        TorrentTracker(
          id: 1,
          announce: 'https://tracker.one/announce',
          host: 'tracker.one',
          siteName: '',
          tier: 0,
          lastAnnounceResult: '',
          lastAnnounceSucceeded: false,
        ),
      ],
    );
    final seeding = _torrent(
      id: 2,
      name: 'Beta',
      status: TorrentStatus.seeding,
      downloadDir: '/downloads/b',
      rateUpload: 50,
      percentDone: 1,
      trackers: const [
        TorrentTracker(
          id: 2,
          announce: 'https://tracker.two/announce',
          host: 'tracker.two',
          siteName: '',
          tier: 0,
          lastAnnounceResult: '',
          lastAnnounceSucceeded: false,
        ),
      ],
    );
    final unknown = _torrent(
      id: 3,
      name: 'Gamma',
      status: TorrentStatus.stopped,
      downloadDir: null,
      errorMessage: 'Tracker unreachable',
      trackers: const [],
    );

    test('groups by download path with an unknown path bucket', () {
      final groups = TorrentListLogic.group([
        downloading,
        seeding,
        unknown,
      ], TorrentGroupingMode.downloadPath);

      expect(
        groups.map((group) => group.title),
        containsAll(<String>['/downloads/a', '/downloads/b', 'Unknown Path']),
      );
    });

    test('groups by tracker with deterministic labels', () {
      final groups = TorrentListLogic.group([
        downloading,
        seeding,
        unknown,
      ], TorrentGroupingMode.tracker);

      expect(groups.map((group) => group.title), contains('tracker.one'));
      expect(groups.map((group) => group.title), contains('tracker.two'));
      expect(groups.map((group) => group.title), contains('No Tracker'));
    });

    test('filters and sorts torrents consistently', () {
      final visible = TorrentListLogic.filterAndSort(
        torrents: [unknown, seeding, downloading],
        searchQuery: 'a',
        filter: TorrentFilter.all,
        sortField: TorrentSortField.name,
        sortAscending: true,
      );

      expect(visible.map((torrent) => torrent.name), [
        'Alpha',
        'Beta',
        'Gamma',
      ]);

      final downloadingOnly = TorrentListLogic.filterAndSort(
        torrents: [unknown, seeding, downloading],
        searchQuery: '',
        filter: TorrentFilter.downloading,
        sortField: TorrentSortField.progress,
        sortAscending: false,
      );

      expect(downloadingOnly.single.id, downloading.id);
    });
  });
}

Torrent _torrent({
  required int id,
  required String name,
  required TorrentStatus status,
  String? downloadDir,
  int rateDownload = 0,
  int rateUpload = 0,
  double percentDone = 0,
  String errorMessage = '',
  List<TorrentTracker> trackers = const [],
}) {
  return Torrent(
    id: id,
    hashString: '$id-hash',
    name: name,
    status: status,
    percentDone: percentDone,
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
    downloadDir: downloadDir,
    trackers: trackers,
    errorCode: errorMessage.isEmpty ? 0 : 1,
    errorMessage: errorMessage,
    addedDate: null,
    doneDate: null,
    activityDate: null,
    bandwidthPriority: BandwidthPriority.normal,
    queuePosition: 0,
    isFinished: status == TorrentStatus.seeding,
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
