import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_client.dart';

class SocketService {
  io.Socket? _socket;
  ApiClient? _api;

  void attachApi(ApiClient api) {
    _api = api;
  }

  static String _serverUrlFromApi(String apiBaseUrl) {
    if (apiBaseUrl.endsWith('/api')) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - 4);
    }
    return apiBaseUrl;
  }

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.131.43.29:3000/api',
    );
    final token = await _api?.getAccessToken() ?? '';

    _socket = io.io(
      _serverUrlFromApi(apiBaseUrl),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1500)
          .build(),
    );
    _socket!.connect();
  }

  io.Socket? get socket => _socket;

  void joinGroup(String groupId) => _socket?.emit('join:group', groupId);

  void leaveGroup(String groupId) => _socket?.emit('leave:group', groupId);

  void joinCampaign(String campaignId) =>
      _socket?.emit('join:campaign', campaignId);

  void leaveCampaign(String campaignId) =>
      _socket?.emit('leave:campaign', campaignId);

  void onMessageNew(dynamic Function(Map<String, dynamic>) handler) {
    _socket?.on('message:new', (data) => handler(_toMap(data)));
  }

  void onMessageDeleted(dynamic Function(String) handler) {
    _socket?.on('message:deleted', (data) => handler(data?.toString() ?? ''));
  }

  void onMessageReaction(dynamic Function(Map<String, dynamic>) handler) {
    _socket?.on('message:reaction', (data) => handler(_toMap(data)));
  }

  void onCampaignUpdate(dynamic Function(Map<String, dynamic>) handler) {
    _socket?.on('campaign:update', (data) => handler(_toMap(data)));
  }

  void onJoinedGroup(dynamic Function(String) handler) {
    _socket?.on('joined:group', (data) => handler(data?.toString() ?? ''));
  }

  void onError(dynamic Function(String) handler) {
    _socket?.on('error', (data) => handler(data?.toString() ?? ''));
  }

  void offEvent(String event) => _socket?.off(event);

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }

  static Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }
}
