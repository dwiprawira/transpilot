import 'package:flutter_test/flutter_test.dart';
import 'package:transpilot/data/dto/torrent_dto.dart';
import 'package:transpilot/domain/entities/torrent.dart';

void main() {
  test('parses a torrent payload into a resilient domain model', () {
    final torrent = TorrentDto({
      'id': 42,
      'hashString': 'hash',
      'name': 'Ubuntu ISO',
      'status': 4,
      'percentDone': 0.75,
      'metadataPercentComplete': 1.0,
      'totalSize': 1024,
      'sizeWhenDone': 1024,
      'rateDownload': 512,
      'rateUpload': 256,
      'eta': 120,
      'uploadRatio': 1.5,
      'peersConnected': 10,
      'peersSendingToUs': 4,
      'peersGettingFromUs': 3,
      'downloadDir': '/downloads/linux',
      'error': 0,
      'errorString': '',
      'addedDate': 1700000000,
      'doneDate': 1700001000,
      'activityDate': 1700002000,
      'bandwidthPriority': 1,
      'queuePosition': 3,
      'isFinished': false,
      'downloadedEver': 900,
      'uploadedEver': 100,
      'secondsDownloading': 45,
      'secondsSeeding': 0,
      'comment': 'LTS release',
      'creator': 'Transmission',
      'dateCreated': 1699999999,
      'magnetLink': 'magnet:?xt=urn:btih:hash',
      'trackers': [
        {
          'id': 1,
          'announce': 'https://tracker.example.com/announce',
          'tier': 0,
          'sitename': 'Example',
        },
      ],
      'trackerStats': [
        {
          'id': 1,
          'host': 'tracker.example.com',
          'tier': 0,
          'lastAnnounceResult': 'Success',
          'lastAnnounceSucceeded': true,
        },
      ],
      'files': [
        {'name': 'ubuntu.iso', 'length': 1024, 'bytesCompleted': 768},
      ],
      'fileStats': [
        {'wanted': true, 'priority': 1},
      ],
      'peers': [
        {
          'address': '1.1.1.1',
          'clientName': 'Transmission',
          'progress': 0.5,
          'rateToClient': 100,
          'rateToPeer': 50,
          'flagStr': 'D',
        },
      ],
    }).toDomain();

    expect(torrent.id, 42);
    expect(torrent.status, TorrentStatus.downloading);
    expect(torrent.files.single.name, 'ubuntu.iso');
    expect(torrent.files.single.priority, BandwidthPriority.high);
    expect(torrent.trackers.single.host, 'tracker.example.com');
    expect(torrent.peers.single.clientName, 'Transmission');
    expect(TorrentDto.primaryTrackerLabel(torrent), 'tracker.example.com');
  });

  test(
    'normalizes trackers and chooses the lowest tier as the primary label',
    () {
      final torrent = Torrent(
        id: 1,
        hashString: 'hash',
        name: 'Movie',
        status: TorrentStatus.seeding,
        percentDone: 1,
        metadataPercentComplete: 1,
        totalSize: 100,
        sizeWhenDone: 100,
        rateDownload: 0,
        rateUpload: 0,
        etaSeconds: null,
        uploadRatio: 2,
        peersConnected: 0,
        peersSendingToUs: 0,
        peersGettingFromUs: 0,
        downloadDir: '/downloads',
        trackers: const [
          TorrentTracker(
            id: 2,
            announce: 'https://b.example.net/announce',
            host: 'b.example.net',
            siteName: '',
            tier: 1,
            lastAnnounceResult: '',
            lastAnnounceSucceeded: false,
          ),
          TorrentTracker(
            id: 1,
            announce: 'https://A.Example.com/announce',
            host: 'A.Example.com',
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
        isFinished: true,
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

      expect(TorrentDto.primaryTrackerLabel(torrent), 'a.example.com');
      expect(
        TorrentDto.normalizeTrackerLabel('https://TRACKER.example.com/path'),
        'tracker.example.com',
      );
    },
  );
}
