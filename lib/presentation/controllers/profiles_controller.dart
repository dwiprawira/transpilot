import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/server_profile.dart';
import '../app/providers.dart';

class ProfilesController extends StateNotifier<AsyncValue<ProfilesState>> {
  ProfilesController(this.ref) : super(const AsyncLoading()) {
    load();
  }

  final Ref ref;

  Future<void> load() async {
    try {
      final repository = ref.read(profileRepositoryProvider);
      final profiles = await repository.loadProfiles();
      final activeProfileId = await repository.loadActiveProfileId();
      state = AsyncData(
        ProfilesState(
          profiles: profiles,
          activeProfileId:
              activeProfileId ??
              (profiles.isNotEmpty ? profiles.first.id : null),
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> saveProfile(ServerProfile profile) async {
    final repository = ref.read(profileRepositoryProvider);
    final withId = profile.id.isEmpty
        ? profile.copyWith(id: const Uuid().v4())
        : profile;
    await repository.saveProfile(withId);
    final current = state.valueOrNull;
    if (current?.activeProfile == null) {
      await repository.saveActiveProfileId(withId.id);
    }
    await load();
  }

  Future<void> deleteProfile(String profileId) async {
    await ref.read(profileRepositoryProvider).deleteProfile(profileId);
    await load();
  }

  Future<void> setActiveProfile(String profileId) async {
    await ref.read(profileRepositoryProvider).saveActiveProfileId(profileId);
    final current = state.valueOrNull;
    if (current == null) {
      await load();
      return;
    }
    state = AsyncData(current.copyWith(activeProfileId: profileId));
  }

  Future<void> clearActiveProfile() async {
    await ref.read(profileRepositoryProvider).saveActiveProfileId(null);
    final current = state.valueOrNull;
    if (current == null) {
      await load();
      return;
    }
    state = AsyncData(current.copyWith(clearActiveProfile: true));
  }

  Future<void> testConnection(ServerProfile profile) async {
    final repository = ref
        .read(transmissionRepositoryFactoryProvider)
        .create(profile);
    await repository.testConnection();
  }
}

final profilesControllerProvider =
    StateNotifierProvider<ProfilesController, AsyncValue<ProfilesState>>(
      ProfilesController.new,
    );
