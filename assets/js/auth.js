document.addEventListener('DOMContentLoaded',()=>{
  const form=document.querySelector('#auth-form');
  if(!form)return;

  const params=new URLSearchParams(location.search);
  const allowed=['/perfil/','/reservar-cancha/','/mis-reservas/','/club-manager/'];
  function safeNext(value){
    if(!value)return null;
    try{const url=new URL(value,location.origin);return url.origin===location.origin&&allowed.includes(url.pathname)?url.pathname+url.search:null;}catch{return null;}
  }
  let next=safeNext(params.get('next'));
  let isClub=params.get('tipo')==='club'||next?.split('?')[0]==='/club-manager/';
  const switchLink=document.querySelector('[data-auth-switch]');
  function updateSwitch(){
    if(!switchLink)return;
    const url=new URL(form.dataset.mode==='login'?'/registro/':'/login/',location.origin);
    if(next)url.searchParams.set('next',next);
    if(isClub)url.searchParams.set('tipo','club');
    switchLink.href=url.pathname+url.search;
  }
  const player=document.querySelector('#register-player-tab'),clubTab=document.querySelector('#register-club-tab');
  function chooseClub(value){
    isClub=value;
    if(value)next='/club-manager/';
    else if(next?.split('?')[0]==='/club-manager/')next=null;
    const playerPanel=document.querySelector('#register-player-panel'),clubPanel=document.querySelector('#register-club-panel');
    player.setAttribute('aria-selected',String(!value));clubTab.setAttribute('aria-selected',String(value));
    player.tabIndex=value?-1:0;clubTab.tabIndex=value?0:-1;
    playerPanel.hidden=value;clubPanel.hidden=!value;
    playerPanel.setAttribute('aria-hidden',String(value));clubPanel.setAttribute('aria-hidden',String(!value));
    (value?clubPanel:playerPanel).append(form);
    const category=form.querySelector('[data-player-only]');
    if(category){category.hidden=value;category.querySelector('select').disabled=value;}
    form.querySelector('button[type="submit"]').textContent=value?'Crear cuenta y configurar mi club':'Crear mi cuenta';
    const current=new URL(location.href);
    current.searchParams.delete('tipo');current.searchParams.delete('next');
    if(value)current.searchParams.set('tipo','club');
    if(next)current.searchParams.set('next',next);
    history.replaceState(null,'',current.pathname+current.search+current.hash);
    updateSwitch();
  }
  if(player&&clubTab){
    player.addEventListener('click',()=>chooseClub(false));clubTab.addEventListener('click',()=>chooseClub(true));
    for(const tab of [player,clubTab])tab.addEventListener('keydown',e=>{if(['ArrowLeft','ArrowRight','Home','End'].includes(e.key)){e.preventDefault();chooseClub(e.key==='Home'?false:e.key==='End'?true:!isClub);(isClub?clubTab:player).focus();}});
    chooseClub(isClub);
  }else updateSwitch();

  const mode=form.dataset.mode;
  const errorBox=document.querySelector('#auth-error');
  const submit=form.querySelector('button[type="submit"]');
  const forgot=document.querySelector('[data-forgot-password]');

  forgot?.addEventListener('click',e=>{e.preventDefault();showError('La recuperación automática todavía no está disponible. Escribe a soporte@pgoapp.com desde tu correo registrado para solicitar ayuda.');});

  const showError=(message)=>{
    if(!errorBox)return;
    errorBox.textContent=message||'No pudimos completar la operación.';
    errorBox.classList.remove('hidden');
  };

  form.addEventListener('submit',async e=>{
    e.preventDefault();
    errorBox?.classList.add('hidden');
    if(errorBox)errorBox.textContent='';

    if(!form.reportValidity())return;
    const data=Object.fromEntries(new FormData(form).entries());
    submit.disabled=true;

    try{
      if(mode==='login'){
        await PGOApi.webLogin({email:String(data.email||'').trim(),password:data.password});
      }else{
        const name=String(data.fullName||'').trim();
        if(name.length<2)throw new Error('Ingresa tu nombre completo.');
        if(String(data.password||'').trim().length<8||!/[A-Z]/.test(data.password)||!/\d/.test(data.password))throw new Error('La contraseña debe tener al menos 8 caracteres, una mayúscula y un número.');
        await PGOApi.webRegister({name,email:String(data.email||'').trim(),password:data.password});
        // El backend actual registra nombre/correo/contraseña. Guardamos la categoría
        // solamente como preferencia visual temporal hasta que exista un campo de perfil persistente.
        if(data.category)sessionStorage.setItem('pgo_category_hint',String(data.category));
      }

      let context;
      try { context=await PGOApi.api('/api/auth/context'); }
      catch (contextError) {
        // Login succeeded. A context error must not be shown as bad credentials.
        showError('La cuenta se autenticó, pero no pudimos verificar sus permisos. Reintenta para acceder a tu espacio.');
        return;
      }
      const account=context?.user||context;
      const memberships=context?.clubMemberships||account?.clubMemberships||[];
      const roles=context?.globalRoles||account?.globalRoles||[];
      const destination=next||(isClub?'/club-manager/':null);
      if(destination){location.replace(destination);return;}
      if(roles.some(x=>(typeof x==='string'?x:x?.role)==='PGO_ADMIN')){
        location.replace('/admin/dashboard/');
      }else if(memberships.length){
        location.replace('/club-manager/');
      }else{
        location.replace('/perfil/');
      }
    }catch(ex){
      showError(ex?.message||'Error de conexión.');
    }finally{
      submit.disabled=false;
    }
  });
});
