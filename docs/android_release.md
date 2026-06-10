# Android release

## Google Sign-In

La app lee `GOOGLE_SERVER_CLIENT_ID` en tiempo de compilacion mediante
`String.fromEnvironment` en `lib/services/api_config.dart`. En Android,
`AuthService` lo entrega a `google_sign_in` como `serverClientId`.

El valor debe ser el **Web OAuth 2.0 client ID** del mismo proyecto de
Firebase/Google Cloud. No se debe usar el Android client ID.

Esta configuracion:

- se inyecta con `--dart-define`;
- no se lee desde un archivo `.env`;
- no depende de un flavor;
- no se obtiene automaticamente de `google-services.json` ni del
  `AndroidManifest.xml`.

## APK release

Desde la raiz del proyecto:

```powershell
flutter build apk --release --dart-define="GOOGLE_SERVER_CLIENT_ID=<WEB_OAUTH_CLIENT_ID>"
```

Salida esperada:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## AAB release

Desde la raiz del proyecto:

```powershell
flutter build appbundle --release `
  --dart-define="GOOGLE_SERVER_CLIENT_ID=<WEB_OAUTH_CLIENT_ID>" `
  --dart-define="API_BASE_URL=https://pgoapp.com/api" `
  --dart-define="SHARE_BASE_URL=https://pgoapp.com"
```

Salida esperada:

```text
build/app/outputs/bundle/release/app-release.aab
```

El archivo `android/key.properties` y el keystore de release deben existir en
la maquina que genera el artefacto. No deben publicarse en Git.

## Defines adicionales

`ApiConfig` tambien permite sustituir URLs durante el build. El comando de
release recomendado ya incluye estos defines:

```powershell
flutter build appbundle --release `
  --dart-define="GOOGLE_SERVER_CLIENT_ID=<WEB_OAUTH_CLIENT_ID>" `
  --dart-define="API_BASE_URL=https://pgoapp.com/api" `
  --dart-define="SHARE_BASE_URL=https://pgoapp.com"
```

Antes de distribuir un artefacto, verificar en el mismo proyecto Google Cloud
que exista un cliente OAuth Android para `com.pgo.app` con los certificados
SHA-1 requeridos para el canal de firma usado. Para Google Play, esto incluye
el SHA-1 de Play App Signing. El valor del `--dart-define` sigue siendo el
client ID del cliente OAuth Web.

## Diagnostico de Google Sign-In

Instalacion limpia del APK:

```powershell
adb uninstall com.pgo.app
adb install build/app/outputs/flutter-apk/app-release.apk
```

Logs seguros del flujo Google:

```powershell
adb logcat -c
adb logcat | findstr /I "pgo.google GoogleSignIn CredentialManager ApiException DEVELOPER_ERROR"
```

La app registra inicio, seleccion de cuenta, presencia del ID token, inicio de
la llamada al backend y codigo HTTP. No registra correos, client IDs ni tokens.

Los APK modernos pueden estar firmados solo con APK Signature Scheme v2/v3.
En ese caso `keytool -printcert -jarfile` puede responder que no es un JAR
firmado. Verificar el certificado efectivo con:

```powershell
$apksigner = Get-ChildItem "$env:LOCALAPPDATA\Android\sdk\build-tools" `
  -Filter apksigner.bat -Recurse |
  Sort-Object FullName -Descending |
  Select-Object -First 1

& $apksigner.FullName verify --verbose --print-certs `
  build/app/outputs/flutter-apk/app-release.apk
```

El SHA-1 y SHA-256 mostrados deben corresponder a una app Android
`com.pgo.app` registrada en Firebase. Despues de agregar fingerprints, descargar
un `google-services.json` nuevo y recompilar desde cero.
