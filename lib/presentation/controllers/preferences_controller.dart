import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../app/providers.dart';

class PreferencesController extends StateNotifier<AsyncValue<AppPreferences>> {
  PreferencesController(this._repository) : super(const AsyncLoading()) {
    _load();
  }

  final PreferencesRepository _repository;

  Future<void> _load() async {
    try {
      final preferences = await _repository.load();
      state = AsyncData(preferences);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> _save(AppPreferences preferences) async {
    state = AsyncData(preferences);
    await _repository.save(preferences);
  }

  AppPreferences get _current => state.valueOrNull ?? AppPreferences.defaults();

  Future<void> updateThemeMode(ThemeMode themeMode) {
    return _save(_current.copyWith(themeMode: themeMode));
  }

  Future<void> updateRefreshInterval(Duration refreshInterval) {
    return _save(_current.copyWith(refreshInterval: refreshInterval));
  }

  Future<void> updateGroupingMode(TorrentGroupingMode groupingMode) {
    return _save(_current.copyWith(groupingMode: groupingMode));
  }

  Future<void> updateSort(TorrentSortField sortField, bool sortAscending) {
    return _save(
      _current.copyWith(sortField: sortField, sortAscending: sortAscending),
    );
  }

  Future<void> updateFilter(TorrentFilter filter) {
    return _save(_current.copyWith(filter: filter));
  }

  Future<void> updateViewMode(TorrentListViewMode viewMode) {
    return _save(_current.copyWith(viewMode: viewMode));
  }

  Future<void> setGroupCollapsed({
    required TorrentGroupingMode groupingMode,
    required String groupKey,
    required bool isCollapsed,
  }) {
    final collapsedPathGroups = {..._current.collapsedPathGroups};
    final collapsedTrackerGroups = {..._current.collapsedTrackerGroups};
    final target = groupingMode == TorrentGroupingMode.downloadPath
        ? collapsedPathGroups
        : collapsedTrackerGroups;
    if (isCollapsed) {
      target.add(groupKey);
    } else {
      target.remove(groupKey);
    }
    return _save(
      _current.copyWith(
        collapsedPathGroups: collapsedPathGroups,
        collapsedTrackerGroups: collapsedTrackerGroups,
      ),
    );
  }
}

final preferencesControllerProvider =
    StateNotifierProvider<PreferencesController, AsyncValue<AppPreferences>>(
      (ref) => PreferencesController(ref.watch(preferencesRepositoryProvider)),
    );
