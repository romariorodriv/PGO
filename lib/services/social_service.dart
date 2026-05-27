import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/friend_request.dart';
import 'api_config.dart';
import 'session_service.dart';

class SocialService {
  static const _requestTimeout = Duration(seconds: 15);

  SocialService({
    http.Client? client,
    SessionService? sessionService,
  })  : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  final http.Client _client;
  final SessionService _sessionService;

  Future<FriendRequestsResponse> getFriendRequests() async {
    final json = await _send(
      method: 'GET',
      path: '/social/friends/requests',
    );

    return FriendRequestsResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<FriendRequest> requestFriend(String userId) async {
    final json = await _send(
      method: 'POST',
      path: '/social/friends/$userId/request',
    );

    return FriendRequest.fromJson(json as Map<String, dynamic>);
  }

  Future<FriendRequest> acceptRequest(String friendshipId) async {
    final json = await _send(
      method: 'PATCH',
      path: '/social/friends/$friendshipId/accept',
    );

    return FriendRequest.fromJson(json as Map<String, dynamic>);
  }

  Future<FriendRequest> rejectRequest(String friendshipId) async {
    final json = await _send(
      method: 'PATCH',
      path: '/social/friends/$friendshipId/reject',
    );

    return FriendRequest.fromJson(json as Map<String, dynamic>);
  }

  Future<void> removeFriend(String userId) async {
    await _send(
      method: 'DELETE',
      path: '/social/friends/$userId',
    );
  }

  Future<dynamic> _send({
    required String method,
    required String path,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      late final http.Response response;
      switch (method) {
        case 'GET':
          response =
              await _client.get(uri, headers: headers).timeout(_requestTimeout);
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: headers)
              .timeout(_requestTimeout);
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers)
              .timeout(_requestTimeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(_requestTimeout);
          break;
        default:
          throw Exception('Metodo no soportado');
      }

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (decoded is Map<String, dynamic>) {
          throw Exception(decoded['message'] ?? 'No se pudo completar acción');
        }
        throw Exception('No se pudo completar acción');
      }

      return decoded;
    } on TimeoutException {
      throw Exception('La acción expiró. Verifica tu conexión.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend.');
    }
  }
}
