import '../entities/server_profile.dart';

abstract class ProfileRepository {
  Future<List<ServerProfile>> loadProfiles();
  Future<void> saveProfile(ServerProfile profile);
  Future<void> deleteProfile(String profileId);
  Future<String?> loadActiveProfileId();
  Future<void> saveActiveProfileId(String? profileId);
}
