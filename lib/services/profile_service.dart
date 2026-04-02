import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/profile_history.dart';
import '../models/profile_summary.dart';
import 'api_config.dart';
import 'session_service.dart';

class ProfileService {
  static const _requestTimeout = Duration(seconds: 15);

  ProfileService({
    http.Client? client,
    SessionService? sessionService,
  })  : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  final http.Client _client;
  final SessionService _sessionService;

  Future<ProfileSummary> getMyProfile() async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa');
    }

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo cargar el perfil');
      }

      return ProfileSummary.fromJson(json);
    } on TimeoutException {
      throw Exception(
        'La carga del perfil expiro. Verifica la conexion con el backend.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para cargar el perfil.',
      );
    }
  }

  Future<ProfileSummary> updateMyProfile({
    required String name,
    String? photoUrl,
    String? category,
    String? preferredClub,
    String? preferredSide,
    String? racketModel,
    String? experienceLevel,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa');
    }

    final payload = <String, dynamic>{
      'name': name.trim(),
      'photoUrl': photoUrl?.trim(),
      'category': category?.trim(),
      'preferredClub': preferredClub?.trim(),
      'preferredSide': preferredSide?.trim(),
      'racketModel': racketModel?.trim(),
      'experienceLevel': experienceLevel?.trim().toUpperCase(),
    }..removeWhere((key, value) => value == null || value == '');

    try {
      final response = await _client
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/profile/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo actualizar el perfil');
      }

      return ProfileSummary.fromJson(json);
    } on TimeoutException {
      throw Exception(
        'La actualizacion del perfil expiro. Verifica la conexion con el backend.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para actualizar el perfil.',
      );
    }
  }

  Future<ProfileHistory> getMyHistory() async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa');
    }

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/me/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          json['message'] ?? 'No se pudo cargar el historial del perfil',
        );
      }

      return ProfileHistory.fromJson(json);
    } on TimeoutException {
      throw Exception(
        'La carga del historial expiro. Verifica la conexion con el backend.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para cargar el historial.',
      );
    }
  }
}
