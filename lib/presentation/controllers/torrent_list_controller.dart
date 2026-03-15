import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_preferences.dart';
import '../../domain/entities/server_profile.dart';
import '../../domain/entities/torrent.dart';
import '../../domain/repositories/transmission_repository.dart';
import '../../shared/logic/torrent_list_logic.dart';
import '../app/providers.dart';
import 'preferences_controller.dart';
import 'profiles_controller.dart';

class TorrentListState {
  const TorrentListState({
    required this.isLoading,
    required this.isRefreshing,
    required this.isConfigured,
    required this.searchQuery,
    required this.groupingMode,
    required this.sortField,
    required this.sortAscending,
    required this.filter,
    required this.viewMode,
    required this.collapsedGroups,
    required this.torrents,
    required this.errorMessage,
    required this.lastUpdated,
    required this.selectedTorrentId,
  });

  factory TorrentListState.initial() {
    final defaults = AppPreferences.defaults();
    return TorrentListState(
      isLoading: false,
      isRefreshing: false,
      isConfigured: false,
      searchQuery: '',
      groupingMode: defaults.groupingMode,
      sortField: defaults.sortField,
      sortAscending: defaults.sortAscending,
      filter: defaults.filter,
      viewMode: defaults.viewMode,
      collapsedGroups: const <String>{},
      torrents: const <Torrent>[],
      errorMessage: null,
      lastUpdated: null,
      selectedTorrentId: null,
    );
  }

  final bool isLoading;
  final bool isRefreshing;
  final bool isConfigured;
  final String searchQuery;
  final TorrentGroupingMode groupingMode;
  final TorrentSortField sortField;
  final bool sortAscending;
  final TorrentFilter filter;
  final TorrentListViewMode viewMode;
  final Set<String> collapsedGroups;
  final List<Torrent> torrents;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final int? selectedTorrentId;

  List<Torrent> get visibleTorrents => TorrentListLogic.filterAndSort(
    torrents: torrents,
    searchQuery: searchQuery,
    filter: filter,
    sortField: sortField,
    sortAscending: sortAscending,
  );

  List<TorrentGroup> get visibleGroups =>
      TorrentListLogic.group(visibleTorrents, groupingMode);

  TorrentListState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isConfigured,
    String? searchQuery,
    TorrentGroupingMode? groupingMode,
    TorrentSortField? sortField,
    bool? sortAscending,
    TorrentFilter? filter,
    TorrentListViewMode? viewMode,
    Set<String>? collapsedGroups,
    List<Torrent>? torrents,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdated,
    int? selectedTorrentId,
    bool clearSelectedTorrent = false,
  }) {
    return TorrentListState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isConfigured: isConfigured ?? this.isConfigured,
      searchQuery: searchQuery ?? this.searchQuery,
      groupingMode: groupingMode ?? this.groupingMode,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      filter: filter ?? this.filter,
      viewMode: viewMode ?? this.viewMode,
      collapsedGroups: collapsedGroups ?? this.collapsedGroups,
      torrents: torrents ?? this.torrents,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      selectedTorrentId: clearSelectedTorrent
          ? null
          : selectedTorrentId ?? this.selectedTorrentId,
    );
  }
}

class TorrentListController extends StateNotifier<TorrentListState> {
  TorrentListController(this.ref) : super(TorrentListState.initial());

  final Ref ref;
  Timer? _refreshTimer;
  ServerProfile? _activeProfile;

  void applyPreferences(AppPreferences preferences) {
    state = state.copyWith(
      groupingMode: preferences.groupingMode,
      sortField: preferences.sortField,
      sortAscending: preferences.sortAscending,
      filter: preferences.filter,
      viewMode: preferences.viewMode,
      collapsedGroups: _collapsedGroupsFor(
        preferences,
        preferences.groupingMode,
      ),
    );
    _configureTimer(preferences.refreshInterval);
  }

  void handleProfilesChanged(ProfilesState? profilesState) {
    final nextProfile = profilesState?.activeProfile;
    if (_activeProfile?.id == nextProfile?.id) {
      return;
    }
    _activeProfile = nextProfile;
    state = state.copyWith(
      isConfigured: nextProfile != null,
      clearSelectedTorrent: nextProfile == null,
    );
    if (nextProfile == null) {
      _refreshTimer?.cancel();
      state = state.copyWith(torrents: const <Torrent>[], clearError: true);
      return;
    }
    unawaited(refresh(forceLoading: true));
  }

