import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/open_match_alert.dart';
import 'api_config.dart';
import 'session_service.dart';

class OpenMatchAlertService {
  OpenMatchAlertService({
    http.Client? client,
    SessionService? sessionService,
  })  : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  static const _requestTimeout = Duration(seconds: 15);

  final http.Client _client;
  final SessionService _sessionService;

  Future<List<OpenMatchAlert>> getAlerts() async {
    final response = await _send(
      (token) => _client.get(
        Uri.parse('${ApiConfig.baseUrl}/open-match-alerts'),
        headers: _headers(token),
      ),
    );

    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) =>
            OpenMatchAlert.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<OpenMatchAlert> getAlert(String id) async {
    final response = await _send(
      (token) => _client.get(
        Uri.parse('${ApiConfig.baseUrl}/open-match-alerts/$id'),
        headers: _headers(token),
      ),
    );

    return OpenMatchAlert.fromJson(
      (jsonDecode(response.body) as Map).cast<String, dynamic>(),
    );
  }

  Future<OpenMatchAlert> createAlert({
    required String category,
    required String format,
    required DateTime startsAt,
    required String club,
    required String district,
    required String courtStatus,
    required int missingPlayers,
    required int costPerPerson,
    required String paymentLabel,
    String? comment,
    List<String> invitedUserIds = const [],
  }) async {
    final response = await _send(
      (token) => _client.post(
        Uri.parse('${ApiConfig.baseUrl}/open-match-alerts'),
        headers: _headers(token),
        body: jsonEncode({
          'category': category,
          'format': format,
          'startsAt': startsAt.toIso8601String(),
          'club': club,
          'district': district,
          'courtStatus': courtStatus,
          'missingPlayers': missingPlayers,
          'costPerPerson': costPerPerson,
          'paymentLabel': paymentLabel,
          if (invitedUserIds.isNotEmpty) 'invitedUserIds': invitedUserIds,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        }),
      ),
    );

    return OpenMatchAlert.fromJson(
      (jsonDecode(response.body) as Map).cast<String, dynamic>(),
    );
  }

  Future<OpenMatchAlert> joinAlert(String id) async {
    final response = await _send(
      (token) => _client.post(
        Uri.parse('${ApiConfig.baseUrl}/open-match-alerts/$id/join'),
        headers: _headers(token),
      ),
    );

    return OpenMatchAlert.fromJson(
      (jsonDecode(response.body) as Map).cast<String, dynamic>(),
    );
  }

  Future<OpenMatchAlert> leaveAlert(String id) async {
    final response = await _send(
      (token) => _client.post(
        Uri.parse('${ApiConfig.baseUrl}/open-match-alerts/$id/leave'),
        headers: _headers(token),
      ),
    );

    return OpenMatchAlert.fromJson(
      (jsonDecode(response.body) as Map).cast<String, dynamic>(),
    );
  }

  Future<OpenMatchAlert> updateCoordination({
    required String id,
    required String status,
  }) async {
    final response = await _send(
      (token) => _client.post(
        Uri.parse('${ApiConfig.baseUrl}/open-match-alerts/$id/coordination'),
        headers: _headers(token),
        body: jsonEncode({'status': status}),
      ),
    );

    return OpenMatchAlert.fromJson(
      (jsonDecode(response.body) as Map).cast<String, dynamic>(),
    );
  }

  Future<void> deleteAlert(String id) async {
    await _send(
      (token) => _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/open-match-alerts/$id'),
        headers: _headers(token),
      ),
    );
  }

  Future<http.Response> _send(
    Future<http.Response> Function(String token) request,
  ) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await request(token).timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body.isEmpty
            ? const <String, dynamic>{}
            : (jsonDecode(response.body) as Map).cast<String, dynamic>();
        throw Exception(body['message'] ?? 'No se pudo completar la acción');
      }
      return response;
    } on TimeoutException {
      throw Exception('La conexión con el backend expiró.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend.');
    }
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
}
