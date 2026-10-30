# Auditoría técnica inicial PGoWeb

Fecha de pruebas: 1 de octubre de 2026, Lima. Sitio: https://pgoapp.com/.
Base: ZIP PGO-FRONTEND-FIGMA-BOOKING-FLOW-FIX (1).zip.
Este paquete es una copia corregida para revisión y despliegue por el propietario. No se ha publicado ni modificado la web alojada. No se dispone del código backend.

## Resultado principal

La sesión de la cuenta de prueba se mantuvo al recargar el perfil, navegar a reservas y volver atrás. No se reprodujo una pérdida real de sesión en esos pasos. Sí se reprodujo una cabecera incorrecta: inicio y mis reservas muestran Iniciar sesión y Crear cuenta estando autenticado. Mis reservas devuelve el listado vacío de la cuenta, y al volver al perfil sigue apareciendo el usuario. Guardar el access token sólo en memoria no es por sí mismo un defecto: su recuperación por cookie funcionó en estas pruebas. No se recomienda solucionar esto almacenando tokens en localStorage.

El principal bloqueo de reservas es el selector de clubes vacío. La UI no distingue falta de clubes de falta de horarios. Sin clubes/canchas de prueba no es posible validar una reserva, pago, cancelación ni conflictos simultáneos.

## Matriz de pruebas en la web alojada

| Flujo | Resultado y alcance |
|---|---|
| Registro | El propietario completó el registro. Se verificó después un perfil autenticado; no se automatizó ni comprobó exhaustivamente la validación del registro. |
| Recargar perfil | Conserva el usuario autenticado. |
| Perfil → Reservar → Atrás | Conserva el perfil y sesión. |
| Reservar | Selector de Club vacío; continuar deshabilitado. Cambiar a mañana no resuelve el bloqueo. |
| Mis reservas | Listado propio sin próximas reservas ni historial; cabecera incorrecta de invitado. |
| Gestión del club como jugador | Deniega acceso: No administras este club. El mensaje ofrece Ingresar aunque ya hay sesión. |
| Recuperar contraseña | El enlace no produce acción; confirmado también en el código. |
| Crear cuenta gratis desde inicio | Lleva a reservas y luego login estando sin sesión; no al registro. |
| Reserva/checkout/confirmación/cancelación | Bloqueado por falta de clubes. Revisión de código, sin operación real. |
| Gestión con rol de club, superadministración y aislamiento entre clubes | Pendiente: no se dispone de esos roles/cuentas. No se concedieron permisos. |
| Login con contraseña, logout y renovación tras vencimiento real | Pendiente en vivo; no se solicitó ni inspeccionó la contraseña. |

## Hallazgos del código

1. Errores de conexión, permisos o servidor se convierten en redirecciones al login en perfil, checkout, confirmación y administración. Esto puede simular una sesión perdida.
2. En reserva se detecta autenticación con una expresión sobre el texto del error; se reemplazó por código HTTP 401.
3. Categoría se guarda como pista en sessionStorage, no se envía al backend. No hay garantía de sincronización entre dispositivos.
4. Métodos de pago del checkout son opciones visuales; la creación de reserva sólo envía courtId, startAt y durationMinutes. No existe transferencia ni verificación de Yape implementada en este frontend.
5. Perfil afirma Pago confirmado sin leer paymentStatus. Confirmación afirma correo enviado sin comprobarlo.
6. Cancelación anuncia cuatro horas sin consultar la política real del club.
7. Borrador/confirmación quedan en sessionStorage y no tienen identidad persistente independiente de la pestaña. Se limpió el borrador tras éxito y los datos temporales al cerrar sesión.
8. Panel de club es de consulta: no implementa altas, edición de canchas, horarios, tarifas, bloqueos ni reservas manuales.
9. Corregido en V2: si falla la consulta de reservas o su respuesta tiene formato inesperado, el perfil muestra No pudimos cargar tus reservas y permite reintentar. Sólo muestra Sin reserva cuando la consulta devuelve un listado válido sin reservas próximas.
10. Login de jugador con PGO_ADMIN redirige al dashboard administrativo, pero el dashboard usa un canal de autenticación administrativo distinto. Validar contrato y roles con backend antes de cambiar esa ruta.
11. Quedan pendientes idempotencia de creación, validación de precio y disponibilidad en servidor, rotación de refresh cookies, y cambios concurrentes de disponibilidad. El frontend no puede garantizar exclusión de dobles reservas.

