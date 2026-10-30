PGO V5 — Clubes y jugadores

Archivos: landing index.html y carpetas en/, pt/, fr/, it/; login/index.html, registro/index.html, assets/css/auth-landing.css.

La landing conserva las cinco páginas SEO de V4 y añade accesos Para clubes / Para jugadores.
Login y registro usan los scripts EXISTENTES /assets/js/auth.js, config.js, api.js, utils.js y session-ui.js, que no se incluyeron ni cambiaron.
El registro de jugador mantiene los campos y atributos del formulario original. El flujo club muestra enlaces comerciales: NO inventa un endpoint de registro de clubes.

REQUIERE mantener los archivos existentes del proyecto, especialmente assets/css/styles.css, assets/js/auth.js, assets/landing/*, favicon.svg.
Antes de publicar: probar login real, alta de jugador, recuperación de contraseña y rutas dashboard. El redireccionamiento de perfiles después de login es responsabilidad del auth.js/backend existente (sin cambios en este paquete).
Por SEO se conservan sitemap-idiomas.xml y etiquetas multilingües de la landing. Las páginas de login/registro no están traducidas.
No sincronizar toda la carpeta a S3 sin revisar rutas y recursos originales.
