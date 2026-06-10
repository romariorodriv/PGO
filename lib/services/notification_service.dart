import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import 'api_config.dart';
import 'session_service.dart';

class NotificationService {
  static const _requestTimeout = Duration(seconds: 15);

  NotificationService({
    http.Client? client,
    SessionService? sessionService,
  })  : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  final http.Client _client;
  final SessionService _sessionService;

  Future<AppNotificationResponse> getNotifications() async {
    final json = await _send(method: 'GET', path: '/notifications');
    return AppNotificationResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<void> markRead(String notificationId) async {
    await _send(method: 'PATCH', path: '/notifications/$notificationId/read');
  }

  Future<void> markAllRead() async {
    await _send(method: 'PATCH', path: '/notifications/read-all');
  }

  Future<void> deleteNotification(String notificationId) async {
    await _send(method: 'DELETE', path: '/notifications/$notificationId');
  }

  Future<dynamic> _send({
    required String method,
    required String path,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    try {
      late final http.Response response;
      switch (method) {
        case 'GET':
          response =
              await _client.get(uri, headers: headers).timeout(_requestTimeout);
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

      final decoded = _decodeBody(response.body);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_EXPIRED');
      }
      if (response.statusCode == 404) {
        throw Exception('ENDPOINT_NOT_FOUND_404');
      }
      if (response.statusCode >= 500) {
        throw Exception('SERVER_UNAVAILABLE_${response.statusCode}');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (decoded is Map<String, dynamic>) {
          throw Exception(decoded['message'] ?? 'No se pudo completar acción');
        }
        if (decoded is String && decoded.trim().isNotEmpty) {
          throw Exception(decoded.trim());
        }
        throw Exception('No se pudo completar acción');
      }

      return decoded;
    } on TimeoutException {
      throw Exception('TIMEOUT');
    } on http.ClientException {
      throw Exception('NETWORK_ERROR');
    }
  }

  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
