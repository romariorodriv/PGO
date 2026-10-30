document.addEventListener('DOMContentLoaded',async()=>{
  const root=document.querySelector('#profile-app');
  if(!root)return;
  const U=PGOUtil;

  const esc=U.esc;
  const firstName=(name)=>String(name||'Jugador').trim().split(/\s+/)[0]||'Jugador';
  const categoryOf=(user)=>{
    const profile=user?.playerProfile||user?.profile||{};
    return user?.category||profile?.category||profile?.levelName||sessionStorage.getItem('pgo_category_hint')||'Jugador PGO';
  };
  const statOf=(user,keys)=>{
    const sources=[user?.stats,user?.playerStats,user?.playerProfile,user?.profile,user];
    for(const src of sources){
      if(!src||typeof src!=='object')continue;
      for(const key of keys){
        const value=src[key];
        if(value!==undefined&&value!==null&&value!=='')return value;
      }
    }
    return null;
  };
  const bookingDate=(value)=>{
    try{return new Intl.DateTimeFormat('es-PE',{timeZone:'America/Lima',weekday:'short',day:'numeric',month:'short'}).format(new Date(value));}catch{return ''}
  };
  const bookingTime=(value)=>{
    try{return new Intl.DateTimeFormat('es-PE',{timeZone:'America/Lima',hour:'numeric',minute:'2-digit'}).format(new Date(value));}catch{return ''}
  };
  const durationMinutes=(booking)=>{
    if(!booking?.startAt||!booking?.endAt)return null;
    const n=Math.round((new Date(booking.endAt)-new Date(booking.startAt))/60000);
    return Number.isFinite(n)&&n>0?n:null;
  };

  try{
    const user=await PGOApi.api('/api/auth/context');
    const bookingsResult=await Promise.allSettled([PGOApi.api('/api/reservations/me')]);
    const result=bookingsResult[0];
    const bookingsFailed=result.status==='rejected'||!Array.isArray(result.value);
    const bookings=bookingsFailed?[]:result.value;
    const upcoming=bookings
      .filter(x=>x?.status==='CONFIRMED'&&x?.startAt&&new Date(x.startAt)>new Date())
      .sort((a,b)=>new Date(a.startAt)-new Date(b.startAt));
    const next=upcoming[0]||null;

    const category=categoryOf(user);
    const xp=statOf(user,['xp','experience','experiencePoints']);
    const name=user?.name||'Jugador PGO';
    const initials=U.initials(name);

    const reservationStatus=bookingsFailed?'NO DISPONIBLE':next?'CONFIRMADA':'SIN RESERVA';
    const reservationTitle=next?`${bookingDate(next.startAt)} · ${bookingTime(next.startAt)}`:'Aún no tienes una reserva próxima';
    const reservationPlace=next?`${esc(next.club?.name||'Club PGO')} · ${esc(next.court?.name||'Cancha')}`:'Encuentra una cancha y horario disponible.';
    const duration=next?durationMinutes(next):null;
    const reservationMeta=next?[duration?`${duration} min`:null,next.price!=null?U.money(next.price):null,next.paymentStatus==='PAID'?'Pago confirmado':'Pago pendiente de verificar'].filter(Boolean).join(' · '):'Tu próxima partida puede empezar aquí.';
    const reservationHref=next?'/mis-reservas/':'/reservar-cancha/';
    const reservationButton=next?'Ver reserva':'Reservar cancha';

    root.className='figma-user-app';
    root.innerHTML=`
      <div id="user-header"></div>
      <main class="figma-user-body">
        <h1>Hola ${esc(firstName(name))} 👋</h1>
        <p class="figma-user-lead">¿Qué quieres hacer hoy?</p>

        <section class="figma-quick-actions" aria-label="Acciones rápidas">
          <a class="figma-action-card recommended" href="/reservar-cancha/">
            <span class="figma-chip figma-chip-accent">RECOMENDADO</span>
            <strong>Reservar cancha</strong>
            <p>Elige club, horario y cancha disponible.</p>
            <span class="figma-action-go accent">Ir →</span>
          </a>
          <a class="figma-action-card" href="/mis-reservas/">
            <span class="figma-chip figma-chip-neutral">PGO</span>
            <strong>Mis reservas</strong>
            <p>Consulta tus horarios y reservas de cancha.</p>
            <span class="figma-action-go">Ir →</span>
          </a>
        </section>

        <section class="figma-home-main">
          <article class="figma-next-reservation">
            <div class="figma-reservation-head">
              <h2>Tu próxima reserva</h2>
              <span class="figma-chip figma-chip-success">${reservationStatus}</span>
            </div>

            ${bookingsFailed?`<div class="figma-booking-hero empty-booking" role="alert"><h3>No pudimos cargar tus reservas</h3><p>No podemos confirmar si tienes una reserva próxima. Intenta nuevamente.</p><button type="button" id="retry-reservations" class="figma-small-dark-button">Reintentar</button></div>`:`<div class="figma-booking-hero ${next?'':'empty-booking'}">
              <h3>${esc(reservationTitle)}</h3>
              <strong>${reservationPlace}</strong>
              <p>${esc(reservationMeta)}</p>
              <a class="figma-small-dark-button" href="${reservationHref}">${reservationButton}</a>
            </div>`}

            <div class="figma-pgo-hint">
              <strong>¿Te faltan jugadores?</strong>
              <p>Comparte tu reserva con otros jugadores.</p>
            </div>
          </article>

          <aside class="figma-identity-card">
            <span>Tu perfil PGO</span>
            <h2>${esc(category)}</h2>
            <p>Nivel y actividad sincronizados con tu app.</p>
            <div class="figma-identity-stats">
              <div><strong>${bookingsFailed?'—':bookings.length}</strong><small>Reservas</small></div>
              <div><strong>${bookingsFailed?'—':upcoming.length}</strong><small>Próximas</small></div>
              <div><strong>${xp==null?'—':`+${esc(xp)}`}</strong><small>XP</small></div>
            </div>
          </aside>
        </section>
      </main>`;

    PGOUserHeader.mount('#user-header',{user,active:'Inicio'});
    root.querySelector('#retry-reservations')?.addEventListener('click',()=>location.reload());
  }catch(e){
    PGOApi.sessionError(e,root);
  }
});

window.addEventListener('pageshow',e=>{if(e.persisted)location.reload();});
