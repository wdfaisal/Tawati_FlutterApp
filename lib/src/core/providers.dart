import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/services/auth_service.dart';
import '../features/donations/services/donation_service.dart';
import '../features/family/services/family_service.dart';
import '../features/groups/services/group_service.dart';
import '../features/initiatives/services/initiative_service.dart';
import '../features/news/services/news_service.dart';
import 'api_client.dart';
import 'biometric_service.dart';
import 'config/app_config_service.dart';
import 'local_mute_service.dart';
import 'socket_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.159.177.29:3000/api',
  );
  return ApiClient(baseUrl: baseUrl);
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider));
});

final donationServiceProvider = Provider<DonationService>((ref) {
  return DonationService(ref.read(apiClientProvider));
});

final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsService(ref.read(apiClientProvider));
});

final familyServiceProvider = Provider<FamilyService>((ref) {
  return FamilyService(ref.read(apiClientProvider));
});

final initiativeServiceProvider = Provider<InitiativeService>((ref) {
  return InitiativeService(ref.read(apiClientProvider));
});

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(ref.read(apiClientProvider));
});

final appConfigServiceProvider = Provider<AppConfigService>((ref) {
  return AppConfigService(ref.read(apiClientProvider));
});

final appConfigProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {};
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  service.attachApi(ref.read(apiClientProvider));
  return service;
});

final localMuteServiceProvider = Provider<LocalMuteService>((ref) {
  return LocalMuteService();
});

final localMutedGroupsProvider =
    StateNotifierProvider<LocalMuteNotifier, Set<String>>((ref) {
  return LocalMuteNotifier(ref.read(localMuteServiceProvider));
});

class LocalMuteNotifier extends StateNotifier<Set<String>> {
  final LocalMuteService _service;
  LocalMuteNotifier(this._service) : super(<String>{}) {
    _load();
  }

  Future<void> _load() async {
    final ids = await _service.loadMutedGroupIds();
    if (mounted) state = ids;
  }

  Future<void> toggle(String groupId) async {
    final muted = state.contains(groupId);
    final next = Set<String>.from(state);
    if (muted) {
      next.remove(groupId);
    } else {
      next.add(groupId);
    }
    state = next;
    await _service.setGroupMuted(groupId, !muted);
  }

  bool isMuted(String groupId) => state.contains(groupId);
}
