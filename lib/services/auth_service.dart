import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/auth_response.dart';
import 'api_config.dart';
import 'push_notification_service.dart';
import 'session_service.dart';

class AuthService {
  static const _requestTimeout = Duration(seconds: 15);
  static const _googleSignInTimeout = Duration(seconds: 30);
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
      _logGoogleEvent('initialize_skipped already_initialized=true');
      return;
    }

    _logGoogleEvent(
      'initialize_start platform=${defaultTargetPlatform.name} '
      'server_client_id_configured=${ApiConfig.googleServerClientIdOrNull != null}',
    );
    if (defaultTargetPlatform == TargetPlatform.android &&
        ApiConfig.googleServerClientIdOrNull == null) {
      _logGoogleEvent('initialize_failed reason=missing_server_client_id');
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

    await _googleSignIn
        .initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    )
        .timeout(
      _googleSignInTimeout,
      onTimeout: () {
        _logGoogleEvent('initialize_failed reason=timeout');
        throw const _GoogleAuthTimeout('initialize');
      },
    );
    _googleInitialized = true;
    _logGoogleEvent('initialize_success');
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
        'No pudimos conectar. Revisa tu internet e intenta otra vez.',
      );
    } on http.ClientException {
      throw Exception(
        'No pudimos conectar. Revisa tu internet e intenta otra vez.',
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
        'No pudimos conectar. Revisa tu internet e intenta otra vez.',
      );
    } on http.ClientException {
      throw Exception(
        'No pudimos conectar. Revisa tu internet e intenta otra vez.',
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
      return await _loginWithGoogle().timeout(
        _googleSignInTimeout,
        onTimeout: () {
          _logGoogleEvent('login_failed reason=overall_timeout');
          throw const _GoogleAuthTimeout('overall');
        },
      );
    } on _GoogleAuthTimeout catch (error) {
      _logGoogleEvent('google_auth_timeout stage=${error.stage}');
      throw Exception(
        'La conexión tardó demasiado. Revisa tu internet e intenta otra vez.',
      );
    }
  }

  Future<AuthResponse> _loginWithGoogle() async {
    try {
      _logGoogleEvent('login_start');
      await _ensureGoogleInitialized();

      _logGoogleEvent('account_selection_start');
      final GoogleSignInAccount account =
          await _googleSignIn.authenticate().timeout(
        _googleSignInTimeout,
        onTimeout: () {
          _logGoogleEvent('account_selection_failed reason=timeout');
          throw const _GoogleAuthTimeout('account_selection');
        },
      );
      _logGoogleEvent('account_selection_success account_present=true');
      final String? idToken = account.authentication.idToken;
      _logGoogleEvent(
        'id_token_result present=${idToken != null && idToken.isNotEmpty}',
      );

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google no devolvio un token de acceso valido. Revisa la configuracion de Google Sign-In.',
        );
      }

      final authUrl = Uri.parse('${ApiConfig.baseUrl}/auth/google');
      _logGoogleEvent(
        'backend_request_start url=$authUrl '
        'timeout_seconds=${_requestTimeout.inSeconds}',
      );
      final response = await _client
          .post(
            authUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': idToken,
            }),
          )
          .timeout(_requestTimeout);
      _logGoogleEvent('backend_response status=${response.statusCode}');

      return _handleAuthResponse(response);
    } on GoogleSignInException catch (error) {
      _logGoogleEvent(
        'google_sign_in_exception code=${error.code.name} '
        'developer_error=${error.code == GoogleSignInExceptionCode.clientConfigurationError}',
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
    } on _GoogleAuthTimeout catch (error) {
      _logGoogleEvent('google_auth_timeout stage=${error.stage}');
      throw Exception(
        'Google no respondió y el inicio de sesión fue cancelado. Verifica Google Play Services, la conexión y la configuración SHA de la app.',
      );
    } on PlatformException catch (error) {
      _logGoogleEvent(
        'platform_exception code=${_safeLogValue(error.code)} '
        'developer_error=${error.code == '10' || error.code == 'DEVELOPER_ERROR'}',
      );
      throw Exception(
        'Google Sign-In falló antes de contactar al servidor. Revisa la firma release, SHA-1, SHA-256 y Web client ID.',
      );
    } on TimeoutException catch (error) {
      _logGoogleEvent(
        'backend_request_failed reason=timeout '
        'type=${_safeLogValue(error.runtimeType.toString())} '
        'url=${ApiConfig.baseUrl}/auth/google',
      );
      throw Exception(
        'No pudimos conectar. Revisa tu internet e intenta otra vez.',
      );
    } on http.ClientException catch (error) {
      _logGoogleEvent(
        'backend_request_failed reason=client_exception '
        'type=${_safeLogValue(error.runtimeType.toString())} '
        'url=${ApiConfig.baseUrl}/auth/google',
      );
      throw Exception(
        'No pudimos conectar. Revisa tu internet e intenta otra vez.',
      );
    } catch (error) {
      _logGoogleEvent(
        'login_failed type=${_safeLogValue(error.runtimeType.toString())}',
      );
      rethrow;
    }
  }

  Future<AuthResponse> _handleAuthResponse(http.Response response) async {
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Error de autenticacion');
    }

    final authResponse = AuthResponse.fromJson(json);
    await _sessionService.saveAccessToken(authResponse.accessToken);
    unawaited(
      PushNotificationService().registerCurrentDevice().catchError((error) {
        _logGoogleEvent(
          'push_register_background_failed '
          'type=${_safeLogValue(error.runtimeType.toString())}',
        );
      }),
    );
    return authResponse;
  }

  static void _logGoogleEvent(String message) {
    developer.log(message, name: 'pgo.google');
  }

  static String _safeLogValue(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
}

class _GoogleAuthTimeout implements Exception {
  const _GoogleAuthTimeout(this.stage);

  final String stage;
}
