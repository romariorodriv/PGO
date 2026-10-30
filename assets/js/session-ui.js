(function(){
  // The server's HttpOnly refresh cookie is the source of session persistence.
  const protectedPages=['/perfil/','/reservar-cancha/','/reservar-cancha/checkout/','/reservar-cancha/confirmada/','/mis-reservas/','/club-manager/'];
  let revision=0;
  const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const isClub=user=>Array.isArray(user?.clubMemberships)&&user.clubMemberships.length>0;
  const accountFrom=context=>{
    const account=context?.user||context||{};
    return {...account,clubMemberships:Array.isArray(context?.clubMemberships)?context.clubMemberships:(Array.isArray(account.clubMemberships)?account.clubMemberships:[])};
  };
  const home=user=>isClub(user)?'/club-manager/':'/perfil/';
  function containers(){
    const header=document.querySelector('header');
    if(!header||header.matches('.figma-user-header,.club-top')||location.pathname.startsWith('/admin/'))return [];
    let actions=header.querySelector('.nav-actions,.site-actions,[data-pgo-session-actions]');
    if(!actions){actions=document.createElement('div');actions.dataset.pgoSessionActions='1';header.append(actions);}
    actions.classList.add('pgo-session-actions');
    return [actions];
  }
  function guest(){
    containers().forEach(el=>{el.innerHTML=el.closest('.landing-nav')?'<a href="/login/">Ingresar</a>':'<a class="btn btn-outline" href="/login/">Iniciar sesión</a><a class="btn btn-primary" href="/registro/">Crear cuenta</a>';});
    document.querySelectorAll('[data-pgo-guest-href]').forEach(a=>{a.href=a.dataset.pgoGuestHref;a.textContent=a.dataset.pgoGuestLabel;});
  }
  function show(user){
    const target=home(user);
    containers().forEach(el=>{el.innerHTML=`<a class="pgo-session-account" href="${target}" aria-label="Sesión activa de ${esc(user.name||'Mi cuenta')}"><span class="pgo-session-dot" aria-hidden="true"></span><span><strong>${esc(user.name||'Mi cuenta')}</strong><small>Sesión activa · ${isClub(user)?'Club':'Jugador'}</small></span></a><button class="btn btn-outline" type="button" data-pgo-logout>Cerrar sesión</button>`;});
    document.querySelectorAll('#mobile-panel a[href="/login/"],#mobile-panel a[href="/registro/"],[data-pgo-guest-href]').forEach(a=>{
      if(!a.dataset.pgoGuestHref){a.dataset.pgoGuestHref=a.getAttribute('href');a.dataset.pgoGuestLabel=a.textContent;}
      a.href=a.dataset.pgoGuestHref==='/login/'?target:isClub(user)?'/club-manager/':'/mis-reservas/';
      a.textContent=a.dataset.pgoGuestHref==='/login/'?'Mi cuenta':isClub(user)?'Gestionar club':'Mis reservas';
    });
  }
  async function update(){
    if(!window.PGOApi||location.pathname.startsWith('/admin/'))return;
    const ticket=++revision;
    try{const context=await PGOApi.api('/api/auth/context');if(ticket!==revision)return;show(accountFrom(context));}
    catch(e){if(ticket!==revision)return;if(e?.status===401){guest();if(protectedPages.includes(location.pathname))PGOApi.loginRedirect();}else{
      // A network failure does not prove the user is logged out.
      containers().forEach(el=>{if(!el.querySelector('.pgo-session-account'))el.innerHTML='<span class="pgo-session-status" role="status">No pudimos verificar tu sesión</span><button class="btn btn-outline" data-pgo-session-retry>Reintentar</button>';});
    }}
  }
  document.addEventListener('click',async e=>{
    const retry=e.target.closest('[data-pgo-session-retry]');if(retry){update();return;}
    const button=e.target.closest('[data-pgo-logout]');
    if(!button||button.closest('.figma-user-header,.club-top'))return;
    button.disabled=true;
    try{await PGOApi.webLogout();location.replace('/');}catch{button.disabled=false;button.textContent='Reintentar cierre';}
  });
  window.addEventListener('pageshow',update);
  window.addEventListener('focus',update);
  window.addEventListener('pgo:session-change',e=>{
    ++revision;
    if(e.detail?.type==='logout'){guest();if(e.detail?.external&&protectedPages.includes(location.pathname))PGOApi.loginRedirect();}
    else if(e.detail?.external&&protectedPages.includes(location.pathname))location.reload();
    else update();
  });
  window.PGOSessionUI={update,home};
})();
