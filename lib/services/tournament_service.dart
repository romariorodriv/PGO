import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tournament_admin_bracket.dart';
import '../models/tournament_admin_matches.dart';
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
      throw Exception('No hay sesion activa');
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
        'La conexion con el backend expiro al crear el torneo.',
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
      throw Exception('No hay sesion activa');
    }

    final body = <String, dynamic>{};
    if (title != null) body['title'] = title.trim();
    if (tournamentType != null) body['tournamentType'] = tournamentType;
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
        'La conexion con el backend expiro al actualizar el torneo.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para actualizar el torneo.',
      );
    }
  }

  Future<List<TournamentRecord>> getTournaments() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/tournaments'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (json is Map<String, dynamic>) {
          throw Exception(json['message'] ?? 'No se pudo cargar los torneos');
        }
        throw Exception('No se pudo cargar los torneos');
      }

      if (json is! List) {
        throw Exception('La respuesta de torneos no es valida');
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
        'La conexion con el backend expiro al cargar los torneos.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para cargar los torneos.',
      );
    }
  }

  Future<TournamentRecord> getTournament(String tournamentId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/tournaments/$tournamentId'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo cargar el torneo');
      }

      return TournamentRecord.fromJson(json);
    } on TimeoutException {
      throw Exception('La conexion con el backend expiro al cargar el torneo.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para cargar el torneo.');
    }
  }

  Future<TournamentAdminMatchesData> getAdminMatches(
    String tournamentId,
  ) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa');
    }

    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-matches'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudieron cargar los partidos');
      }

      return TournamentAdminMatchesData.fromJson(json);
    } on TimeoutException {
      throw Exception('La conexion con el backend expiro al cargar los partidos.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para cargar los partidos.');
    }
  }

  Future<TournamentAdminBracketData> getAdminBracket(
    String tournamentId,
  ) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa');
    }

    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-bracket'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo cargar el bracket');
      }

      return TournamentAdminBracketData.fromJson(json);
    } on TimeoutException {
      throw Exception('La conexion con el backend expiro al cargar el bracket.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para cargar el bracket.');
    }
  }

  Future<void> generateBracket(String tournamentId) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa');
    }

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/tournaments/$tournamentId/generate-bracket'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudieron generar los cruces');
      }
    } on TimeoutException {
      throw Exception('La conexion con el backend expiro al generar cruces.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para generar cruces.');
    }
  }

  Future<void> closeAndGenerateBracket(String tournamentId) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa');
    }

    try {
      final response = await _client
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/tournaments/$tournamentId/close-and-generate',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          json['message'] ?? 'No se pudieron cerrar inscripciones y generar cruces',
        );
      }
    } on TimeoutException {
      throw Exception(
        'La conexion con el backend expiro al cerrar inscripciones y generar cruces.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend para cerrar inscripciones y generar cruces.',
      );
    }
  }

  Future<void> startAdminMatch({
    required String tournamentId,
    required String matchId,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa');
    }

    try {
      final response = await _client
          .patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-matches/$matchId/start',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudo iniciar el partido');
      }
    } on TimeoutException {
      throw Exception('La conexion con el backend expiro al iniciar el partido.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para iniciar el partido.');
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
      throw Exception('No hay sesion activa');
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
              if (score != null && score.trim().isNotEmpty) 'score': score.trim(),
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudo registrar el ganador');
      }
    } on TimeoutException {
      throw Exception('La conexion con el backend expiro al registrar el ganador.');
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
      throw Exception('No hay sesion activa');
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
              if (score != null && score.trim().isNotEmpty) 'score': score.trim(),
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudo corregir el resultado');
      }
    } on TimeoutException {
      throw Exception('La conexion con el backend expiro al corregir el resultado.');
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
      throw Exception('No hay sesion activa');
    }

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/tournaments/$tournamentId/register-solo'),
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
        throw Exception(json['message'] ?? 'No se pudo completar la inscripcion');
      }
    } on TimeoutException {
      throw Exception('La conexion con el backend expiro al inscribirte.');
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
      throw Exception('No hay sesion activa');
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
        throw Exception(json['message'] ?? 'No se pudo completar la inscripcion');
      }
    } on TimeoutException {
      throw Exception('La conexion con el backend expiro al inscribirte.');
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
      throw Exception('No hay sesion activa');
    }

    try {
      final response = await _client
          .patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-registrations/$registrationId/pair/$partnerRegistrationId',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo emparejar la inscripcion');
      }

      return TournamentRecord.fromJson(json);
    } on TimeoutException {
      throw Exception('La conexion con el backend expiro al emparejar.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para emparejar.');
    }
  }

  Future<TournamentRecord> removeAdminRegistration({
    required String tournamentId,
    required String registrationId,
  }) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa');
    }

    try {
      final response = await _client
          .patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/tournaments/$tournamentId/admin-registrations/$registrationId/remove',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'No se pudo quitar la inscripcion');
      }

      return TournamentRecord.fromJson(json);
    } on TimeoutException {
      throw Exception('La conexion con el backend expiro al quitar la inscripcion.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend para quitar la inscripcion.');
    }
  }
}
