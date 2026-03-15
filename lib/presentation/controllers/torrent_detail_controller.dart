import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/torrent.dart';
import '../../domain/repositories/transmission_repository.dart';
import '../app/providers.dart';
import 'profiles_controller.dart';

class TorrentDetailController extends StateNotifier<AsyncValue<Torrent?>> {
  TorrentDetailController(this.ref, this.torrentId)
    : super(const AsyncLoading());

  final Ref ref;
  final int torrentId;

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

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null) {
      state = const AsyncData(null);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repository.getTorrentDetail(torrentId),
    );
  }

  Future<void> perform(
    Future<void> Function(TransmissionRepository repo) action,
  ) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    await action(repository);
    await refresh();
  }
}

class TorrentFilesController
    extends StateNotifier<AsyncValue<List<TorrentFileEntry>>> {
  TorrentFilesController(this.ref, this.torrentId)
    : super(const AsyncLoading());

  final Ref ref;
  final int torrentId;

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

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null) {
      state = const AsyncData(<TorrentFileEntry>[]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.getTorrentFiles(torrentId));
  }

  Future<void> perform(
    Future<void> Function(TransmissionRepository repo) action,
  ) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    await action(repository);
    await refresh();
  }
}

class TorrentPeersController
    extends StateNotifier<AsyncValue<List<TorrentPeer>>> {
  TorrentPeersController(this.ref, this.torrentId)
    : super(const AsyncLoading());

  final Ref ref;
  final int torrentId;

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

  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null) {
      state = const AsyncData(<TorrentPeer>[]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.getTorrentPeers(torrentId));
  }
}

final torrentDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<TorrentDetailController, AsyncValue<Torrent?>, int>((
      ref,
      torrentId,
    ) {
      final controller = TorrentDetailController(ref, torrentId);
      Future<void>.microtask(controller.refresh);
      return controller;
    });

final torrentFilesControllerProvider = StateNotifierProvider.autoDispose
    .family<TorrentFilesController, AsyncValue<List<TorrentFileEntry>>, int>((
      ref,
      torrentId,
    ) {
      final controller = TorrentFilesController(ref, torrentId);
      Future<void>.microtask(controller.refresh);
      return controller;
    });

final torrentPeersControllerProvider = StateNotifierProvider.autoDispose
    .family<TorrentPeersController, AsyncValue<List<TorrentPeer>>, int>((
      ref,
      torrentId,
    ) {
      final controller = TorrentPeersController(ref, torrentId);
      Future<void>.microtask(controller.refresh);
      return controller;
    });
