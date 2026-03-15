import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/app_logger.dart';
import '../../data/repositories/preferences_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/transmission_repository_impl.dart';
import '../../data/rpc/transmission_rpc_client.dart';
import '../../data/storage/preferences_storage.dart';
import '../../data/storage/secure_credentials_storage.dart';
import '../../domain/entities/server_profile.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/transmission_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  throw UnimplementedError('secureStorageProvider must be overridden');
});

final appLoggerProvider = StateNotifierProvider<AppLogger, List<AppLogEntry>>((
  ref,
) {
  return AppLogger();
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  final storage = PreferencesStorage(ref.watch(sharedPreferencesProvider));
  return PreferencesRepositoryImpl(storage);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  final secureStorage = SecureCredentialsStorage(
    ref.watch(secureStorageProvider),
  );
  return ProfileRepositoryImpl(sharedPreferences, secureStorage);
});

final transmissionRepositoryFactoryProvider =
    Provider<TransmissionRepositoryFactory>((ref) {
      return TransmissionRepositoryFactory(
        ref.watch(appLoggerProvider.notifier),
      );
    });

final activeProfileProvider = Provider<ServerProfile?>((ref) => null);

class TransmissionRepositoryFactory {
  TransmissionRepositoryFactory(this._logger);

  final AppLogger _logger;

  TransmissionRepository create(ServerProfile profile) {
    return TransmissionRepositoryImpl(
      TransmissionRpcClient(profile, logger: _logger),
    );
  }
}
