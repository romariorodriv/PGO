(function(){
  async function mount(root){
    let context;
    try{context=await PGOApi.api('/api/auth/context');}catch(e){PGOApi.sessionError(e,root);return;}
    if(context.clubMemberships?.length){PGOApi.sessionError({status:403},root);return;}
    root.innerHTML=`<header class="club-top"><a href="/" class="pgo-logo">PGO</a><button type="button" class="btn btn-outline" data-pgo-logout>Cerrar sesión</button></header><main class="container" style="max-width:720px;padding:40px 20px"><h1>Registra tu club</h1><p><strong>Paso 1: datos del establecimiento.</strong> Tras registrarlo, PGO revisará tu solicitud antes de habilitar las reservas públicas.</p><p>Tu cuenta quedará vinculada como propietaria. Después podrás preparar canchas, horarios y tarifas mientras PGO revisa el club. Las reservas públicas requieren aprobación y que el propietario active la prueba de siete días.</p><form id="register-club" class="card panel"><div class="grid g2 gap16">${[['name','Nombre del club','text',2],['email','Correo del club','email',0],['phone','Teléfono','tel',5],['address','Dirección','text',5],['district','Distrito','text',2],['city','Ciudad','text',2]].map(([name,label,type,min])=>`<label>${label}<input class="input" name="${name}" type="${type}" required ${min?`minlength="${min}"`:''}></label>`).join('')}</div><label>Descripción opcional<textarea class="input" name="description"></textarea></label><p id="club-register-error" role="alert"></p><button type="submit" class="btn btn-primary">Registrar club</button> <a href="/perfil/">Volver a mi cuenta</a></form></main>`;
    root.querySelector('[data-pgo-logout]').addEventListener('click',async e=>{const b=e.currentTarget;b.disabled=true;try{await PGOApi.webLogout();location.replace('/');}catch{b.disabled=false;b.textContent='Reintentar cierre';}});
    const form=root.querySelector('#register-club'),error=root.querySelector('#club-register-error'),button=form.querySelector('button');
    let sending=false;
    form.addEventListener('submit',async event=>{
      event.preventDefault();if(sending||!form.reportValidity())return;
      const body=Object.fromEntries([...new FormData(form)].map(([key,value])=>[key,String(value).trim()]));
      if(!body.description)delete body.description;
      const minimums={name:2,phone:5,address:5,district:2,city:2};
      if(Object.entries(minimums).some(([key,min])=>body[key].length<min)){error.textContent='Completa los datos del club sin usar sólo espacios.';return;}
      sending=true;button.disabled=true;error.textContent='';
      try{
        const club=await PGOApi.api('/api/club/register',{method:'POST',body:JSON.stringify(body)});
        if(!club?.id)throw new Error('No pudimos verificar el resultado. Revisa tu cuenta antes de repetir el registro.');
        location.replace('/club-manager/');
      }catch(e){error.textContent=e?.message||'No pudimos registrar el club. Revisa tu cuenta antes de volver a enviar.';}
      finally{sending=false;button.disabled=false;}
    });
  }
  window.PGOClubRegistration={mount};
})();
