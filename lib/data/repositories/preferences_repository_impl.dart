import '../../domain/entities/app_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../storage/preferences_storage.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl(this._storage);

  final PreferencesStorage _storage;

  @override
  Future<AppPreferences> load() async => _storage.load();

  @override
  Future<void> save(AppPreferences preferences) => _storage.save(preferences);
}
