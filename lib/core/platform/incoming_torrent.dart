import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomingTorrent {
  const IncomingTorrent._({this.fileName, this.bytes, this.magnetLink});

  factory IncomingTorrent.file({
    required String fileName,
    required Uint8List bytes,
  }) {
    return IncomingTorrent._(fileName: fileName, bytes: bytes);
  }

  factory IncomingTorrent.magnet(String magnetLink) {
    return IncomingTorrent._(magnetLink: magnetLink);
  }

  factory IncomingTorrent.fromMap(Map<Object?, Object?> map) {
    final rawMagnetLink = map['magnetLink'];
    if (rawMagnetLink is String && rawMagnetLink.trim().isNotEmpty) {
      return IncomingTorrent.magnet(rawMagnetLink.trim());
    }

    final rawBytes = map['bytes'];
    if (rawBytes is! Uint8List) {
      throw const FormatException('Incoming torrent payload is missing.');
    }

    final rawFileName = map['fileName'];
    return IncomingTorrent.file(
      fileName: rawFileName is String && rawFileName.trim().isNotEmpty
          ? rawFileName.trim()
          : 'shared.torrent',
      bytes: rawBytes,
    );
  }

  final String? fileName;
  final Uint8List? bytes;
  final String? magnetLink;

  bool get isFile => bytes != null;
  bool get isMagnet => magnetLink != null;
}

class IncomingTorrentService {
  IncomingTorrentService() {
    _subscription = _eventChannel
        .receiveBroadcastStream()
        .cast<Map<Object?, Object?>>()
        .listen((event) {
          _controller.add(IncomingTorrent.fromMap(event));
        });
  }

  static const _methodChannel = MethodChannel(
    'com.transpilot.app/incoming_torrent_method',
  );
  static const _eventChannel = EventChannel(
    'com.transpilot.app/incoming_torrent_events',
  );

  final _controller = StreamController<IncomingTorrent>.broadcast();
  late final StreamSubscription<Map<Object?, Object?>> _subscription;

  Stream<IncomingTorrent> get stream => _controller.stream;

  Future<IncomingTorrent?> takeInitialTorrent() async {
    final payload = await _methodChannel.invokeMapMethod<Object?, Object?>(
      'takeInitialTorrent',
    );
    if (payload == null) {
      return null;
    }
    return IncomingTorrent.fromMap(payload);
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }
}

final incomingTorrentServiceProvider = Provider<IncomingTorrentService>((ref) {
  final service = IncomingTorrentService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
