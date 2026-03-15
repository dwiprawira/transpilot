import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLogLevel { debug, info, warning, error }

class AppLogEntry {
  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.metadata = const <String, Object?>{},
  });

  final DateTime timestamp;
  final AppLogLevel level;
  final String category;
  final String message;
  final Map<String, Object?> metadata;
}

class AppLogger extends StateNotifier<List<AppLogEntry>> {
  AppLogger() : super(const []);

  static const _maxEntries = 200;

  void log({
    required AppLogLevel level,
    required String category,
    required String message,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      metadata: metadata,
    );
    Future<void>.microtask(() {
      if (!mounted) {
        return;
      }
      final next = [entry, ...state];
      state = next.take(_maxEntries).toList(growable: false);
    });
  }

  void clear() {
    state = const [];
  }

  String exportText() {
    final buffer = StringBuffer();
    for (final entry in state) {
      final metadata = entry.metadata.entries
          .map((item) => '${item.key}=${item.value}')
          .join(', ');
      buffer.writeln(
        '[${entry.timestamp.toIso8601String()}] '
        '${entry.level.name.toUpperCase()} '
        '${entry.category}: ${entry.message}'
        '${metadata.isEmpty ? '' : ' ($metadata)'}',
      );
    }
    return buffer.toString().trim();
  }
}
