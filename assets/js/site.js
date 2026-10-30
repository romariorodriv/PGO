(function () {
  const logo = (inverse = false) =>
    `<span class="pgo-logo ${inverse ? "inverse" : ""}"><span class="pgo-mark"><i></i><i></i></span><span>PGO</span></span>`;
  function header() {
    return `<header class="site-header"><div class="container inner"><a href="/">${logo()}</a><nav class="site-nav"><a href="/">Inicio</a><a href="/reservar-cancha/">Reservas</a><a href="/blog/">Blog PGO</a></nav><div class="site-actions"><a class="btn btn-outline" href="/login/">Iniciar sesión</a><a class="btn btn-primary" href="/registro/">Crear cuenta</a></div><button class="mobile-menu-btn" id="mobile-menu">☰</button></div></header><div id="mobile-panel" class="hidden" style="position:fixed;inset:72px 0 auto 0;background:#fff;z-index:99;padding:18px 24px;border-bottom:1px solid #e1e5ea;box-shadow:0 15px 30px rgba(0,0,0,.08)"><div style="display:grid;gap:14px;font-weight:700"><a href="/">Inicio</a><a href="/reservar-cancha/">Reservas</a><a href="/blog/">Blog PGO</a><a href="/login/">Iniciar sesión</a><a href="/registro/">Crear cuenta</a></div></div>`;
  }
  function footer() {
    return `<footer class="site-footer"><div class="container"><div class="footer-grid"><div>${logo(true)}<p>PGO conecta jugadores y clubes para reservar canchas y gestionar tu experiencia de pádel.</p></div><div><h4>Producto</h4><a href="/reservar-cancha/">Reservar cancha</a><a href="/blog/">Blog PGO</a></div><div><h4>PGO</h4><a href="/contacto/">Soporte</a><a href="/autores/">Autores</a><a href="/politica-editorial/">Política editorial</a></div><div><h4>Legal</h4><a href="/politica-de-privacidad/">Privacidad</a><a href="/terminos-y-condiciones/">Términos</a><a href="/eliminar-cuenta/">Eliminar cuenta</a></div></div><div class="footer-bottom">© 2026 PGO. Todos los derechos reservados.</div></div></footer>`;
  }
  document
    .querySelectorAll("[data-site-header]")
    .forEach((x) => (x.innerHTML = header()));
  document
    .querySelectorAll("[data-site-footer]")
    .forEach((x) => (x.innerHTML = footer()));
  const b = document.getElementById("mobile-menu"),
    p = document.getElementById("mobile-panel");
  if (b && p) b.onclick = () => p.classList.toggle("hidden");
  window.PGOSite = { logo };
})();
