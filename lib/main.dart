import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/colors.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/push_notification_service.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    (error) => debugPrint('Push notification initialization failed: $error'),
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

class _AppEntryScreen extends StatelessWidget {
  const _AppEntryScreen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SessionService().getAccessToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F7F8),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          PushNotificationService().registerCurrentDevice().catchError(
            (error) => debugPrint('Push registration failed: $error'),
          );
          return const MainShell();
        }

        return const LoginScreen();
      },
    );
  }
}
