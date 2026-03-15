import 'package:flutter/material.dart';

enum TorrentGroupingMode { flat, downloadPath, tracker }

enum TorrentSortField { name, progress, addedDate, downloadSpeed, uploadSpeed }

enum TorrentFilter {
  all,
  active,
  downloading,
  seeding,
  paused,
  checking,
  error,
}

enum TorrentListViewMode { compact }

extension TorrentGroupingModeX on TorrentGroupingMode {
  String get label {
    switch (this) {
      case TorrentGroupingMode.flat:
        return 'Flat List';
      case TorrentGroupingMode.downloadPath:
        return 'Download Path';
      case TorrentGroupingMode.tracker:
        return 'Tracker';
    }
  }
}

extension TorrentSortFieldX on TorrentSortField {
  String get label {
    switch (this) {
      case TorrentSortField.name:
        return 'Name';
      case TorrentSortField.progress:
        return 'Progress';
      case TorrentSortField.addedDate:
        return 'Added Date';
      case TorrentSortField.downloadSpeed:
        return 'Download Speed';
      case TorrentSortField.uploadSpeed:
        return 'Upload Speed';
    }
  }
}

extension TorrentFilterX on TorrentFilter {
  String get label {
    switch (this) {
      case TorrentFilter.all:
        return 'All';
      case TorrentFilter.active:
        return 'Active';
      case TorrentFilter.downloading:
        return 'Downloading';
      case TorrentFilter.seeding:
        return 'Seeding';
      case TorrentFilter.paused:
        return 'Paused';
      case TorrentFilter.checking:
        return 'Checking';
      case TorrentFilter.error:
        return 'Error';
    }
  }
}

extension TorrentListViewModeX on TorrentListViewMode {
  String get label {
    switch (this) {
      case TorrentListViewMode.compact:
        return 'Compact';
    }
  }
}

class AppPreferences {
  const AppPreferences({
    required this.refreshInterval,
    required this.themeMode,
    required this.groupingMode,
    required this.sortField,
    required this.sortAscending,
    required this.filter,
    required this.viewMode,
    required this.collapsedPathGroups,
    required this.collapsedTrackerGroups,
  });

  final Duration refreshInterval;
  final ThemeMode themeMode;
  final TorrentGroupingMode groupingMode;
  final TorrentSortField sortField;
  final bool sortAscending;
  final TorrentFilter filter;
  final TorrentListViewMode viewMode;
  final Set<String> collapsedPathGroups;
  final Set<String> collapsedTrackerGroups;

  factory AppPreferences.defaults() {
    return const AppPreferences(
      refreshInterval: Duration(seconds: 10),
      themeMode: ThemeMode.system,
      groupingMode: TorrentGroupingMode.flat,
      sortField: TorrentSortField.addedDate,
      sortAscending: false,
      filter: TorrentFilter.all,
      viewMode: TorrentListViewMode.compact,
      collapsedPathGroups: <String>{},
      collapsedTrackerGroups: <String>{},
    );
  }

  AppPreferences copyWith({
    Duration? refreshInterval,
    ThemeMode? themeMode,
    TorrentGroupingMode? groupingMode,
    TorrentSortField? sortField,
    bool? sortAscending,
    TorrentFilter? filter,
    TorrentListViewMode? viewMode,
    Set<String>? collapsedPathGroups,
    Set<String>? collapsedTrackerGroups,
  }) {
    return AppPreferences(
      refreshInterval: refreshInterval ?? this.refreshInterval,
      themeMode: themeMode ?? this.themeMode,
      groupingMode: groupingMode ?? this.groupingMode,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      filter: filter ?? this.filter,
      viewMode: viewMode ?? this.viewMode,
      collapsedPathGroups: collapsedPathGroups ?? this.collapsedPathGroups,
      collapsedTrackerGroups:
          collapsedTrackerGroups ?? this.collapsedTrackerGroups,
    );
  }
}
