import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'session_service.dart';

class AccountService {
  static const _requestTimeout = Duration(seconds: 15);

  AccountService({
    http.Client? client,
    SessionService? sessionService,
  })  : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  final http.Client _client;
  final SessionService _sessionService;

  Future<void> changePassword(String password) async {
    await _send(
      method: 'PATCH',
      path: '/auth/password',
      body: {'password': password},
    );
  }

  Future<void> deleteAccount() async {
    await _send(method: 'DELETE', path: '/auth/account');
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
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
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
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
