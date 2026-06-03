import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/main_shell.dart';
import '../screens/confirmar_actividad_screen.dart';
import '../screens/open_match_alerts_screen.dart';
import '../screens/tournament_description_screen.dart';
import '../screens/tournament_live_screen.dart';
import '../models/app_notification.dart';
import '../widgets/pgo_bottom_nav.dart';
import 'api_config.dart';
import 'open_match_alert_service.dart';
import 'session_service.dart';
import 'tournament_service.dart';

@pragma('vm:entry-point')
Future<void> pgoFirebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('push_background type=${message.data['type'] ?? ''}');
  }
}

class PushNotificationService {
  PushNotificationService({
    http.Client? client,
    SessionService? sessionService,
  })  : _client = client ?? http.Client(),
        _sessionService = sessionService ?? SessionService();

  static const _requestTimeout = Duration(seconds: 15);
  static const _fcmSenderResetKey = 'fcm_sender_reset_id';
  static const _androidChannel = AndroidNotificationChannel(
    'pgo_default_sound',
    'PGO',
    description: 'Notificaciones principales de PGO',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('pgo_notification'),
  );

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static bool _initialized = false;
  static String? _lastHandledPayload;

  final http.Client _client;
  final SessionService _sessionService;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    await Firebase.initializeApp();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_pgo_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            unawaited(_handleNotificationData(decoded.cast<String, dynamic>()));
          }
        } catch (_) {}
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _logPushDebug(
      'permission platform=${defaultTargetPlatform.name} '
      'status=${permission.authorizationStatus.name}',
    );
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(
      pgoFirebaseMessagingBackgroundHandler,
    );
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    unawaited(messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    }));

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(registerCurrentDevice(tokenOverride: token));
    });
  }

  Future<void> registerCurrentDevice({String? tokenOverride}) async {
    if (kIsWeb) return;

    try {
      await initialize();
      final accessToken = await _sessionService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return;

      await _resetTokenIfFirebaseSenderChanged();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _waitForApnsToken();
        _logPushDebug('apns_token=${_maskToken(apnsToken)}');
      }
      final fcmToken =
          tokenOverride ?? await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        _logPushDebug('fcm_token=null platform=${defaultTargetPlatform.name}');
        return;
      }
      _logPushDebug(
        'fcm_token=${_maskToken(fcmToken)} platform=${defaultTargetPlatform.name}',
      );

      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/notifications/devices'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'token': fcmToken,
              'platform': defaultTargetPlatform.name,
            }),
          )
          .timeout(_requestTimeout);
      _logPushDebug(
        'push_register status=${response.statusCode} '
        'platform=${defaultTargetPlatform.name}',
      );
    } catch (error) {
      debugPrint('Push device registration skipped: $error');
      // No bloquea login ni navegacion si el registro push falla.
    }
  }

  Future<void> _resetTokenIfFirebaseSenderChanged() async {
    final senderId = Firebase.app().options.messagingSenderId ?? '';
    if (senderId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_fcmSenderResetKey) == senderId) return;

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    await prefs.setString(_fcmSenderResetKey, senderId);
  }

  Future<String?> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final token = await FirebaseMessaging.instance.getAPNSToken();
      if (token != null && token.isNotEmpty) return token;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  static void _logPushDebug(String message) {
    if (kDebugMode) debugPrint('pgo_push $message');
  }

  static String _maskToken(String? token) {
    if (token == null || token.isEmpty) return 'null';
    if (token.length <= 12) return '${token.substring(0, 2)}...';
    return '${token.substring(0, 6)}...${token.substring(token.length - 6)}';
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      payload: jsonEncode(message.data),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@drawable/ic_pgo_notification',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('pgo_notification'),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    unawaited(_handleNotificationData(message.data));
  }

  static Future<void> _handleNotificationData(
    Map<String, dynamic> rawData,
  ) async {
    final data = rawData.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
    final payloadKey = jsonEncode(data);
    if (_lastHandledPayload == payloadKey) return;
    _lastHandledPayload = payloadKey;

    final sessionToken = await SessionService().getAccessToken();
    if (sessionToken == null || sessionToken.isEmpty) {
      return;
    }

    final type = (data['type'] ?? '').trim();
    final normalizedType = type.toUpperCase();

    if (normalizedType.startsWith('OPEN_MATCH_') ||
        data['screen'] == 'open_match_alert') {
      await _openMatchAlert(data['alertId'] ?? data['openMatchAlertId'] ?? '');
      return;
    }

    if (_isMatchConfirmationNotification(data, normalizedType, type)) {
      await _openMatchConfirmation(data);
      return;
    }

    if (normalizedType == 'FRIEND_REQUEST' ||
        normalizedType == 'FRIEND_ACCEPTED' ||
        type == 'friend_request' ||
        type == 'friend_accepted' ||
        data['screen'] == 'profile_friends') {
      await _openProfileFriends();
      return;
    }

    if (type.startsWith('tournament_') ||
        normalizedType.startsWith('TOURNAMENT_') ||
        normalizedType == 'MATCH_SCORE_REQUIRED' ||
        normalizedType == 'TOURNAMENT_INVITATION' ||
        data.containsKey('tournamentId')) {
      final tournamentId = data['tournamentId'] ?? '';
      final shouldOpenLive = {
        'TOURNAMENT_BRACKET_READY',
        'TOURNAMENT_MATCH_ASSIGNED',
        'TOURNAMENT_MATCH_STARTED',
        'TOURNAMENT_NEXT_MATCH_READY',
        'MATCH_SCORE_REQUIRED',
        'MATCH_STARTED',
        'MATCH_FINISHED',
      }.contains(normalizedType);
      await _openTournament(tournamentId, live: shouldOpenLive);
      return;
    }

    if (normalizedType == 'MATCH_RESULT_RECORDED' ||
        normalizedType == 'MATCH_RESULT_CONFIRMATION_REQUIRED' ||
        normalizedType == 'XP_GAINED' ||
        normalizedType == 'XP_LEVEL_UP' ||
        normalizedType == 'XP_NEAR_LEVEL_UP') {
      await _openProfile();
      return;
    }

    if (normalizedType == 'MATCH_INVITATION') {
      await _openHome();
      return;
    }

    await _openHome();
  }

  static Future<NavigatorState?> _waitForNavigator() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final navigator = navigatorKey.currentState;
      if (navigator != null) return navigator;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return navigatorKey.currentState;
  }

  static Future<void> _openMatchAlert(String alertId) async {
    final navigator = await _waitForNavigator();
    if (navigator == null) return;

    try {
      final alert = await OpenMatchAlertService().getAlert(alertId);
      navigator.push(
        MaterialPageRoute(
          builder: (_) => OpenMatchDetailScreen(alert: alert),
        ),
      );
    } catch (_) {
      navigator.pushAndRemoveUntil(
        MainShell.route(initialTab: PgoNavTab.alerts),
        (_) => false,
      );
    }
  }

  static Future<void> _openMatchConfirmation(
    Map<String, String> data,
  ) async {
    final navigator = await _waitForNavigator();
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ConfirmarActividadScreen(
          notification: PgoAppNotification(
            id: data['notificationId'] ??
                data['matchId'] ??
                'match-confirmation',
            type: 'MATCH_RESULT_CONFIRMATION_REQUIRED',
            title: data['title'] ?? 'Tomás registró un match contigo',
            body: data['body'] ??
                'Revisa el marcador antes de guardarlo en tu historial.',
            data: Map<String, dynamic>.from(data),
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  static bool _isMatchConfirmationNotification(
    Map<String, String> data,
    String normalizedType,
    String rawType,
  ) {
    final title = (data['title'] ?? '').toLowerCase();
    final body = (data['body'] ?? '').toLowerCase();
    final screen = data['screen'] ?? '';

    if (screen == 'confirmar_actividad') return true;
    if (normalizedType == 'MATCH_RESULT_CONFIRMATION_REQUIRED' ||
        rawType == 'match_result_confirmation_required') {
      return true;
    }
    if (normalizedType == 'MATCH_RESULT_RECORDED' ||
        rawType == 'match_result_recorded') {
      return title.contains('resultado') ||
          body.contains('resultado') ||
          body.contains('revisa tu actividad');
    }
    return title.contains('resultado') && body.contains('actividad');
  }

  static Future<void> _openTournament(
    String tournamentId, {
    required bool live,
  }) async {
    final navigator = await _waitForNavigator();
    if (navigator == null) return;

    if (tournamentId.isEmpty) {
      navigator.pushAndRemoveUntil(
        MainShell.route(initialTab: PgoNavTab.tournaments),
        (_) => false,
      );
      return;
    }

    try {
      final tournament = await TournamentService().getTournament(tournamentId);
      navigator.push(
        MaterialPageRoute(
          builder: (_) => live
              ? TournamentLiveScreen(tournament: tournament)
              : TournamentDescriptionScreen(tournament: tournament),
        ),
      );
    } catch (_) {
      navigator.pushAndRemoveUntil(
        MainShell.route(initialTab: PgoNavTab.tournaments),
        (_) => false,
      );
    }
  }

  static Future<void> _openProfileFriends() async {
    final navigator = await _waitForNavigator();
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MainShell.route(
        initialTab: PgoNavTab.profile,
        openProfileFriendsOnStart: true,
      ),
      (_) => false,
    );
  }

  static Future<void> _openProfile() async {
    final navigator = await _waitForNavigator();
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MainShell.route(initialTab: PgoNavTab.profile),
      (_) => false,
    );
  }

  static Future<void> _openHome() async {
    final navigator = await _waitForNavigator();
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(MainShell.route(), (_) => false);
  }
}
