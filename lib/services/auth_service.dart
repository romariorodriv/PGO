import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/auth_response.dart';
import 'api_config.dart';
import 'session_service.dart';

class AuthService {
  static const _requestTimeout = Duration(seconds: 15);
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _googleInitialized = false;

  AuthService({
    http.Client? client,
    SessionService? sessionService,
  })  : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  final http.Client _client;
  final SessionService _sessionService;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) {
      return;
    }

    await _googleSignIn.initialize(
      clientId: ApiConfig.googleClientIdOrNull,
      serverClientId: ApiConfig.googleServerClientIdOrNull,
    );
    _googleInitialized = true;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': normalizedEmail,
              'password': password,
            }),
          )
          .timeout(_requestTimeout);

      return _handleAuthResponse(response);
    } on TimeoutException {
      throw Exception(
        'La conexion con el backend expiro. Verifica que Nest este corriendo y que la URL sea correcta.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend. Revisa la URL de API y tu emulador/dispositivo.',
      );
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(_requestTimeout);

      return _handleAuthResponse(response);
    } on TimeoutException {
      throw Exception(
        'La conexion con el backend expiro. Verifica que Nest este corriendo y que la URL sea correcta.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend. Revisa la URL de API y tu emulador/dispositivo.',
      );
    }
  }

  Future<AuthResponse> loginWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final String? idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google no devolvio un token de acceso valido. Revisa la configuracion de Google Sign-In.',
        );
      }

      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': idToken,
            }),
          )
          .timeout(_requestTimeout);

      return _handleAuthResponse(response);
    } on GoogleSignInException catch (error) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          throw Exception('Se cancelo el inicio de sesion con Google');
        case GoogleSignInExceptionCode.clientConfigurationError:
          throw Exception(
            'Google Sign-In no esta configurado correctamente. Revisa el client ID y la configuracion de Android.',
          );
        default:
          throw Exception(
            error.description ??
                'No se pudo iniciar sesion con Google en este momento.',
          );
      }
    } on TimeoutException {
      throw Exception(
        'La conexion con el backend expiro. Verifica que Nest este corriendo y que la URL sea correcta.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend. Revisa la URL de API y tu emulador/dispositivo.',
      );
    }
  }

  Future<AuthResponse> _handleAuthResponse(http.Response response) async {
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Error de autenticacion');
    }

    final authResponse = AuthResponse.fromJson(json);
    await _sessionService.saveAccessToken(authResponse.accessToken);
    return authResponse;
  }
}
