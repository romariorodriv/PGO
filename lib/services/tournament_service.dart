import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tournament_admin_bracket.dart';
import '../models/tournament_admin_matches.dart';
import '../models/tournament_alert.dart';
import '../models/tournament_record.dart';
import 'api_config.dart';
import 'session_service.dart';

class TournamentService {
  static const _requestTimeout = Duration(seconds: 15);

  TournamentService({
    http.Client? client,
    SessionService? sessionService,
  })  : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  final http.Client _client;
  final SessionService _sessionService;

  Future<TournamentRecord> createTournament({
    required String title,
    required String tournamentType,
    String pairingMode = 'FIXED',
    required int playerCapacity,
    required String modality,
    required String format,
    required String location,
    String? address,
    required String city,
    required String district,
    required DateTime startsAt,
    required String prize,
    required int entryFee,
    required String category,
    String? description,
    String? photoUrl,
    String status = 'PUBLISHED',
    bool registrationsOpen = true,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/tournaments'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'title': title.trim(),
              'tournamentType': tournamentType,
              'pairingMode': pairingMode,
              'playerCapacity': playerCapacity,
              'modality': modality,
              'format': format,
              'location': location.trim(),
              if (address != null && address.trim().isNotEmpty)
                'address': address.trim(),
              'city': city.trim(),
              'district': district.trim(),
              'startsAt': startsAt.toUtc().toIso8601String(),
              'prize': prize.trim(),
              'entryFee': entryFee,
              'category': category.trim(),
              if (description != null && description.trim().isNotEmpty)
                'description': description.trim(),
              if (photoUrl != null && photoUrl.trim().isNotEmpty)
                'photoUrl': photoUrl.trim(),
              'status': status,
              'registrationsOpen': registrationsOpen,
            }),
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo crear el torneo');
      }

      return TournamentRecord.fromJson(json);
    } on TimeoutException {
      throw Exception(
        'La conexión con el backend expiró al crear el torneo.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para crear el torneo.',
      );
    }
  }

  Future<TournamentRecord> updateTournament({
    required String tournamentId,
    String? title,
    String? tournamentType,
    String? pairingMode,
    int? playerCapacity,
    String? modality,
    String? format,
    String? location,
    String? address,
    String? city,
    String? district,
    DateTime? startsAt,
    String? prize,
    int? entryFee,
    String? category,
    String? description,
    String? photoUrl,
    String? status,
    bool? registrationsOpen,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    final body = <String, dynamic>{};
    if (title != null) body['title'] = title.trim();
    if (tournamentType != null) body['tournamentType'] = tournamentType;
    if (pairingMode != null) body['pairingMode'] = pairingMode;
    if (playerCapacity != null) body['playerCapacity'] = playerCapacity;
    if (modality != null) body['modality'] = modality;
    if (format != null) body['format'] = format;
    if (location != null) body['location'] = location.trim();
    if (address != null) body['address'] = address.trim();
    if (city != null) body['city'] = city.trim();
    if (district != null) body['district'] = district.trim();
    if (startsAt != null) body['startsAt'] = startsAt.toUtc().toIso8601String();
    if (prize != null) body['prize'] = prize.trim();
    if (entryFee != null) body['entryFee'] = entryFee;
    if (category != null) body['category'] = category.trim();
    if (description != null) body['description'] = description.trim();
    if (photoUrl != null) body['photoUrl'] = photoUrl.trim();
    if (status != null) body['status'] = status;
    if (registrationsOpen != null) {
      body['registrationsOpen'] = registrationsOpen;
    }

    try {
      final response = await _client
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/tournaments/$tournamentId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo actualizar el torneo');
      }

      return TournamentRecord.fromJson(json);
    } on TimeoutException {
      throw Exception(
        'La conexión con el backend expiró al actualizar el torneo.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para actualizar el torneo.',
      );
    }
  }

  Future<List<TournamentRecord>> getTournaments() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/tournaments'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (json is Map<String, dynamic>) {
          throw Exception(json['message'] ?? 'No se pudo cargar los torneos');
        }
        throw Exception('No se pudo cargar los torneos');
      }

      if (json is! List) {
        throw Exception('La respuesta de torneos no es válida');
      }

      return json
          .map(
            (item) => TournamentRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on TimeoutException {
      throw Exception(
        'La conexión con el backend expiró al cargar los torneos.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para cargar los torneos.',
      );
    }
  }

  Future<TournamentRecord> getTournament(String tournamentId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/tournaments/$tournamentId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo cargar el torneo');
      }

      return TournamentRecord.fromJson(json);
    } on TimeoutException {
      throw Exception('La conexión con el backend expiró al cargar el torneo.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para cargar el torneo.');
    }
  }

  Future<TournamentAdminMatchesData> getAdminMatches(
    String tournamentId,
  ) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-matches'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            json['message'] ?? 'No se pudieron cargar los partidos');
      }

      return TournamentAdminMatchesData.fromJson(json);
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al cargar los partidos.');
    } on http.ClientException {
      throw Exception(
          'No se pudo conectar al backend para cargar los partidos.');
    }
  }

  Future<TournamentAdminMatchesData> getTournamentMatches(
    String tournamentId,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/tournaments/$tournamentId/matches'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            json['message'] ?? 'No se pudieron cargar los partidos');
      }

      return TournamentAdminMatchesData.fromJson(json);
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al cargar los partidos.');
    } on http.ClientException {
      throw Exception(
          'No se pudo conectar al backend para cargar los partidos.');
    }
  }

  Future<TournamentAdminMatchesData> getMyTournamentMatches(
    String tournamentId,
  ) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      return getTournamentMatches(tournamentId);
    }

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/tournaments/$tournamentId/my-matches'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            json['message'] ?? 'No se pudieron cargar tus partidos');
      }

      return TournamentAdminMatchesData.fromJson(json);
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al cargar tus partidos.');
    } on http.ClientException {
      throw Exception(
          'No se pudo conectar al backend para cargar tus partidos.');
    }
  }

  Future<TournamentAlertsResponse> getMyAlerts() async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/tournaments/me/alerts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          json['message'] ?? 'No se pudieron cargar las alertas',
        );
      }

      return TournamentAlertsResponse.fromJson(json);
    } on TimeoutException {
      throw Exception('La conexión con el backend expiró al cargar alertas.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para cargar alertas.');
    }
  }

  Future<TournamentAdminBracketData> getAdminBracket(
    String tournamentId,
  ) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-bracket'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo cargar el bracket');
      }

      return TournamentAdminBracketData.fromJson(json);
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al cargar el bracket.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para cargar el bracket.');
    }
  }

  Future<TournamentAdminBracketData> getTournamentBracket(
    String tournamentId,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/tournaments/$tournamentId/bracket'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo cargar el bracket');
      }

      return TournamentAdminBracketData.fromJson(json);
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al cargar el bracket.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para cargar el bracket.');
    }
  }

  Future<void> generateBracket(String tournamentId) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/tournaments/$tournamentId/generate-bracket'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudieron generar los cruces');
      }
    } on TimeoutException {
      throw Exception('La conexión con el backend expiró al generar cruces.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para generar cruces.');
    }
  }

  Future<void> closeAndGenerateBracket(String tournamentId) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/tournaments/$tournamentId/close-and-generate',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          json['message'] ??
              'No se pudieron cerrar inscripciones y generar cruces',
        );
      }
    } on TimeoutException {
      throw Exception(
        'La conexión con el backend expiró al cerrar inscripciones y generar cruces.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para cerrar inscripciones y generar cruces.',
      );
    }
  }

  Future<void> deleteBracket(String tournamentId) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/tournaments/$tournamentId/delete-bracket',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudieron eliminar cruces');
      }
    } on TimeoutException {
      throw Exception('La conexión con el backend expiró al eliminar cruces.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para eliminar cruces.');
    }
  }

  Future<void> startAdminMatch({
    required String tournamentId,
    required String matchId,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.patch(
        Uri.parse(
          '${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-matches/$matchId/start',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudo iniciar el partido');
      }
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al iniciar el partido.');
    } on http.ClientException {
      throw Exception(
          'No se pudo conectar al backend para iniciar el partido.');
    }
  }

  Future<void> startTournamentMatch({
    required String tournamentId,
    required String matchId,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.patch(
        Uri.parse(
          '${ApiConfig.baseUrl}/tournaments/$tournamentId/matches/$matchId/start',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudo iniciar el partido');
      }
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al iniciar el partido.');
    } on http.ClientException {
      throw Exception(
          'No se pudo conectar al backend para iniciar el partido.');
    }
  }

  Future<void> finishTournamentMatch({
    required String tournamentId,
    required String matchId,
    required String winnerLabel,
    String? score,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client
          .patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/tournaments/$tournamentId/matches/$matchId/finish',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'winnerLabel': winnerLabel,
              if (score != null && score.trim().isNotEmpty)
                'score': score.trim(),
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudo registrar el ganador');
      }
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al registrar el ganador.');
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para registrar el ganador.',
      );
    }
  }

  Future<void> finishAdminMatch({
    required String tournamentId,
    required String matchId,
    required String winnerLabel,
    String? score,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client
          .patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-matches/$matchId/finish',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'winnerLabel': winnerLabel,
              if (score != null && score.trim().isNotEmpty)
                'score': score.trim(),
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudo registrar el ganador');
      }
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al registrar el ganador.');
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para registrar el ganador.',
      );
    }
  }

  Future<void> correctAdminMatchResult({
    required String tournamentId,
    required String matchId,
    required String winnerLabel,
    String? score,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client
          .patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-matches/$matchId/correct-result',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'winnerLabel': winnerLabel,
              if (score != null && score.trim().isNotEmpty)
                'score': score.trim(),
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudo corregir el resultado');
      }
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al corregir el resultado.');
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para corregir el resultado.',
      );
    }
  }

  Future<void> registerSolo({
    required String tournamentId,
    required String preferredSide,
    required String availability,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}/tournaments/$tournamentId/register-solo'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'preferredSide': preferredSide,
              'availability': availability,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
            json['message'] ?? 'No se pudo completar la inscripción');
      }
    } on TimeoutException {
      throw Exception('La conexión con el backend expiró al inscribirte.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para inscribirte.');
    }
  }

  Future<void> registerWithPartner({
    required String tournamentId,
    required String partnerUserId,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/tournaments/$tournamentId/register-with-partner',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'partnerUserId': partnerUserId,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
            json['message'] ?? 'No se pudo completar la inscripción');
      }
    } on TimeoutException {
      throw Exception('La conexión con el backend expiró al inscribirte.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para inscribirte.');
    }
  }

  Future<TournamentRecord> pairAdminRegistrations({
    required String tournamentId,
    required String registrationId,
    required String partnerRegistrationId,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.patch(
        Uri.parse(
          '${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-registrations/$registrationId/pair/$partnerRegistrationId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            json['message'] ?? 'No se pudo emparejar la inscripción');
      }

      return TournamentRecord.fromJson(json);
    } on TimeoutException {
      throw Exception('La conexión con el backend expiró al emparejar.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para emparejar.');
    }
  }

  Future<TournamentRecord> addAdminRegistration({
    required String tournamentId,
    required String userId,
    String? partnerUserId,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-registrations',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'userId': userId,
              if (partnerUserId != null && partnerUserId.isNotEmpty)
                'partnerUserId': partnerUserId,
            }),
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo agregar al jugador');
      }

      return TournamentRecord.fromJson(json);
    } on TimeoutException {
      throw Exception('La conexión con el backend expiró al agregar jugador.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para agregar jugador.');
    }
  }

  Future<TournamentRecord> removeAdminRegistration({
    required String tournamentId,
    required String registrationId,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await _client.patch(
        Uri.parse(
          '${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-registrations/$registrationId/remove',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo quitar la inscripción');
      }

      return TournamentRecord.fromJson(json);
    } on TimeoutException {
      throw Exception(
          'La conexión con el backend expiró al quitar la inscripción.');
    } on http.ClientException {
      throw Exception(
          'No se pudo conectar al backend para quitar la inscripción.');
    }
  }
}