## Correcciones incluidas

- Cabeceras públicas reconocen la cuenta consultando contexto autenticado. Revalidación en pageshow, incluida restauración por atrás/adelante.
- Botón de cerrar sesión visible; limpieza de borradores y preferencias temporales al cierre. No se persisten tokens en almacenamiento del navegador.
- Propagación de códigos HTTP y separación de 401, 403 y otros errores; 401 solicita login, 403 muestra falta de permiso y los demás permiten reintentar.
- Login devuelve a una ruta interna permitida usando next, evitando redirecciones externas. Navegación tras login usa replace.
- Selector vacío de clubes tiene mensaje explícito y está deshabilitado. Respuesta de clubes con formato distinto a array muestra error, en lugar de fingir un catálogo vacío.
- Horarios pasados no seleccionables; continuar deshabilitado durante carga; borrador vencido vuelve a selección de cancha.
- Bloqueo de doble envío en checkout mientras una petición está en curso. No sustituye idempotencia del servidor.
- Se retiran afirmaciones no verificadas de pago instantáneo, correo enviado y política fija de cancelación. Estado de pago del perfil se basa en PAID.
- Alertas disponibles limitadas a OPEN, con cupos positivos y fecha futura.
- Crear cuenta gratis lleva al registro.
- Recuperación de contraseña muestra que está pendiente, en vez de no hacer nada. No se inventa un endpoint.

## Archivos modificados

assets/js/api.js, auth.js, booking.js, booking-checkout.js, booking-confirmation.js, profile.js, club-manager.js, admin-dashboard.js y nuevo session-ui.js. Los HTML incluyen session-ui.js; inicio incorpora configuración/API. No hubo cambios de esquema ni backend.

## Validación local

Todos los JavaScript pasan node --check. Todos los scripts referenciados por HTML existen. Pruebas aisladas con respuestas HTTP simuladas verifican: una renovación compartida para dos peticiones concurrentes, reintento con token renovado, 403 conservado sin renovación y finalización sin bucle cuando la cookie ha expirado. Estas pruebas no equivalen a validar cookies reales ni la integración completa. El frontend corregido todavía no está desplegado y no se ha probado visualmente en todos los tamaños.

## Siguiente revisión con backend

Se necesita ZIP/backend y datos de club/canchas de prueba, además de sesión de gestor de club. Prioridad:

1. Revisar qué devuelve GET /api/clubs y por qué no hay clubes seleccionables: datos vacíos, filtro de publicación/estado o contrato distinto.
2. Revisar login, refresh y logout; cookies HttpOnly, Secure, dominio/path, expiración, CORS con credenciales y rotación entre pestañas.
3. Crear club de pruebas y horarios futuros; probar reserva → registro en Mis reservas → cancelación → liberación del horario.
4. Confirmar que dos usuarios no reservan la misma cancha/horario y que cada operación valida pertenencia al club, rol, precio y estado en el servidor.
5. Establecer contrato de pago y cancelación; persistir categoría; validar mails y recuperación.
6. Probar gestores de dos clubes para asegurar separación de canchas, clientes, métricas y reservas. Añadir pruebas de superadministración.

No se puede afirmar funcionamiento al 100% con la evidencia actual. Esta es la auditoría inicial y un primer conjunto de correcciones de frontend.

## Actualización V2
Se comprobó con respuestas simuladas: fallo de conexión, listado vacío válido, respuesta mal formada y reserva confirmada futura. Los cuatro estados se renderizan de forma diferenciada. No se modificó el backend ni se desplegó este ZIP.
