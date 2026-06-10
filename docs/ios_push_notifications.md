# Push notifications en iOS

## Firebase y APNs

El proyecto Firebase de `GoogleService-Info.plist` debe tener configurada una
APNs Authentication Key para la app iOS `com.pgo.app`.

En Firebase Console:

1. Abrir Project Settings.
2. Abrir Cloud Messaging.
3. En Apple app configuration, seleccionar `com.pgo.app`.
4. Cargar una clave APNs `.p8`.
5. Configurar su Key ID.
6. Configurar el Team ID `8ZJ2RQN2W7`.

La clave `.p8` no debe copiarse al repositorio ni al servidor NestJS.

El error Firebase Admin `messaging/third-party-auth-error` indica que Firebase
no pudo autenticarse ante APNs. Debe resolverse en Firebase Console antes de
esperar entregas push en iPhone.

## Firma iOS

En una Mac, abrir `ios/Runner.xcworkspace` y verificar en Runner:

- Bundle ID `com.pgo.app`.
- Capability Push Notifications.
- Capability Background Modes con Remote notifications.
- Associated Domains conserva `applinks:pgoapp.com`.
- El provisioning profile incluye `aps-environment` y Associated Domains.
- Debug usa APNs development.
- TestFlight/App Store usa APNs production.

Reinstalar la app despues de regenerar el provisioning profile.

## Logs seguros

Con la app instalada desde Xcode:

```bash
flutter logs | grep -E "pgo.push|FirebaseMessaging|APNS|APNs"
```

Secuencia esperada:

```text
initialize_start platform=iOS
permission platform=iOS status=authorized
apns_token present=true length=...
fcm_token present=true length=...
backend_register_start platform=iOS
backend_register_result status=200 platform=iOS
```

Los logs no incluyen el contenido de los tokens.
