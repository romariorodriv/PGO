import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/auth_response.dart';
import 'api_config.dart';
import 'push_notification_service.dart';
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

    if (defaultTargetPlatform == TargetPlatform.android &&
        ApiConfig.googleServerClientIdOrNull == null) {
      throw Exception(
        'Falta GOOGLE_SERVER_CLIENT_ID para Google Sign-In en Android. '
        'Debes usar el web client id del proyecto Firebase/Google Cloud.',
      );
    }

    // Android (Credential Manager) requires serverClientId.
    // iOS uses clientId. Keep serverClientId when available for iOS too.
    final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final String? clientId = isAndroid ? null : ApiConfig.googleClientIdOrNull;
    final String? serverClientId = isAndroid
        ? (ApiConfig.googleServerClientIdOrNull ??
            ApiConfig.googleClientIdOrNull)
        : (ApiConfig.googleServerClientIdOrNull ??
            '27858588529-ao5coqdfo1bbfr4l38l0ig4gkk0i1a9c.apps.googleusercontent.com');

    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
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
        'La conexión con el backend expiró. Verifica que Nest esté corriendo y que la URL sea correcta.',
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
        'La conexión con el backend expiró. Verifica que Nest esté corriendo y que la URL sea correcta.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar al backend. Revisa la URL de API y tu emulador/dispositivo.',
      );
    }
  }

  Future<void> forgotPassword({required String email}) async {
    final normalizedEmail = email.toLowerCase().trim();

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': normalizedEmail}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'No se pudo enviar la solicitud');
      }
    } on TimeoutException {
      throw Exception('La conexión con el backend expiró.');
    } on http.ClientException {
      throw Exception('No se pudo conectar al backend.');
    }
  }

  Future<void> logout() async {
    await _sessionService.clear();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<AuthResponse> loginWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
      final String? clientId = isAndroid ? null : ApiConfig.googleClientIdOrNull;
      final String serverClientId = isAndroid
          ? (ApiConfig.googleServerClientIdOrNull ??
              ApiConfig.googleClientIdOrNull ??
              '')
          : (ApiConfig.googleServerClientIdOrNull ??
              '27858588529-ao5coqdfo1bbfr4l38l0ig4gkk0i1a9c.apps.googleusercontent.com');

      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      _logGoogleDebug(
        'google_auth account email=${_maskEmail(account.email)} '
        'platform=${defaultTargetPlatform.name}',
      );
      _logGoogleDebug(
        'google_auth config platform=${defaultTargetPlatform.name} '
        'clientIdIos=${clientId?.startsWith("27858588529") == true} '
        'serverClientId=${serverClientId.startsWith("27858588529")}',
      );
      final String? idToken = account.authentication.idToken;
      _logGoogleDebug('google_auth idToken=${idToken == null ? 'null' : 'ok'}');

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google no devolvio un token de acceso valido. Revisa la configuracion de Google Sign-In.',
        );
      }

      _logGoogleDebug(
        'google_auth request ${ApiConfig.baseUrl}/auth/google '
        'platform=${defaultTargetPlatform.name}',
      );
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': idToken,
            }),
          )
          .timeout(_requestTimeout);
      _logGoogleDebug(
        'google_auth response status=${response.statusCode} '
        'body=${_shortBody(response.body)}',
      );

      return _handleAuthResponse(response);
    } on GoogleSignInException catch (error) {
      _logGoogleDebug(
        'google_auth exception code=${error.code} desc=${error.description}',
      );
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          throw Exception('Se canceló el inicio de sesión con Google');
        case GoogleSignInExceptionCode.clientConfigurationError:
          throw Exception(
            'Google Sign-In no está configurado correctamente. En Android revisa package name, SHA-1 y serverClientId.',
          );
        default:
          throw Exception(
            error.description ??
                'No se pudo iniciar sesión con Google en este momento.',
          );
      }
    } on TimeoutException {
      throw Exception(
        'La conexión con el backend expiró. Verifica que Nest esté corriendo y que la URL sea correcta.',
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
    await PushNotificationService().registerCurrentDevice();
    return authResponse;
  }

  static void _logGoogleDebug(String message) {
    if (kDebugMode) debugPrint('pgo_google $message');
  }

  static String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final local = parts.first;
    final domain = parts.last;
    final visible = local.isEmpty ? '***' : '${local[0]}***';
    return '$visible@$domain';
  }

  static String _shortBody(String body) {
    final trimmed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed.length <= 120) return trimmed;
    return '${trimmed.substring(0, 120)}...';
  }
}
