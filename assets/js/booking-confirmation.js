document.addEventListener('DOMContentLoaded',async()=>{
  const app=document.querySelector('#confirmed-app');
  if(!app)return;
  const U=PGOUtil;
  const CONFIRMED_KEY='pgo_booking_confirmed';
  let user=null,data=null;
  const limaToday=()=>new Intl.DateTimeFormat('en-CA',{timeZone:'America/Lima',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());
  try{user=await PGOApi.api('/api/auth/context');}
  catch(e){PGOApi.sessionError(e,app);return;}
  PGOUserHeader.mount('#user-header',{user,active:'Reservar'});
  try{data=JSON.parse(sessionStorage.getItem(CONFIRMED_KEY)||'null');}catch{data=null;}
  if(!data||data.userId!==(user?.user||user)?.id){location.replace('/mis-reservas/');return;}

  const club=data.club?.name||data.clubName||'Club PGO';
  const court=data.court?.name||data.courtName||'Cancha';
  const code=data.bookingCode||data.code||data.id||'PGO-RSV';
  const price=data.price!=null?Number(data.price):0;
  const duration=Number(data.durationMinutes||0)||90;
  const when=`${data.date===limaToday()?'Hoy':(data.dateLabel||data.date||'')} · ${data.time||''}`;
  const paymentLabel=String(data.paymentStatus||'').toUpperCase()==='PAID'?'Pago confirmado':data.paymentChoice==='onsite'?'Pago en sede':'Pago por coordinar';

  app.className='figma-confirmed-page';
  app.innerHTML=`
    <section class="figma-confirmed-body" data-figma-node="150:6">
      <div class="figma-confirmed-success">
        <span>✓</span>
        <h1>¡Cancha reservada!</h1>
        <p>${U.esc(code)} · Consulta esta reserva en Mis reservas</p>
      </div>

      <div class="figma-confirmed-grid">
        <article class="figma-confirmed-detail">
          <h2>${U.esc(when)}</h2>
          <strong>${U.esc(club)} · ${U.esc(court)}</strong>
          <p>${duration} minutos · ${U.money(price)} · ${U.esc(paymentLabel)}</p>
          <h3>¿Te faltan jugadores?</h3>
          <p>Comparte tu reserva con amigos.</p>
          <div class="figma-confirmed-actions">
            <button class="figma-medium-secondary" id="share-booking" type="button">Invitar jugadores</button>
          </div>
        </article>

        <aside class="figma-confirmed-next">
          <h2>Tu reserva ya está sincronizada</h2>
          <p>También aparecerá en tu app PGO con el mismo usuario.</p>
          <a class="figma-large-primary" href="/mis-reservas/">Ver mis reservas</a>
          <a class="figma-large-secondary" href="/reservar-cancha/">Reservar otra cancha</a>
        </aside>
      </div>
    </section>`;

  document.querySelector('#share-booking')?.addEventListener('click',async()=>{
    const text=`Tengo cancha en ${club}, ${court}, ${when}. ¿Te sumas?`;
    try{
      if(navigator.share)await navigator.share({title:'Reserva PGO',text});
      else{await navigator.clipboard.writeText(text);alert('Invitación copiada.');}
    }catch{}
  });
});

window.addEventListener('pageshow',e=>{if(e.persisted)location.reload();});
