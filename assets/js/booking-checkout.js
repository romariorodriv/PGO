document.addEventListener('DOMContentLoaded',async()=>{
  const app=document.querySelector('#checkout-app');
  if(!app)return;
  const U=PGOUtil;
  const DRAFT_KEY='pgo_booking_draft';
  const CONFIRMED_KEY='pgo_booking_confirmed';
  let method='transfer';
  let submitting=false;
  let draft=null;
  let user=null;
  const limaToday=()=>new Intl.DateTimeFormat('en-CA',{timeZone:'America/Lima',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());
  const dayChip=(d,t)=>`${d===limaToday()?'HOY':String(d||'').slice(5)} · ${t||''}`;

  try{
    user=await PGOApi.api('/api/auth/context');
  }catch(e){PGOApi.sessionError(e,app);return;}
  PGOUserHeader.mount('#user-header',{user,active:'Reservar'});
  try{draft=JSON.parse(sessionStorage.getItem(DRAFT_KEY)||'null');}catch{draft=null;}
  if(!draft?.userId||draft.userId!==(user?.user||user)?.id||!Number.isInteger(Number(draft.durationMinutes))||Number(draft.durationMinutes)<30||Number(draft.durationMinutes)>240||!Number.isFinite(Number(draft.price))||Number(draft.price)<=0||!draft?.courtId||!draft?.startAt||!Number.isFinite(new Date(draft.startAt).getTime())||new Date(draft.startAt)<=new Date()){location.replace('/reservar-cancha/');return;}

  function render(error=''){
    app.className='figma-checkout-page';
    app.innerHTML=`
      <section class="figma-checkout-body" data-figma-node="150:5">
        <h1>Confirma tu reserva</h1>
        <p class="figma-booking-subtitle">Revisa los datos y elige cómo quieres pagar.</p>
        ${error?`<div class="figma-inline-error">${U.esc(error)}</div>`:''}
        <div class="figma-checkout-grid">
          <div class="figma-checkout-main">
            <article class="figma-checkout-booking">
              <span class="figma-chip figma-chip-accent">${U.esc(dayChip(draft.date,draft.time))}</span>
              <h2>${U.esc(draft.clubName)} · ${U.esc(draft.courtName)}</h2>
              <p>${U.esc(draft.durationMinutes)} minutos · ${U.esc(draft.district||'Club PGO')}</p>
            </article>

            <h3 class="figma-payment-title">Método de pago</h3>
            <button type="button" class="figma-payment-option ${method==='transfer'?'selected':''}" data-method="transfer">
              <span><strong>Yape / transferencia</strong><small>Coordina el pago con el club; esta web no procesa transferencias</small></span>
              <b>${method==='transfer'?'✓':'○'}</b>
            </button>
            <button type="button" class="figma-payment-option ${method==='onsite'?'selected':''}" data-method="onsite">
              <span><strong>Pago en sede</strong><small>Paga cuando llegues al club</small></span>
              <b>${method==='onsite'?'✓':'○'}</b>
            </button>

            <article class="figma-booking-policy">
              <strong>Política de reserva</strong>
              <p>Consulta con el club su política de cancelación.</p>
            </article>
          </div>

          <aside class="figma-checkout-order">
            <h2>Resumen de pago</h2>
            <div><span>Cancha</span><strong>${U.esc(draft.courtName)}</strong></div>
            <div><span>Fecha</span><strong>${U.esc(draft.date===limaToday()?'Hoy':draft.dateLabel||draft.date)} · ${U.esc(draft.time)}</strong></div>
            <div><span>Duración</span><strong>${U.esc(draft.durationMinutes)} min</strong></div>
            <div><span>Tarifa</span><strong>${U.money(draft.price)}</strong></div>
            <hr>
            <div class="figma-order-total"><b>Total</b><strong>${U.money(draft.price)}</strong></div>
            <a href="/reservar-cancha/" class="booking-change-slot">Cambiar fecha o cancha</a>
            <button type="button" id="confirm-booking" class="figma-large-primary">Confirmar reserva ${moneyButton(draft.price)}</button>
          </aside>
        </div>
      </section>`;
    bind();
  }

  function moneyButton(v){return `S/ ${Number(v||0).toFixed(2)}`;}
  function bind(){
    document.querySelectorAll('[data-method]').forEach(b=>b.addEventListener('click',()=>{method=b.dataset.method;render();}));
    document.querySelector('#confirm-booking')?.addEventListener('click',confirm);
  }
  async function confirm(){
    if(submitting)return;submitting=true;
    const btn=document.querySelector('#confirm-booking');
    if(btn){btn.disabled=true;btn.textContent='Confirmando...';}
    try{
      if(new Date(draft.startAt)<=new Date()){sessionStorage.removeItem(DRAFT_KEY);location.replace('/reservar-cancha/');return;}
      const result=await PGOApi.api('/api/reservations',{
        method:'POST',
        body:JSON.stringify({courtId:draft.courtId,startAt:draft.startAt,durationMinutes:Number(draft.durationMinutes),expectedPrice:Number(draft.price)})
      });
      sessionStorage.removeItem(DRAFT_KEY);
      const confirmed={...draft,...result,paymentChoice:method,confirmedAt:new Date().toISOString()};
      sessionStorage.setItem(CONFIRMED_KEY,JSON.stringify(confirmed));
      location.href='/reservar-cancha/confirmada/';
    }catch(e){if(e?.status===401){PGOApi.loginRedirect();return;}render(e?.code==='PRICE_CHANGED'?'La tarifa cambió. Vuelve a elegir la cancha para revisar el precio actualizado.':e?.status===409?'El turno ya no está disponible. Vuelve a elegir fecha o cancha.':e?.message||'No pudimos confirmar la reserva.');}finally{submitting=false;}
  }
  render();
});

window.addEventListener('pageshow',e=>{if(e.persisted)location.reload();});
