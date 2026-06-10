import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/community_user.dart';
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
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_EXPIRED');
      }
      if (response.statusCode == 404) {
        throw Exception('ENDPOINT_NOT_FOUND_404');
      }
      if (response.statusCode >= 500) {
        throw Exception('SERVER_UNAVAILABLE_${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo cargar el perfil');
      }

      return ProfileSummary.fromJson(json);
    } on TimeoutException {
      throw Exception(
        'TIMEOUT',
      );
    } on http.ClientException {
      throw Exception(
        'NETWORK_ERROR',
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
    String? categoryOrigin,
    bool? categoryIsProvisional,
    String? categorySuggested,
    String? categoryPreliminary,
    String? categoryMaxApplied,
    int? categoryScore,
    Map<String, List<String>>? categoryQuizAnswers,
    bool? hasCompletedInitialOnboarding,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    final payload = <String, dynamic>{
      'name': name.trim(),
      'photoUrl': _normalizeRemotePhotoUrl(photoUrl),
      'category': category?.trim(),
      'preferredClub': preferredClub?.trim(),
      'preferredSide': preferredSide?.trim(),
      'racketModel': racketModel?.trim(),
      'experienceLevel': experienceLevel?.trim().toUpperCase(),
      'categoryOrigin': categoryOrigin?.trim(),
      'categoryIsProvisional': categoryIsProvisional,
      'categorySuggested': categorySuggested?.trim(),
      'categoryPreliminary': categoryPreliminary?.trim(),
      'categoryMaxApplied': categoryMaxApplied?.trim(),
      'categoryScore': categoryScore,
      'categoryQuizAnswers': categoryQuizAnswers,
      'hasCompletedInitialOnboarding': hasCompletedInitialOnboarding,
    }..removeWhere((key, value) => value == null || value == '');
    _logProfilePayload(payload);

    try {
      return await _sendUpdateProfilePayload(payload);
    } on Exception catch (error) {
      if (_shouldRetryWithoutLegacyOnboardingFields(error, payload)) {
        final fallbackPayload = Map<String, dynamic>.from(payload)
          ..remove('categoryOrigin')
          ..remove('categoryIsProvisional')
          ..remove('categorySuggested')
          ..remove('categoryPreliminary')
          ..remove('categoryMaxApplied')
          ..remove('categoryScore')
          ..remove('categoryQuizAnswers')
          ..remove('hasCompletedInitialOnboarding');
        return _sendUpdateProfilePayload(fallbackPayload);
      }
      rethrow;
    }
  }

  Future<ProfileSummary> _sendUpdateProfilePayload(
    Map<String, dynamic> payload,
  ) async {
    try {
      final token = await _sessionService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('No hay sesión activa');
      }
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

      _throwIfAuthExpired(response);
      _logProfileUpdate(
        status: response.statusCode,
        payloadKeys: payload.keys.toList(),
        body: _safeResponseSummary(response.body),
      );
      if (response.statusCode == 413) {
        throw Exception(
          'El archivo es muy pesado. Intenta con una imagen más liviana.',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_profileUpdateMessage(json));
      }

      return ProfileSummary.fromJson(json);
    } on TimeoutException {
      throw Exception(
        'La actualización del perfil expiró. Verifica la conexión con el backend.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para actualizar el perfil.',
      );
    }
  }

  Future<void> markHomeGuideSeen() async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/profile/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'hasSeenHomeGuide': true}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_EXPIRED');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.body.isEmpty) {
          throw Exception('No se pudo guardar la guia');
        }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudo guardar la guia');
      }
    } on TimeoutException {
      throw Exception('La actualización de la guia expiró.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend.');
    }
  }

  Future<void> markInitialOnboardingComplete() async {
    await _patchFlags({'hasCompletedInitialOnboarding': true});
  }

  Future<void> _patchFlags(Map<String, dynamic> body) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    final response = await _client
        .patch(
          Uri.parse('${ApiConfig.baseUrl}/profile/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);

    _throwIfAuthExpired(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        _friendlyApiMessage(json['message'], 'No se pudo actualizar el perfil'),
      );
    }
  }

  void _throwIfAuthExpired(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('AUTH_EXPIRED');
    }
  }

  bool _shouldRetryWithoutLegacyOnboardingFields(
    Object error,
    Map<String, dynamic> payload,
  ) {
    final message = error.toString().toLowerCase();
    final hasLegacyFields = payload.containsKey('categoryOrigin') ||
        payload.containsKey('categoryIsProvisional') ||
        payload.containsKey('categorySuggested') ||
        payload.containsKey('categoryPreliminary') ||
        payload.containsKey('categoryMaxApplied') ||
        payload.containsKey('categoryScore') ||
        payload.containsKey('categoryQuizAnswers') ||
        payload.containsKey('hasCompletedInitialOnboarding');
    return hasLegacyFields &&
        (message.contains('should not exist') ||
            message.contains('validation') ||
            message.contains('badrequest') ||
            message.contains('bad request') ||
            message.contains('must be') ||
            message.contains('property') ||
            message.contains('categoryorigin') ||
            message.contains('categoryisprovisional') ||
            message.contains('categorysuggested') ||
            message.contains('categorypreliminary') ||
            message.contains('categorymaxapplied') ||
            message.contains('categoryscore') ||
            message.contains('categoryquizanswers') ||
            message.contains('hascompletedinitialonboarding'));
  }

  static void _logProfileUpdate({
    required int status,
    required List<String> payloadKeys,
    required String body,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      'pgo_profile_update status=$status payload=${payloadKeys.join(",")} body=$body',
    );
  }

  static void _logProfilePayload(Map<String, dynamic> payload) {
    if (!kDebugMode) return;
    final details = payload.entries.map((entry) {
      final value = entry.value;
      final length = value is String ? ' length=${value.length}' : '';
      return '${entry.key}=${value.runtimeType} present=true$length';
    }).join(' ');
    debugPrint('pgo.profile_update payload_types $details');
  }

  static String? _normalizeRemotePhotoUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || trimmed.length > 2048) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static String _safeResponseSummary(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return 'json_object=false';
      final code = decoded['code']?.toString() ?? 'none';
      final message = decoded['message'];
      final messageLength = message is String ? message.length : 0;
      final requestIdPresent =
          decoded['requestId']?.toString().trim().isNotEmpty == true;
      return 'code=$code message_length=$messageLength '
          'request_id_present=$requestIdPresent';
    } catch (_) {
      return 'json_object=false body_length=${body.length}';
    }
  }

  String _friendlyApiMessage(Object? message, String fallback) {
    if (message is String && message.trim().isNotEmpty) {
      final lower = message.toLowerCase();
      if (lower.contains('should not exist') ||
          lower.contains('must be') ||
          lower.contains('validation') ||
          lower.contains('bad request')) {
        return message.trim();
      }
      return message;
    }
    if (message is List && message.isNotEmpty) {
      return message
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .join(' ');
    }
    if (message is Map && message.isNotEmpty) {
      final nested = message['message'];
      if (nested != null) {
        return _friendlyApiMessage(nested, fallback);
      }
      return message.values
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .join(' ');
    }
    return fallback;
  }

  String _profileUpdateMessage(Map<String, dynamic> json) {
    final code = json['code']?.toString();
    switch (code) {
      case 'invalid_profile_payload':
      case 'invalid_category':
      case 'invalid_preferred_side':
        return _friendlyApiMessage(
          json['message'],
          'Revisa los datos de tu perfil e intenta nuevamente.',
        );
      case 'user_not_found':
        return 'No pudimos iniciar sesión. Inténtalo nuevamente.';
      case 'profile_conflict':
      case 'profile_update_failed':
        return 'No pudimos completar tu perfil. Inténtalo nuevamente.';
      default:
        final status = (json['statusCode'] as num?)?.toInt();
        if (status != null && status >= 500) {
          return 'No pudimos completar tu perfil. Inténtalo nuevamente.';
        }
        return _friendlyApiMessage(
          json['message'],
          'No pudimos completar tu perfil. Inténtalo nuevamente.',
        );
    }
  }

  Future<ProfileHistory> getMyHistory() async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
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
        'La carga del historial expiró. Verifica la conexión con el backend.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para cargar el historial.',
      );
    }
  }

  Future<List<CommunityUser>> getMyFriends() async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/me/friends'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode == 404) {
        return const [];
      }

      final json = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (json is Map<String, dynamic>) {
          throw Exception(json['message'] ?? 'No se pudo cargar amigos');
        }
        throw Exception('No se pudo cargar amigos');
      }

      return (json as List)
          .map((item) => CommunityUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception('La carga de amigos expiró.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para cargar amigos.');
    }
  }
}
