import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pgo/services/profile_service.dart';
import 'package:pgo/services/session_service.dart';

class _TestSessionService extends SessionService {
  @override
  Future<String?> getAccessToken() async => 'test-token';
}

void main() {
  Map<String, dynamic> profileResponse() => {
        'id': 'user-1',
        'name': 'Jugador',
        'email': 'player@example.com',
        'photoUrl': null,
        'experiencePoints': 0,
        'category': null,
        'preferredClub': null,
        'preferredSide': null,
        'racketModel': null,
        'experienceLevel': null,
        'rankingPosition': 0,
        'matchesPlayed': 0,
        'wins': 0,
        'winRate': 0,
        'weeklyStreak': 0,
        'friendsCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'socialNotificationsCount': 0,
        'matchHistory': const [],
      };

  test('does not send a base64 photoUrl', () async {
    final client = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload.containsKey('photoUrl'), isFalse);
      return http.Response(
        jsonEncode(profileResponse()),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = ProfileService(
      client: client,
      sessionService: _TestSessionService(),
    );

    await service.updateMyProfile(
      name: 'Jugador',
      photoUrl: 'data:image/png;base64,AAAA',
    );
  });

  test('keeps a valid remote photoUrl', () async {
    const photoUrl = 'https://lh3.googleusercontent.com/photo.jpg';
    final client = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['photoUrl'], photoUrl);
      return http.Response(
        jsonEncode({...profileResponse(), 'photoUrl': photoUrl}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = ProfileService(
      client: client,
      sessionService: _TestSessionService(),
    );

    await service.updateMyProfile(name: 'Jugador', photoUrl: photoUrl);
  });

  test('maps an unexpected profile update failure to human copy', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(
        '{"statusCode":500,"code":"profile_update_failed",'
        '"message":"No se pudo actualizar el perfil.",'
        '"requestId":"request-1"}',
        500,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = ProfileService(
      client: client,
      sessionService: _TestSessionService(),
    );

    expect(
      () => service.updateMyProfile(
        name: 'Jugador',
        category: '6ta categoria',
        categoryOrigin: 'manual',
        categoryIsProvisional: true,
        hasCompletedInitialOnboarding: true,
      ),
      throwsA(
        predicate(
          (error) =>
              error.toString().contains('No pudimos completar tu perfil.'),
        ),
      ),
    );
  });
}
