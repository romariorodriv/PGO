# Cómo actualizar

Conserva una copia de tu frontend actual. Sube el contenido de PGO-WEB-AUDITADO a la raíz del hosting de pruebas, sustituyendo HTML y assets/js. No necesitas cambios de backend para este primer parche. No lo he desplegado.

Después de subir: abre una pestaña nueva; verifica registro/login, Mi cuenta en inicio/mis reservas, recarga y atrás/adelante. Revisa cerrar sesión y que el perfil ya no sea accesible. Si no aparecen clubes, comprueba el contrato y datos de GET /api/clubs con el backend.

Las opciones de pago siguen sin persistir en backend; no habilites cobros basándote en este checkout. Para validar reservas hacen falta clubes/canchas/horarios de prueba. Consulta AUDITORIA-TECNICA.md para el alcance probado y los pendientes.
