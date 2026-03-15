import '../../data/dto/torrent_dto.dart';
import '../../domain/entities/app_preferences.dart';
import '../../domain/entities/torrent.dart';

class TorrentGroup {
  const TorrentGroup({
    required this.key,
    required this.title,
    required this.torrents,
  });

  final String key;
  final String title;
  final List<Torrent> torrents;

  int get totalSize =>
      torrents.fold(0, (sum, torrent) => sum + torrent.totalSize);
  int get totalDownloadSpeed =>
      torrents.fold(0, (sum, torrent) => sum + torrent.rateDownload);
  int get totalUploadSpeed =>
      torrents.fold(0, (sum, torrent) => sum + torrent.rateUpload);
}

class TorrentListLogic {
  static List<Torrent> filterAndSort({
    required List<Torrent> torrents,
    required String searchQuery,
    required TorrentFilter filter,
    required TorrentSortField sortField,
    required bool sortAscending,
  }) {
    final query = searchQuery.trim().toLowerCase();
    final filtered = torrents.where((torrent) {
      if (query.isNotEmpty) {
        final searchable = [
          torrent.name,
          torrent.downloadDir ?? '',
          TorrentDto.primaryTrackerLabel(torrent),
          torrent.errorMessage,
        ].join(' ').toLowerCase();
        if (!searchable.contains(query)) {
          return false;
        }
      }
      return _matchesFilter(torrent, filter);
    }).toList();

    filtered.sort((a, b) => _compare(a, b, sortField, sortAscending));
    return filtered;
  }

  static List<TorrentGroup> group(
    List<Torrent> torrents,
    TorrentGroupingMode mode,
  ) {
    if (mode == TorrentGroupingMode.flat) {
      return [
        TorrentGroup(key: 'flat', title: 'All Torrents', torrents: torrents),
      ];
    }

    final groups = <String, List<Torrent>>{};
    for (final torrent in torrents) {
      final key = switch (mode) {
        TorrentGroupingMode.downloadPath =>
          (torrent.downloadDir == null || torrent.downloadDir!.trim().isEmpty)
              ? 'Unknown Path'
              : torrent.downloadDir!.trim(),
        TorrentGroupingMode.tracker => TorrentDto.primaryTrackerLabel(torrent),
        TorrentGroupingMode.flat => 'All Torrents',
      };
      groups.putIfAbsent(key, () => []).add(torrent);
    }

    final entries = groups.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return entries
        .map(
          (entry) => TorrentGroup(
            key: entry.key,
            title: entry.key,
            torrents: entry.value,
          ),
        )
        .toList();
  }

  static bool _matchesFilter(Torrent torrent, TorrentFilter filter) {
    switch (filter) {
      case TorrentFilter.all:
        return true;
      case TorrentFilter.active:
        return torrent.isActive;
      case TorrentFilter.downloading:
        return torrent.status == TorrentStatus.downloading ||
            torrent.status == TorrentStatus.queuedForDownload;
      case TorrentFilter.seeding:
        return torrent.status == TorrentStatus.seeding ||
            torrent.status == TorrentStatus.queuedForSeed;
      case TorrentFilter.paused:
        return torrent.status == TorrentStatus.stopped;
      case TorrentFilter.checking:
        return torrent.status == TorrentStatus.verifying ||
            torrent.status == TorrentStatus.queuedForVerification;
      case TorrentFilter.error:
        return torrent.hasError;
    }
  }

  static int _compare(
    Torrent a,
    Torrent b,
    TorrentSortField sortField,
    bool sortAscending,
  ) {
    final factor = sortAscending ? 1 : -1;
    final result = switch (sortField) {
      TorrentSortField.name => a.name.toLowerCase().compareTo(
        b.name.toLowerCase(),
      ),
      TorrentSortField.progress => a.effectiveProgress.compareTo(
        b.effectiveProgress,
      ),
      TorrentSortField.addedDate =>
        (a.addedDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          b.addedDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      TorrentSortField.downloadSpeed => a.rateDownload.compareTo(
        b.rateDownload,
      ),
      TorrentSortField.uploadSpeed => a.rateUpload.compareTo(b.rateUpload),
    };
    if (result != 0) {
      return result * factor;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
