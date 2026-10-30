# PGO Frontend — HTML + CSS + JavaScript puro

Esta carpeta contiene **solo el frontend**. No incluye ni modifica el backend, la base de datos, AWS Lambda, EC2, RDS ni ningún servicio de servidor.

## Objetivo

Se eliminó la dependencia de Next.js/React/Tailwind para que el frontend sea más simple de mantener:

- HTML por ruta (`/login/index.html`, `/perfil/index.html`, etc.)
- un CSS central: `assets/css/styles.css`
- JavaScript puro en `assets/js/`
- API existente de PGO consumida con `fetch`
- sin `npm install`
- sin `npm run build`
- sin `node_modules`

## Configuración del backend

Editar solamente:

`assets/js/config.js`

Producción ya está configurada como:

`https://api.pgoapp.com/api`

## Desarrollo local

Desde esta carpeta:

```bash
python -m http.server 8080
```

Abrir `http://localhost:8080/`.

Nota: el backend debe permitir el origen local si se quiere probar autenticación desde localhost. En producción el origen es `pgoapp.com`.

## S3

No existe carpeta `out` porque **ya no hay proceso de compilación**. Esta carpeta completa es el equivalente al antiguo `out`.

Para desplegar:

1. Subir **el contenido de esta carpeta** a la raíz del bucket S3 de PGO.
2. No subir la carpeta contenedora como un nivel adicional.
3. Crear invalidación de CloudFront: `/*`.

## Archivos principales

- `index.html` — home
- `assets/css/styles.css` — colores, tamaños, layout y responsive
- `assets/js/config.js` — URL del API
- `assets/js/api.js` — autenticación, refresh y cliente API
- `assets/js/auth.js` — login y registro
- `assets/js/profile.js` — dashboard del jugador
- `assets/js/booking.js` — reservas de cancha
- `assets/js/bookings.js` — mis reservas
- `assets/js/admin-*.js` — frontend administrativo
- `assets/js/club-manager.js` — frontend básico del club

## Cambiar el fondo del hero

En `assets/css/styles.css`, buscar:

```css
--hero-bg: linear-gradient(135deg,#F7F8FA 0%,#FFFFFF 48%,#EEF2F5 100%);
```

Por ejemplo, para el degradado oscuro que mostraste en Figma:

```css
--hero-bg: linear-gradient(135deg,#385E90 0%,#1E2F43 50%,#1C2A3A 100%);
```

Si usas un fondo oscuro, también conviene cambiar el texto del hero a blanco.

## Nota sobre alcance

La conversión conserva el flujo principal de frontend y los contratos de API existentes. Las pantallas complejas de administración y club se simplificaron visualmente para reducir dependencias, pero siguen consultando los endpoints existentes. No se realizó ningún cambio de backend.
