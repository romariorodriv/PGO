import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/match_record.dart';
import 'api_config.dart';
import 'session_service.dart';

class MatchService {
  static const _requestTimeout = Duration(seconds: 15);

  MatchService({
    http.Client? client,
    SessionService? sessionService,
  })  : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  final http.Client _client;
  final SessionService _sessionService;

  Future<List<MatchRecord>> getMyMatches() async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/matches/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = json is Map<String, dynamic>
            ? json['message']
            : 'No se pudo cargar tus matches';
        throw Exception(message ?? 'No se pudo cargar tus matches');
      }

      final items =
          json is List ? json : (json['matches'] as List? ?? const []);
      return items
          .map(
            (item) => MatchRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al cargar tus matches.');
    } on http.ClientException {
      throw Exception(
          'No se pudo conectar al backend para cargar tus matches.');
    }
  }

  Future<MatchRecord> createMatch({
    required String clubName,
    required DateTime playedAt,
    required String matchType,
    required List<String> participantIds,
    String? photoUrl,
    String? openMatchAlertId,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/matches'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'clubName': clubName,
              'playedAt': playedAt.toUtc().toIso8601String(),
              'matchType': matchType,
              'participantIds': participantIds,
              if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
              if (openMatchAlertId != null && openMatchAlertId.isNotEmpty)
                'openMatchAlertId': openMatchAlertId,
            }),
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo registrar el match');
      }

      return MatchRecord.fromJson(json);
    } on TimeoutException {
      throw Exception(
        'La conexión con el backend expiró al registrar el match.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para registrar el match.',
      );
    }
  }

  Future<MatchRecord> updateMatchResult({
    required String matchId,
    required DateTime playedAt,
    required int winnerTeam,
    required List<Map<String, int>> games,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/matches/$matchId/result'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'playedAt': playedAt.toUtc().toIso8601String(),
              'winnerTeam': winnerTeam,
              'games': games,
            }),
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo actualizar el match');
      }

      return MatchRecord.fromJson(json);
    } on TimeoutException {
      throw Exception(
        'La conexión con el backend expiró al actualizar el match.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para actualizar el match.',
      );
    }
  }

  Future<MatchRecord> finalizeMatch({
    required String matchId,
    required List<String> winnerPlayerIds,
    String? description,
    String? photoUrl,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/matches/$matchId/finalize'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'winnerPlayerIds': winnerPlayerIds,
              if (description != null && description.trim().isNotEmpty)
                'description': description.trim(),
              if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
            }),
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo finalizar el match');
      }

      return MatchRecord.fromJson(json);
    } on TimeoutException {
      throw Exception(
        'La conexión con el backend expiró al finalizar el match.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para finalizar el match.',
      );
    }
  }
}
