import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/colors.dart';
import 'models/profile_summary.dart';
import 'screens/initial_onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/backend_health_service.dart';
import 'services/profile_service.dart';
import 'services/push_notification_service.dart';
import 'services/session_service.dart';
import 'utils/initial_category_onboarding.dart';
import 'utils/match_share_link.dart';
import 'utils/post_auth_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(
    pgoFirebaseMessagingBackgroundHandler,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF7F7F8),
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Color(0xFFF7F7F8),
    ),
  );
  runApp(const MyApp());

  unawaited(PushNotificationService().initialize().catchError(
        (error) =>
            debugPrint('Push notification initialization failed: $error'),
      ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: true,
    );
    final interTextTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);
    final interPrimaryTextTheme =
        GoogleFonts.interTextTheme(baseTheme.primaryTextTheme);

    return MaterialApp(
      navigatorKey: PushNotificationService.navigatorKey,
      title: 'PGO',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
      theme: baseTheme.copyWith(
        textTheme: interTextTheme,
        primaryTextTheme: interPrimaryTextTheme,
        dialogTheme: DialogThemeData(
          titleTextStyle: interTextTheme.titleLarge,
          contentTextStyle: interTextTheme.bodyMedium,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          modalBarrierColor: Colors.black.withValues(alpha: 0.35),
        ),
        chipTheme: baseTheme.chipTheme.copyWith(
          labelStyle: interTextTheme.labelMedium,
          secondaryLabelStyle: interTextTheme.labelMedium,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: interTextTheme.labelLarge,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: interTextTheme.labelLarge,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: interTextTheme.labelLarge,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: AppColors.headerToolbarHeight,
        ),
      ),
      home: const _AppEntryScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AppEntryScreen extends StatefulWidget {
  const _AppEntryScreen();

  @override
  State<_AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<_AppEntryScreen> {
  final AppLinks _appLinks = AppLinks();
  final Stopwatch _watch = Stopwatch();
  bool _slow = false;
  bool _failed = false;
  String _error = '';
  Future<Widget>? _bootstrapFuture;
  Timer? _slowTimer;
  StreamSubscription<Uri>? _matchLinkSubscription;
  bool _initialLinkCaptured = false;

  @override
  void initState() {
    super.initState();
    _matchLinkSubscription = _appLinks.uriLinkStream.listen((uri) {
      unawaited(_captureMatchLinkWhileLoggedOut(uri));
    });
    _start();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _matchLinkSubscription?.cancel();
    super.dispose();
  }

  void _log(String label) {
    debugPrint('pgo_startup $label ${_watch.elapsedMilliseconds}ms');
  }

  void _start() {
    _watch
      ..reset()
      ..start();
    _log('app_start');
    _slowTimer?.cancel();
    _slowTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _slow = true);
    });
    setState(() {
      _slow = false;
      _failed = false;
      _error = '';
      _bootstrapFuture = _bootstrap();
    });
  }

  Future<Widget> _bootstrap() async {
    try {
      await _captureInitialMatchLink();
      final token = await SessionService().getAccessToken();
      _log('auth_loaded');
      if (token == null || token.isEmpty) {
        _slowTimer?.cancel();
        _log('first_screen_ready');
        return const LoginScreen();
      }

      try {
        await _retry(
          'backend_health',
          () => BackendHealthService().check(
            timeout: const Duration(seconds: 8),
          ),
        );
        _log('backend_health_ok');
      } catch (error) {
        if (!_isEndpointNotFound(error)) rethrow;
        _log('backend_health_404_ignored');
        debugPrint('PGO startup: /health no existe; validando con /profile/me');
      }
      final profile = await _retry('profile', ProfileService().getMyProfile);
      _log('profile_loaded');
      final resolvedProfile = await _ensureInitialCategoryOnboarding(profile);
      unawaited(PushNotificationService().registerCurrentDevice().catchError(
            (error) => debugPrint('Push registration failed: $error'),
          ));
      _slowTimer?.cancel();
      _log('first_screen_ready');
      return MainShell(initialProfile: resolvedProfile);
    } catch (error) {
      _slowTimer?.cancel();
      if (_isAuthError(error)) {
        await SessionService().clear();
        _log('auth_cleared');
        return const LoginScreen();
      }
      final message = _startupErrorMessage(error);
      if (mounted) {
        setState(() {
          _failed = true;
          _error = message;
        });
      }
      return _StartupLoading(
        failed: true,
        error: _error,
        onRetry: _start,
      );
    }
  }

  Future<void> _captureInitialMatchLink() async {
    if (_initialLinkCaptured) return;
    _initialLinkCaptured = true;
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null && parseMatchShareLink(uri).isMatchPath) {
        await savePendingDeepLink(uri);
      }
    } catch (error) {
      debugPrint('Initial match link capture failed: $error');
    }
  }

  Future<void> _captureMatchLinkWhileLoggedOut(Uri uri) async {
    if (!parseMatchShareLink(uri).isMatchPath) return;
    final token = await SessionService().getAccessToken();
    if (token == null || token.isEmpty) {
      await savePendingDeepLink(uri);
    }
  }

  Future<T> _retry<T>(String label, Future<T> Function() action) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        if (attempt > 1 && mounted) setState(() => _slow = true);
        final result = await action();
        if (attempt > 1) _log('${label}_ok_attempt_$attempt');
        return result;
      } catch (error) {
        if (_isAuthError(error)) rethrow;
        if (!_isRetryable(error)) rethrow;
        lastError = error;
        _log('${label}_fail_attempt_$attempt');
        if (attempt < 3) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    throw lastError ?? Exception('Backend no disponible');
  }

  bool _isRetryable(Object error) {
    final value = error.toString().toLowerCase();
    return value.contains('timeout') ||
        value.contains('network_error') ||
        value.contains('clientexception') ||
        value.contains('socket') ||
        value.contains('server_unavailable') ||
        value.contains('500') ||
        value.contains('502') ||
        value.contains('503') ||
        value.contains('504');
  }

  bool _isEndpointNotFound(Object error) {
    return error.toString().toLowerCase().contains('endpoint_not_found_404') ||
        error.toString().contains('404');
  }

  String _startupErrorMessage(Object error) {
    if (_isEndpointNotFound(error)) return 'Endpoint no encontrado (404)';
    final value = error.toString().toLowerCase();
    if (value.contains('timeout')) return 'Sin internet o conexión lenta';
    if (value.contains('network_error') ||
        value.contains('clientexception') ||
        value.contains('socket')) {
      return 'No pudimos conectar con el servidor';
    }
    if (value.contains('server_unavailable') || value.contains('5')) {
      return 'Servidor no disponible';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  bool _isAuthError(Object error) {
    final value = error.toString().toLowerCase();
    return value.contains('auth_expired') ||
        value.contains('unauthorized') ||
        value.contains('forbidden') ||
        value.contains('401') ||
        value.contains('403');
  }

  Future<ProfileSummary> _ensureInitialCategoryOnboarding(
    ProfileSummary profile,
  ) async {
    if (!needsInitialCategoryOnboarding(profile)) return profile;

    final result = await _openInitialCategoryOnboarding(profile);
    if (result == null) {
      throw Exception('ONBOARDING_CANCELLED');
    }

    final updated = await _retry(
      'save_initial_category',
      () => ProfileService().updateMyProfile(
        name: result.name,
        photoUrl: result.photoUrl,
        category: result.category,
        preferredClub: result.preferredClub,
        preferredSide: result.preferredSide,
        categoryOrigin: result.categoryOrigin,
        categoryIsProvisional: result.categoryIsProvisional,
        categorySuggested: result.quizCompletion?.result.suggestedCategory,
        categoryPreliminary: result.quizCompletion?.result.preliminaryCategory,
        categoryMaxApplied: result.quizCompletion?.result.maxAppliedCategory,
        categoryScore: result.quizCompletion?.result.totalScore,
        categoryQuizAnswers: result.quizCompletion?.answers,
        hasCompletedInitialOnboarding: true,
      ),
    );
    try {
      await ProfileService().markInitialOnboardingComplete();
    } catch (_) {}
    return updated;
  }

  Future<InitialOnboardingResult?> _openInitialCategoryOnboarding(
    ProfileSummary profile,
  ) {
    final completer = Completer<InitialOnboardingResult?>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final result = await Navigator.of(context).push<InitialOnboardingResult>(
        MaterialPageRoute(
          builder: (context) => InitialOnboardingScreen(
            initialName: profile.name,
            email: profile.email,
            initialPhotoUrl: profile.photoUrl,
            initialPhone: '',
          ),
        ),
      );
      if (!completer.isCompleted) completer.complete(result);
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (_failed) {
          return _StartupLoading(
            failed: true,
            error: _error,
            onRetry: _start,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return _StartupLoading(
            slow: _slow,
            onRetry: _start,
          );
        }
        return snapshot.data ?? const LoginScreen();
      },
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading({
    this.slow = false,
    this.failed = false,
    this.error = '',
    required this.onRetry,
  });

  final bool slow;
  final bool failed;
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/pgoIconoAPP.png', height: 88),
                const SizedBox(height: 24),
                Text(
                  failed
                      ? 'No pudimos conectar con el servidor'
                      : slow
                          ? 'Estamos conectando con PGO...'
                          : 'Preparando tu experiencia...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!failed) ...[
                  const SizedBox(height: 22),
                  const CircularProgressIndicator(
                    color: AppColors.PrimaryGreen,
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Text(
                    error.isEmpty
                        ? 'Revisa tu conexión e intenta de nuevo.'
                        : error,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.PrimaryGreen,
                      foregroundColor: AppColors.SecondBlue,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
