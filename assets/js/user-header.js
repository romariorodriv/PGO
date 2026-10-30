(function(){
  const U=window.PGOUtil||{};
  const esc=U.esc||((v)=>String(v??''));
  function categoryOf(user){
    const profile=user?.playerProfile||user?.profile||{};
    return user?.category||profile?.category||profile?.levelName||sessionStorage.getItem('pgo_category_hint')||'Jugador PGO';
  }
  function mount(target,{user,active='Inicio'}={}){
    const root=typeof target==='string'?document.querySelector(target):target;
    if(!root)return;
    user=user?.user||user;
    const name=user?.name||'Jugador PGO';
    const initials=(U.initials?U.initials(name):String(name).slice(0,2).toUpperCase())||'PG';
    const category=categoryOf(user);
    const items=[
      ['Inicio','/perfil/'],
      ['Reservar','/reservar-cancha/'],
      ['Mis reservas','/mis-reservas/']
    ];
    root.innerHTML=`
      <header class="figma-user-header" data-figma-node="152:92">
        <a class="figma-brand" href="/" aria-label="PGO Inicio">
          <span class="figma-mark" aria-hidden="true"><i></i><i></i></span>
          <strong>PGO</strong>
        </a>
        <nav class="figma-user-nav" aria-label="Navegación de jugador">
          ${items.map(([label,href])=>`<a href="${href}" class="${active===label?'active':''}">${label}</a>`).join('')}
        </nav>
        <div class="figma-user-actions"><a class="figma-user-menu" href="/perfil/" aria-label="Perfil de ${esc(name)}">
          <span class="figma-user-dot" aria-hidden="true">•</span>
          <span class="figma-user-avatar">${esc(initials)}</span>
          <span class="figma-user-copy"><strong>${esc(name)}</strong><small>Sesión activa</small></span>
        </a><button type="button" class="btn btn-outline figma-user-logout" data-pgo-logout>Cerrar sesión</button></div>
      </header>`;
    const logout=root.querySelector('[data-pgo-logout]');
    logout.addEventListener('click',async()=>{logout.disabled=true;try{await PGOApi.webLogout();location.replace('/')}catch{logout.disabled=false;logout.textContent='Reintentar cierre'}});
  }
  window.PGOUserHeader={mount,categoryOf};
})();
