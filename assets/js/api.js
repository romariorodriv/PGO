(function(){
  const base=(window.PGO_CONFIG?.API_BASE||'https://api.pgoapp.com/api').replace(/\/$/,'');
  let accessToken=null, refreshPromise=null, adminAccessToken=null, adminRefreshPromise=null;
  const urlFor=(path)=>base+(path.startsWith('/api/')?path.slice(4):path.startsWith('/')?path:'/'+path);
  async function parse(response){ const data=await response.json().catch(()=>({})); if(!response.ok){ const raw=(data&&typeof data==='object')?(data.message||data.error):null; const msg=typeof raw==='string'?raw:(raw&&raw.message)||'No pudimos completar la operación.'; const error=new Error(msg); error.status=response.status; error.code=data?.code||raw?.code; throw error; } return data; }
  let sessionVersion=0;
  const sessionLock=fn=>window.navigator?.locks?.request?window.navigator.locks.request('pgo-web-session',fn):fn();
  const clearDrafts=()=>['pgo_booking_draft','pgo_booking_confirmed','pgo_category_hint','pgo-booking-club'].forEach(k=>sessionStorage.removeItem(k));
  function notifySession(type){
    ++sessionVersion;
    try{localStorage.setItem('pgo_session_event',JSON.stringify({type,id:Date.now()+':'+Math.random()}));}catch{}
    window.dispatchEvent(new CustomEvent('pgo:session-change',{detail:{type,external:false}}));
  }
  window.addEventListener('storage',e=>{
    if(e.key!=='pgo_session_event'||!e.newValue)return;
    let event;try{event=JSON.parse(e.newValue)}catch{return;}
    if(!['login','logout'].includes(event.type))return;
    ++sessionVersion;accessToken=null;clearDrafts();
    window.dispatchEvent(new CustomEvent('pgo:session-change',{detail:{type:event.type,external:true}}));
  });
  async function refresh(){
    if(!refreshPromise){
      const version=sessionVersion;
      refreshPromise=sessionLock(async()=>{
        if(version!==sessionVersion)return false;
        const r=await fetch(urlFor('/auth/web/refresh'),{method:'POST',credentials:'include',cache:'no-store',headers:{'X-PGO-Web-Request':'1'}});
        if(!r.ok){if(r.status===401)return false;await parse(r);}
        const d=await r.json();
        if(version!==sessionVersion||typeof d.accessToken!=='string'||!d.accessToken)return false;
        accessToken=d.accessToken;return true;
      }).finally(()=>{refreshPromise=null;});
    }
    return refreshPromise;
  }
  async function api(path,options={},retry=true){
    const method=options.method||'GET';
    const response=await fetch(urlFor(path),{credentials:'include',cache:'no-store',...options,headers:{...(options.body?{'Content-Type':'application/json'}:{}),...(method!=='GET'?{'X-PGO-Web-Request':'1'}:{}),...(accessToken?{Authorization:'Bearer '+accessToken}:{}),...(options.headers||{})}});
    if(response.status===401&&retry&&!path.includes('/auth/web/')&&await refresh())return api(path,options,false);
    return parse(response);
  }
  async function webLogin(body){return sessionLock(async()=>{const r=await api('/auth/web/login',{method:'POST',body:JSON.stringify(body)},false);clearDrafts();accessToken=r.accessToken;notifySession('login');return r.user;});}
  async function webRegister(body){return sessionLock(async()=>{const r=await api('/auth/web/register',{method:'POST',body:JSON.stringify(body)},false);clearDrafts();accessToken=r.accessToken;notifySession('login');return r.user;});}
  async function webLogout(){return sessionLock(async()=>{
    await api('/auth/web/logout',{method:'POST'},false);
    accessToken=null;clearDrafts();notifySession('logout');
  });}
  async function readAdmin(response){ const p=await response.json().catch(()=>({})); if(!response.ok){const raw=p.message||p.error;const error=new Error(typeof raw==='string'?raw:(raw&&raw.message)||'No pudimos completar la operación.');error.status=response.status;throw error;} if(!p||typeof p!=='object'||!('data'in p))throw new Error('Respuesta administrativa inválida.');return p.data; }
  async function adminRefresh(){ if(!adminRefreshPromise){adminRefreshPromise=fetch(urlFor('/admin/auth/refresh'),{method:'POST',credentials:'include',cache:'no-store',headers:{'X-PGO-Admin-Request':'1'}}).then(async r=>{if(!r.ok)return false; const d=await readAdmin(r); adminAccessToken=d.accessToken; return true;}).catch(()=>false).finally(()=>adminRefreshPromise=null);}return adminRefreshPromise; }
  async function adminApi(path,options={},retry=true){ const r=await fetch(urlFor(path),{credentials:'include',cache:'no-store',...options,headers:{...(options.body?{'Content-Type':'application/json'}:{}),'X-PGO-Admin-Request':'1',...(adminAccessToken?{Authorization:'Bearer '+adminAccessToken}:{}),...(options.headers||{})}}); if(r.status===401&&retry&&!path.includes('/admin/auth/login')&&!path.includes('/admin/auth/refresh')&&await adminRefresh())return adminApi(path,options,false); return readAdmin(r); }
  async function adminLogin(body){const r=await fetch(urlFor('/admin/auth/login'),{method:'POST',credentials:'include',cache:'no-store',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});const d=await readAdmin(r);adminAccessToken=d.accessToken;return d.admin;}
  async function adminLogout(){try{await adminApi('/admin/auth/logout',{method:'POST'},false);}finally{adminAccessToken=null;}}
  function loginRedirect(admin=false){
    const next=location.pathname+location.search;
    location.replace((admin?'/admin/login/':'/login/')+'?next='+encodeURIComponent(next));
  }
  function sessionError(error,root,admin=false){
    if(error?.status===401){loginRedirect(admin);return;}
    const box=document.createElement('div');box.className='error';box.setAttribute('role','alert');
    box.textContent=error?.status===403?'Tu cuenta no tiene permiso para acceder a esta sección.':error?.message||'No pudimos conectar con PGO. Intenta nuevamente.';
    const retry=document.createElement('button');retry.className='btn btn-outline';retry.textContent='Reintentar';retry.onclick=()=>location.reload();
    const home=document.createElement('a');home.href=admin?'/admin/login/':'/perfil/';home.textContent=admin?'Volver al acceso de admin':'Volver a mi inicio';
    box.append(document.createElement('br'),retry,document.createTextNode(' '),home);root.replaceChildren(box);
  }
  window.PGOApi={sessionError,loginRedirect,api,webLogin,webRegister,webLogout,adminApi,adminLogin,adminLogout,urlFor};
})();
