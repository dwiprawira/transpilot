import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_preferences.dart';

class PreferencesStorage {
  PreferencesStorage(this._sharedPreferences);

  static const _preferencesKey = 'app_preferences_v1';

  final SharedPreferences _sharedPreferences;

  TorrentListViewMode _parseViewMode(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'comfortable') {
      return TorrentListViewMode.compact;
    }
    return TorrentListViewMode.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => TorrentListViewMode.compact,
    );
  }

  AppPreferences load() {
    final raw = _sharedPreferences.getString(_preferencesKey);
    if (raw == null || raw.isEmpty) {
      return AppPreferences.defaults();
    }

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AppPreferences(
      refreshInterval: Duration(
        seconds: json['refreshIntervalSeconds'] as int? ?? 10,
      ),
      themeMode: ThemeMode.values.byName(
        json['themeMode'] as String? ?? ThemeMode.system.name,
      ),
      groupingMode: TorrentGroupingMode.values.byName(
        json['groupingMode'] as String? ?? TorrentGroupingMode.flat.name,
      ),
      sortField: TorrentSortField.values.byName(
        json['sortField'] as String? ?? TorrentSortField.addedDate.name,
      ),
      sortAscending: json['sortAscending'] as bool? ?? false,
      filter: TorrentFilter.values.byName(
        json['filter'] as String? ?? TorrentFilter.all.name,
      ),
      viewMode: _parseViewMode(json['viewMode'] as String?),
      collapsedPathGroups:
          (json['collapsedPathGroups'] as List<dynamic>? ?? const <dynamic>[])
              .map((value) => value.toString())
              .toSet(),
      collapsedTrackerGroups:
          (json['collapsedTrackerGroups'] as List<dynamic>? ??
                  const <dynamic>[])
              .map((value) => value.toString())
              .toSet(),
    );
  }

  Future<void> save(AppPreferences preferences) {
    return _sharedPreferences.setString(
      _preferencesKey,
      jsonEncode({
        'refreshIntervalSeconds': preferences.refreshInterval.inSeconds,
        'themeMode': preferences.themeMode.name,
        'groupingMode': preferences.groupingMode.name,
        'sortField': preferences.sortField.name,
        'sortAscending': preferences.sortAscending,
        'filter': preferences.filter.name,
        'viewMode': preferences.viewMode.name,
        'collapsedPathGroups': preferences.collapsedPathGroups.toList(),
        'collapsedTrackerGroups': preferences.collapsedTrackerGroups.toList(),
      }),
    );
  }
}
