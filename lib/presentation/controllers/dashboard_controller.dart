import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_preferences.dart';
import '../../domain/entities/server_profile.dart';
import '../../domain/entities/session_models.dart';
import '../../domain/repositories/transmission_repository.dart';
import '../app/providers.dart';
import 'preferences_controller.dart';
import 'profiles_controller.dart';

class DashboardState {
  const DashboardState({
    required this.isLoading,
    required this.isConfigured,
    required this.sessionInfo,
    required this.sessionStats,
    required this.freeSpaceInfo,
    required this.errorMessage,
    required this.lastUpdated,
  });

  factory DashboardState.initial() {
    return const DashboardState(
      isLoading: false,
      isConfigured: false,
      sessionInfo: null,
      sessionStats: null,
      freeSpaceInfo: null,
      errorMessage: null,
      lastUpdated: null,
    );
  }

  final bool isLoading;
  final bool isConfigured;
  final SessionInfo? sessionInfo;
  final SessionStats? sessionStats;
  final FreeSpaceInfo? freeSpaceInfo;
  final String? errorMessage;
  final DateTime? lastUpdated;

  DashboardState copyWith({
    bool? isLoading,
    bool? isConfigured,
    SessionInfo? sessionInfo,
    SessionStats? sessionStats,
    FreeSpaceInfo? freeSpaceInfo,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      isConfigured: isConfigured ?? this.isConfigured,
      sessionInfo: sessionInfo ?? this.sessionInfo,
      sessionStats: sessionStats ?? this.sessionStats,
      freeSpaceInfo: freeSpaceInfo ?? this.freeSpaceInfo,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this.ref) : super(DashboardState.initial());

  final Ref ref;
  Timer? _refreshTimer;
  ServerProfile? _activeProfile;

  void applyPreferences(AppPreferences preferences) {
    _refreshTimer?.cancel();
    if (_activeProfile == null) {
      return;
    }
    _refreshTimer = Timer.periodic(preferences.refreshInterval, (_) {
      unawaited(refresh());
    });
  }

  void handleProfilesChanged(ProfilesState? profilesState) {
    final nextProfile = profilesState?.activeProfile;
    if (_activeProfile?.id == nextProfile?.id) {
      return;
    }
    _activeProfile = nextProfile;
    state = state.copyWith(
      isConfigured: nextProfile != null,
      errorMessage: null,
      sessionInfo: nextProfile == null ? null : state.sessionInfo,
      sessionStats: nextProfile == null ? null : state.sessionStats,
      freeSpaceInfo: nextProfile == null ? null : state.freeSpaceInfo,
    );
    if (nextProfile == null) {
      _refreshTimer?.cancel();
      return;
    }
    unawaited(refresh(forceLoading: true));
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
      state = DashboardState.initial();
      return;
    }

    state = state.copyWith(isLoading: forceLoading, clearError: true);
    try {
      final sessionInfo = await repository.getSessionInfo();
      final sessionStats = await repository.getSessionStats();
      final freeSpace = await repository.getFreeSpace(sessionInfo.downloadDir);
      state = state.copyWith(
        isLoading: false,
        isConfigured: true,
        sessionInfo: sessionInfo,
        sessionStats: sessionStats,
        freeSpaceInfo: freeSpace,
        lastUpdated: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: '$error');
    }
  }

  Future<void> updateSessionInfo(SessionInfo sessionInfo) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.updateSessionInfo(sessionInfo);
      await refresh();
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: '$error');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
      final controller = DashboardController(ref);
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