  void _configureTimer(Duration refreshInterval) {
    _refreshTimer?.cancel();
    if (_activeProfile == null || refreshInterval.inSeconds <= 0) {
      return;
    }
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      unawaited(refresh());
    });
  }

  Set<String> _collapsedGroupsFor(
    AppPreferences preferences,
    TorrentGroupingMode groupingMode,
  ) {
    return switch (groupingMode) {
      TorrentGroupingMode.downloadPath => preferences.collapsedPathGroups,
      TorrentGroupingMode.tracker => preferences.collapsedTrackerGroups,
      TorrentGroupingMode.flat => const <String>{},
    };
  }

  TransmissionRepository? get _repository {
    final active = ref
        .read(profilesControllerProvider)
        .valueOrNull
        ?.activeProfile;
    if (active == null) {
      return null;
    }
    return ref.read(transmissionRepositoryFactoryProvider).create(active);
  }

  Future<void> refresh({bool forceLoading = false}) async {
    final repository = _repository;
    if (repository == null) {
      state = state.copyWith(
        isConfigured: false,
        torrents: const <Torrent>[],
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(
      isLoading: forceLoading && state.torrents.isEmpty,
      isRefreshing: !forceLoading,
      clearError: true,
    );
    try {
      final torrents = await repository.getTorrents();
      final selectedId = state.selectedTorrentId;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        torrents: torrents,
        lastUpdated: DateTime.now(),
        errorMessage: null,
        selectedTorrentId: torrents.any((torrent) => torrent.id == selectedId)
            ? selectedId
            : (torrents.isNotEmpty ? torrents.first.id : null),
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: '$error',
      );
    }
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<void> setGroupingMode(TorrentGroupingMode value) async {
    final preferences =
        ref.read(preferencesControllerProvider).valueOrNull ??
        AppPreferences.defaults();
    await ref
        .read(preferencesControllerProvider.notifier)
        .updateGroupingMode(value);
    state = state.copyWith(
      groupingMode: value,
      collapsedGroups: _collapsedGroupsFor(preferences, value),
    );
  }

  Future<void> setFilter(TorrentFilter value) async {
    await ref.read(preferencesControllerProvider.notifier).updateFilter(value);
    state = state.copyWith(filter: value);
  }

  Future<void> setSort(TorrentSortField sortField, bool sortAscending) async {
    await ref
        .read(preferencesControllerProvider.notifier)
        .updateSort(sortField, sortAscending);
    state = state.copyWith(sortField: sortField, sortAscending: sortAscending);
  }

  Future<void> setViewMode(TorrentListViewMode viewMode) async {
    await ref
        .read(preferencesControllerProvider.notifier)
        .updateViewMode(viewMode);
    state = state.copyWith(viewMode: viewMode);
  }

  Future<void> toggleGroupCollapsed(String groupKey) async {
    final updated = {...state.collapsedGroups};
    final isCollapsed = updated.contains(groupKey);
    if (isCollapsed) {
      updated.remove(groupKey);
    } else {
      updated.add(groupKey);
    }
    state = state.copyWith(collapsedGroups: updated);
    if (state.groupingMode != TorrentGroupingMode.flat) {
      await ref
          .read(preferencesControllerProvider.notifier)
          .setGroupCollapsed(
            groupingMode: state.groupingMode,
            groupKey: groupKey,
            isCollapsed: !isCollapsed,
          );
    }
  }

  void selectTorrent(int torrentId) {
    state = state.copyWith(selectedTorrentId: torrentId);
  }

  Future<void> performAction(
    Future<void> Function(TransmissionRepository repo) action,
  ) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    await action(repository);
    await refresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final torrentListControllerProvider =
    StateNotifierProvider<TorrentListController, TorrentListState>((ref) {
      final controller = TorrentListController(ref);
      Future<void>.microtask(() {
        final preferences = ref.read(preferencesControllerProvider).valueOrNull;
        if (preferences != null) {
          controller.applyPreferences(preferences);
        }
        final profilesState = ref.read(profilesControllerProvider).valueOrNull;
        if (profilesState != null) {
          controller.handleProfilesChanged(profilesState);
        }
      });
      ref.listen(preferencesControllerProvider, (_, next) {
        next.whenData(controller.applyPreferences);
      });
      ref.listen(profilesControllerProvider, (_, next) {
        controller.handleProfilesChanged(next.valueOrNull);
      });
      return controller;
    });
