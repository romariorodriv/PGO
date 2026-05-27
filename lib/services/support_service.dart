import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'session_service.dart';

class SupportService {
  static const _requestTimeout = Duration(seconds: 15);

  SupportService({
    http.Client? client,
    SessionService? sessionService,
  })  : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  final http.Client _client;
  final SessionService _sessionService;

  Future<void> sendReport({
    required String type,
    required String subject,
    required String description,
    String? screenshotLabel,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/support/reports');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'type': type,
              'subject': subject,
              'description': description,
              if ((screenshotLabel ?? '').trim().isNotEmpty)
                'screenshotLabel': screenshotLabel!.trim(),
            }),
          )
          .timeout(_requestTimeout);

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (decoded is Map<String, dynamic>) {
          throw Exception(decoded['message'] ?? 'No se pudo enviar reporte');
        }
        throw Exception('No se pudo enviar reporte');
      }
    } on TimeoutException {
      throw Exception('El envío expiró. Verifica tu conexión.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend.');
    }
  }
}
