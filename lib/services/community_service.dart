import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/community_user.dart';
import 'api_config.dart';
import 'session_service.dart';

class CommunityService {
  static const _requestTimeout = Duration(seconds: 15);

  CommunityService({
    http.Client? client,
    SessionService? sessionService,
  })  : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  final http.Client _client;
  final SessionService _sessionService;

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  Future<List<CommunityUser>> getSuggestions() async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/users/suggestions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      final json = _decodeBody(response);
      if (response.statusCode == 404) {
        return const [];
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (json is Map<String, dynamic>) {
          throw Exception(
              json['message'] ?? 'No se pudieron cargar sugerencias');
        }
        throw Exception('No se pudieron cargar sugerencias');
      }

      return (json as List)
          .map((item) => CommunityUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception('La carga de sugerencias expiró.');
    } on http.ClientException {
      throw Exception(
          'No se pudo conectar al backend para cargar sugerencias.');
    }
  }

  Future<List<CommunityUser>> searchCommunity(String query) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/users/community').replace(
      queryParameters: {
        'q': query.trim(),
      },
    );

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      final json = _decodeBody(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (json is Map<String, dynamic>) {
          throw Exception(json['message'] ?? 'No se pudo cargar la comunidad');
        }
        if (json is String && json.isNotEmpty) {
          throw Exception(json);
        }
        throw Exception('No se pudo cargar la comunidad');
      }

      return (json as List)
          .map((item) => CommunityUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception('La carga de la comunidad expiró.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para cargar usuarios.');
    }
  }
}
