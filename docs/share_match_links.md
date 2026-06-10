# Enlaces compartidos de partidos

Ruta pública:

```text
https://pgoapp.com/partidos/{openMatchAlertId}
```

## DNS y HTTPS

- `pgoapp.com` debe tener un registro `A` o `AAAA` hacia el servidor de producción.
- El certificado HTTPS debe cubrir `pgoapp.com`.
- Android App Links no debe publicarse sobre HTTP ni con certificados inválidos.

## Nginx

Nginx debe enviar estas rutas al backend NestJS sin cambiar la URL:

```nginx
location /partidos/ {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location = /.well-known/assetlinks.json {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host $host;
}

location = /.well-known/apple-app-site-association {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host $host;
}
```

No agregar redirects a las dos rutas `/.well-known/`. Ambas deben responder
directamente con HTTP 200 y `Content-Type: application/json`.

## Variables de entorno

```text
ANDROID_APP_LINKS_SHA256=<PLAY_APP_SIGNING_SHA256>
APPLE_TEAM_ID=<APPLE_DEVELOPER_TEAM_ID>
PGO_ANDROID_STORE_URL=https://play.google.com/store/apps/details?id=com.pgo.app
PGO_IOS_STORE_URL=<APP_STORE_OR_TESTFLIGHT_URL>
```

## Universal Links en iOS

El target `Runner` debe usar el Bundle ID `com.pgo.app`, incluir
`Runner/Runner.entitlements` en `CODE_SIGN_ENTITLEMENTS` y tener la capability
Associated Domains con:

```text
applinks:pgoapp.com
```

En una Mac con Xcode se debe seleccionar el Apple Developer Team correcto en
Signing & Capabilities. El provisioning profile generado debe incluir
`com.apple.developer.associated-domains`. El Team ID de esa cuenta se configura
en el backend:

```text
APPLE_TEAM_ID=<APPLE_DEVELOPER_TEAM_ID>
```

Despues de cambiar AASA o el provisioning profile, eliminar e instalar
nuevamente la app mediante Xcode o TestFlight antes de probar el enlace.

`ANDROID_APP_LINKS_SHA256` acepta varios certificados separados por comas. En
producción debe incluir el SHA-256 de **App signing key certificate** mostrado
por Play Console. El certificado upload local no reemplaza el certificado de
Play App Signing.

Si `APPLE_TEAM_ID` todavía no existe, el endpoint AASA devuelve una
configuración válida sin aplicaciones y Android sigue funcionando.

## Validación Android

1. Instalar el build firmado que corresponde al certificado publicado.
2. Abrir el enlace desde WhatsApp y desde un navegador.
3. Probar con sesión iniciada y cerrada.
4. Probar con la app desinstalada para verificar el fallback HTML.
5. Verificar asociaciones:

```text
adb shell pm verify-app-links --re-verify com.pgo.app
adb shell pm get-app-links com.pgo.app
```

Si no hay una URL de tienda configurada para la plataforma detectada, el
fallback web muestra `Proximamente en tiendas`. En Android tambien debe
verificarse que `Abrir enlaces compatibles` este habilitado en los ajustes de
la aplicacion.

El dominio `pgoapp.com` debe aparecer como verificado.

Para validar navegación y errores controlados:

```text
adb shell am start -a android.intent.action.VIEW -d "https://pgoapp.com/partidos/no-es-uuid"
adb shell am start -a android.intent.action.VIEW -d "https://pgoapp.com/partidos/UUID_VALIDO"
```

El primer comando debe mostrar “Enlace de partido no válido”. El segundo debe
abrir el detalle correspondiente al UUID usado en la prueba.
