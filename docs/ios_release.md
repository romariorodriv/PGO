# iOS release

La app usa configuracion de compilacion mediante `--dart-define`. El valor de
`GOOGLE_SERVER_CLIENT_ID` debe ser el Web OAuth Client ID del proyecto, no el
client ID iOS.

## Build para dispositivo

```bash
flutter clean
flutter pub get
flutter build ios --release \
  --dart-define="GOOGLE_SERVER_CLIENT_ID=<WEB_OAUTH_CLIENT_ID>" \
  --dart-define="API_BASE_URL=https://pgoapp.com/api" \
  --dart-define="SHARE_BASE_URL=https://pgoapp.com"
```

## IPA

```bash
flutter build ipa --release \
  --dart-define="GOOGLE_SERVER_CLIENT_ID=<WEB_OAUTH_CLIENT_ID>" \
  --dart-define="API_BASE_URL=https://pgoapp.com/api" \
  --dart-define="SHARE_BASE_URL=https://pgoapp.com"
```

El fallback compilado de `API_BASE_URL` tambien es
`https://pgoapp.com/api`. No se deben agregar excepciones ATS para IPs o HTTP
en produccion.

## Diagnostico

Los logs `pgo.google` muestran la URL final de autenticacion, presencia del ID
token, timeout y status HTTP. No muestran el contenido del token.

```bash
flutter logs | grep -E "pgo.google|backend_request|backend_response"
```
