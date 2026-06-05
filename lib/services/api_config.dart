import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _productionBaseUrl = 'http://3.145.41.187/api';
  static const String _defaultAndroidGoogleClientId =
      '27858588529-0o3sreikgi33i0slkjdvhmms58sthj8i.apps.googleusercontent.com';
  static const String _defaultIosGoogleClientId =
      '27858588529-lumaihfvi9k7uvpc0f7g208r4hsdcuq8.apps.googleusercontent.com';

  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _overrideShareBaseUrl = String.fromEnvironment(
    'SHARE_BASE_URL',
    defaultValue: '',
  );
  static const String _overrideGoogleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3001/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return _productionBaseUrl;
      default:
        return 'http://localhost:3001/api';
    }
  }

  static String get shareBaseUrl {
    if (_overrideShareBaseUrl.isNotEmpty) {
      return _overrideShareBaseUrl;
    }

    final uri = Uri.parse(baseUrl);
    final publicSegments = uri.pathSegments
        .where(
            (segment) => segment.isNotEmpty && segment.toLowerCase() != 'api')
        .toList();
    return uri
        .replace(
          pathSegments: publicSegments,
          queryParameters: null,
          fragment: null,
        )
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }

  static String get googleClientId {
    if (_overrideGoogleClientId.isNotEmpty) {
      return _overrideGoogleClientId;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _defaultIosGoogleClientId;
      case TargetPlatform.android:
        return _defaultAndroidGoogleClientId;
      default:
        return '';
    }
  }

  static String? get googleClientIdOrNull =>
      googleClientId.isEmpty ? null : googleClientId;

  static String? get googleServerClientIdOrNull =>
      googleServerClientId.isEmpty ? null : googleServerClientId;
}
