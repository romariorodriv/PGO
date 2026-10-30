# SEO publico: configuracion pendiente (sin aplicar)

Dominio preferido existente: `https://pgoapp.com`.

- Configurar en el hosting una redireccion HTTP 301 o 308 desde `http://pgoapp.com`, `http://www.pgoapp.com` y `https://www.pgoapp.com` hacia `https://pgoapp.com`, conservando ruta y query string. No se ha modificado AWS, S3 ni CloudFront. Comprobar despues `/`, `/en/` y una URL real de articulo: destino final 200, sin bucles ni cadenas innecesarias. HTML estatico no puede emitir esta redireccion HTTP.
- Administracion queda fuera de este cambio: `admin/blogs/blog-publisher.service.ts` fija ORIGIN con `www`; `assets/js/admin-blogs.js` tambien genera URLs con `www`. Corregirlos en una tarea autorizada de administracion para evitar que futuras publicaciones reintroduzcan ese dominio. La plantilla del publicador debe conservar un H1 para el titulo, eliminar el titulo repetido del cuerpo y normalizar secciones a H2 y subsecciones a H3 antes del saneamiento. Revisar tambien referencias relacionadas del contenido publicado. No se ha cambiado esa plantilla.
- Los articulos estaticos actuales ya tienen un H1 y secciones H2 sin titulo duplicado. Tres son versiones editoriales abreviadas heredadas; no se ha inventado su contenido faltante.
- El blog actual usa JSON embebido y tarjetas Growth locales, sin fetch de articulos. No se reprodujo el antiguo mensaje exacto de "0 articulos". Ahora incluye cuatro tarjetas y contador en el HTML inicial; el filtro vacio solo se muestra tras evaluar un catalogo con articulos. Un catalogo ausente conserva el HTML y muestra carga.
- Hreflang validado contra archivos locales; falta comprobar respuestas HTTP reales y redirecciones despues de aplicar la configuracion y publicar. No hubo despliegue.
- El formulario de portada solo prepara un correo y aclara que no se ha enviado. No se encontraron eventos de conversion de solicitud recibida en el codigo de portada revisado. Un clic mailto no acredita recepcion.
- Este frontend es HTML/CSS/JS estatico: README.md declara que no hay comando de compilacion ni package.json. La validacion se hace con el verificador SEO y `node --check assets/js/blog-editorial.js`.
