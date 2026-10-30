# Auditoría inicial de clubes: frontend V2 y backend adjunto

## Conclusión

El backend sí tiene alta y aprobación de clubes. No existe una cuenta separada llamada «club»: una cuenta normal adquiere una membresía OWNER cuando registra el club. El club nace PENDING y necesita un PGO_ADMIN para pasar a APPROVED. La web revisada no ofrece el alta ni aprobación, de modo que una cuenta de jugador queda sin acceso al panel.

No se creó un club ni se asignaron roles en la base de datos alojada. No se usaron credenciales de base de datos del ZIP. Las comprobaciones de servicios descritas abajo son aisladas con Prisma simulado, no pruebas integrales de PostgreSQL ni de la web alojada.

## Flujo confirmado en código

1. Cuenta autenticada: POST /api/club/register recibe name, email, phone, address, district, city y opcionalmente description/instagram.
2. ClubsService.register crea Club y ClubMember OWNER para el usuario actual; schema.prisma define status PENDING por defecto.
3. GET /api/club/me consulta la membresía del usuario. No exige APPROVED para entrar al panel: aprobación afecta a publicación y reservas.
4. PGO_ADMIN consulta GET /api/pgo-admin/clubs?status=PENDING y cambia el estado con PATCH /api/pgo-admin/clubs/:id/status y cuerpo {"status":"APPROVED"}.
5. GET /api/clubs sólo devuelve APPROVED. Esto explica un catálogo vacío si no hay aprobados, pero no se consultó la base alojada para confirmar que ésa es la causa concreta.

El rol PGO_ADMIN de este flujo está en UserGlobalRole y se comprueba con JWT de usuario. Es distinto del canal de administración /api/admin/auth. No debe suponerse que una cuenta del panel administrativo tiene automáticamente ese rol. Existe el script scripts/grant-pgo-admin.ts; no se ejecutó ni se otorgó acceso administrativo.

## Hallazgos

| Prioridad | Hallazgo | Evidencia/alcance |
|---|---|---|
| Alta | Alta de club ausente en frontend | La API POST /club/register existe; no tiene formulario en V2. |
| Alta | Aprobación sin pantalla operativa | API /pgo-admin/clubs/:id/status existe; dashboard administrativo del frontend sólo usa /admin/dashboard. |
| Alta | Panel de gestión sólo de consulta | Backend ofrece canchas, horarios, tarifas, bloqueos, reservas manuales y calendario; frontend sólo resumen, reservas, canchas y clientes. |
| Alta | Roles OWNER/ADMIN/STAFF sin diferenciación en operaciones revisadas | ClubAccessService admite lista de roles, pero gestión y reservas manuales llaman membership sin roles. STAFF tiene las mismas comprobaciones de membresía en esos métodos. Definir permisos esperados antes de restringirlo. |
| Alta | Selección de club implícita para usuario con varias membresías | membership usa findFirst sin orden ni selección explícita; contexto y operaciones de colección derivan el primer club. Falta selector de club y contexto inequívoco. |
| Media | Validación insuficiente de duraciones al configurar horarios | SetSchedulesDto.durations valida array de enteros, pero no mínimo/máximo, lista no vacía ni duplicados; las reservas sólo admiten 30–240. |
| Media | Fechas del calendario sin validación expresa | Controller construye Dates desde query sin comprobar rango/validez. Disponibilidad valida forma YYYY-MM-DD, pero no fecha calendario canónica. |
| Media | Métrica de ocupación aproximada | reservationsToday/(activeCourts*10), no minutos ocupados respecto a horarios reales. Se rotula como estimada en este parche. |
| Media | Próximas reservas incluían canceladas en panel | El filtro del frontend sólo comprobaba fecha; corregido a CONFIRMED. |
| Media | Nombre del jugador manual podía mostrarse como Jugador | Backend entrega player.name; frontend miraba player.firstName. Corregido. |
| Media | Sin cancelación operativa del gestor | La API de cancelación revisada sólo permite al playerId. No hay endpoint de gestor para cancelar reservas manuales de invitados. |
| Media | Estados y configuración de clubes no aprobados | La membresía permite operar configuración aun estando PENDING/REJECTED/SUSPENDED. Las reservas sí exigen APPROVED. Decidir qué configuración debe permitirse en cada estado. |

## Protecciones existentes

- Canchas individuales: se comprueba membresía en el club de la cancha.
- Horarios y tarifas: se rechazan courtId ajenos al club obtenido del contexto.
- Bloqueos: transacción y advisory lock por cancha; rechaza solapamiento con reservas confirmadas.
- Reservas: advisory lock por cancha, exclusión reservations_confirmed_no_overlap en migración y cálculo del precio en servidor.
- Alta de club: crea membresía OWNER anidada con el usuario autenticado; no acepta un propietario arbitrario desde el DTO.
- Cambiar estado del club exige PGO_ADMIN.

La existencia de estas protecciones en código no prueba que todas las migraciones estén aplicadas en el servidor.

## Parche frontend incluido

En /club-manager/, si el servidor devuelve 403 y auth/context confirma que no hay membresías, se muestra un formulario de registro de club con la cuenta existente. Si ya hay membresías, se conserva el aviso de acceso denegado para no esconder un problema de permisos con otro formulario. Después del alta vuelve al panel. El panel muestra el estado y un aviso para PENDING/SUSPENDED/REJECTED. No hay aprobación automática.

También corrige nombres de jugadores, filtro de próximas reservas confirmadas y etiqueta de ocupación estimada. Conserva todas las correcciones V2.

Archivos nuevos/modificados: assets/js/club-registration.js, assets/js/club-manager.js y club-manager/index.html. No se modificó el backend.

## Comprobaciones ejecutadas

- TypeScript de ClubsService y ClubAccessService transpila y se ejecuta aislado con dependencias simuladas: vinculación OWNER al usuario actual, slug, filtro público APPROVED, rechazo sin membresía y rechazo sin PGO_ADMIN. PENDING se corrobora mediante el valor por defecto del esquema; la devolución del mock no prueba inserción real.
- Frontend con API simulada: avisos PENDING y SUSPENDED, panel APPROVED y delegación a formulario con 403.
- Sintaxis de todos los JS y existencia de scripts referenciados por HTML.
- No se ejecutó la suite e2e incluida: requiere una base PostgreSQL de pruebas y dependencias del proyecto.
- No se ha publicado el parche ni probado su presentación en navegador. No se registró una cuenta nueva ni un club en el sitio.

## Para completar la auditoría en la web

1. Publicar este frontend en el hosting de pruebas, con respaldo del actual.
2. Con la cuenta de prueba ya existente, entrar en /club-manager/ y registrar un club identificado como prueba. El propietario debe completar cualquier registro de credenciales; este formulario usa la sesión existente y no crea una contraseña nueva.
3. Verificar el panel PENDING y que el club no aparezca en catálogo.
4. Un operador con PGO_ADMIN aprueba el club de prueba mediante el flujo administrativo existente/API. No compartir contraseñas en chat. Si no hay operador habilitado, preparar su alta de forma controlada.
5. Configurar canchas, horarios, duración y precios desde API o el futuro panel operativo; aprobar por sí solo no crea disponibilidad.
6. Probar reservas del jugador y manuales, bloqueos, historial y métricas. Probar dos cuentas simultáneas y dos clubes distintos.

La auditoría operativa de clubes sigue pendiente de alta/aprobación/configuración en el ambiente de pruebas. Este informe identifica el bloqueo y entrega el formulario que faltaba; no afirma que todas las operaciones estén completas.
