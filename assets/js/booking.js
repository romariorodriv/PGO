document.addEventListener('DOMContentLoaded',()=>{
  const app=document.querySelector('#booking-app');
  if(!app)return;
  const U=PGOUtil, W=PGOBookingWeek;
  const DRAFT_KEY='pgo_booking_draft';
  const limaToday=()=>new Intl.DateTimeFormat('en-CA',{timeZone:'America/Lima',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());
  const addDays=(d,n)=>{const x=new Date(d+'T12:00:00Z');x.setUTCDate(x.getUTCDate()+n);return x.toISOString().slice(0,10)};
  const longDate=(d)=>new Intl.DateTimeFormat('es-PE',{timeZone:'UTC',weekday:'long',day:'numeric',month:'short'}).format(new Date(d+'T12:00:00Z')).replace('.','');
  let user=null,clubs=[],clubId='',selectedDate=limaToday(),rangeStart=W.monday(limaToday()),requestId=0,duration=90,slots=[],selectedTime='',selected=null,loading=true,error='';
  const club=()=>clubs.find(x=>x.id===clubId)||null;
  const durations=()=>{
    const raw=club()?.allowedDurations||club()?.durations||[];
    return [...new Set(raw.filter(x=>x?.active!==false).map(x=>Number(x?.minutes??x)).filter(x=>Number.isInteger(x)&&x>=30&&x<=240))].sort((a,b)=>a-b);
  };
  const days=()=>W.days(rangeStart);
  const selectable=s=>W.selectable(s);
  const validDay=d=>d>=limaToday()&&d<=addDays(limaToday(),90);
  function focusMatch(selector,key,value){[...document.querySelectorAll(selector)].find(b=>b.dataset[key]===value&&(!b.getClientRects||b.getClientRects().length))?.focus({preventScroll:true});}
  function cell(day,time,mobile=false){
    const g=W.group(slots,day,time),chosen=selectedDate===day&&selectedTime===time;
    if(!validDay(day)||!g.available.length)return `<span class="week-unavailable" title="${U.esc(g.detail||'El club no publicó turnos para esta hora.')}">${!validDay(day)?day<limaToday()?'Pasado':'Fuera de rango':U.esc(g.label)}</span>`;
    const price=(g.available.length>1?'Desde ':'')+U.money(g.price);
    return `<button type="button" class="week-slot ${chosen?'is-selected':''}" data-turn="${day}|${time}" aria-pressed="${chosen}" aria-label="${U.esc(longDate(day)+', '+time+', '+duration+' minutos, '+price+', '+g.available.length+' canchas disponibles')}">${mobile?`<strong>${time}–${W.time(g.available[0].endAt)}</strong>`:''}<strong>${U.esc(price)}</strong><small>${chosen?'✓ Seleccionado':g.available.length===1?'1 cancha':g.available.length+' canchas'}</small></button>`;
  }
  function scheduleTable(){
    if(loading)return '<div class="week-notice" role="status">Consultando horarios de la semana…</div>';
    if(error)return '';
    if(!durations().length)return '<div class="week-notice" role="status">Este club aún no publicó duraciones de reserva.</div>';
    const week=days(),times=[...new Set(slots.filter(s=>week.includes(s.date)).map(s=>s.time))].sort();
    const dayTimes=[...new Set(slots.filter(s=>s.date===selectedDate).map(s=>s.time))].sort();
    const hasAvailable=slots.some(s=>week.includes(s.date)&&selectable(s));
    return `<section class="week-schedule" aria-label="Horarios disponibles" aria-busy="${loading}">
      <p class="week-help">Selecciona un horario verde. Horas de Lima · ${duration} minutos.</p>
      <div class="week-legend"><span>● Disponible</span><span>● Seleccionado</span><span>● No disponible</span></div>
      ${!hasAvailable?'<p class="week-notice" role="status">No hay turnos disponibles esta semana para esta duración. Revisa los estados de abajo, cambia de semana o consulta con el club.</p>':''}
      <div class="week-desktop"><div class="week-table-scroll" role="region" tabindex="0" aria-label="Calendario de lunes a domingo"><table class="week-table"><caption>Semana del ${U.esc(longDate(week[0]))} al ${U.esc(longDate(week[6]))}</caption><thead><tr><th scope="col">Hora</th>${week.map(day=>`<th scope="col" class="${day===limaToday()?'is-today':''}"><span>${U.esc(new Intl.DateTimeFormat('es-PE',{weekday:'short',timeZone:'UTC'}).format(new Date(day+'T12:00:00Z')))}</span><strong>${Number(day.slice(-2))}</strong>${day===limaToday()?'<small>Hoy</small>':''}</th>`).join('')}</tr></thead><tbody>${times.map(time=>`<tr><th scope="row">${time}</th>${week.map(day=>`<td>${cell(day,time)}</td>`).join('')}</tr>`).join('')||'<tr><td colspan="8">El club no publicó horarios para esta semana y duración.</td></tr>'}</tbody></table></div></div>
      <div class="week-mobile"><div class="week-days" aria-label="Elige un día">${week.map(day=>`<button type="button" data-date="${day}" ${!validDay(day)?'disabled':''} aria-pressed="${day===selectedDate}" class="${day===selectedDate?'is-selected':''}"><span>${U.esc(new Intl.DateTimeFormat('es-PE',{weekday:'short',timeZone:'UTC'}).format(new Date(day+'T12:00:00Z')))}</span><strong>${Number(day.slice(-2))}</strong><small>${day===limaToday()?'Hoy':' '}</small></button>`).join('')}</div><h2>${U.esc(longDate(selectedDate))}</h2><div class="week-mobile-slots">${dayTimes.map(time=>`<div class="week-mobile-row"><span>${time}</span>${cell(selectedDate,time,true)}</div>`).join('')||'<p class="week-notice">Sin horarios publicados para este día y duración. Elige otro día.</p>'}</div></div>
    </section>`;
  }
  function courtPicker(){
    if(!selectedTime||loading||error)return '';
    const g=W.group(slots,selectedDate,selectedTime);
    if(g.available.length<2)return '';
    return `<section class="week-court-picker" aria-labelledby="week-court-title"><h2 id="week-court-title" tabindex="-1">Elige tu cancha</h2><p>${U.esc(longDate(selectedDate))} · ${selectedTime} · ${duration} minutos</p><div>${g.available.map((slot,i)=>`<button type="button" data-court-choice="${i}" aria-pressed="${selected?.courtId===slot.courtId}" class="${selected?.courtId===slot.courtId?'is-selected':''}"><span><strong>${U.esc(slot.courtName)}</strong><small>${U.esc(slot.court?.surface||'')} ${slot.court?.indoor===true?'· Techada':slot.court?.indoor===false?'· Exterior':''}</small></span><b>${U.money(slot.price)}</b></button>`).join('')}</div></section>`;
  }

  async function init(){
    ++requestId; loading=true; selected=null; selectedTime=''; slots=[]; error=''; render();
    try{
      user=await PGOApi.api('/api/auth/context');
      PGOUserHeader.mount('#user-header',{user,active:'Reservar'});
      const rows=await PGOApi.api('/api/clubs');
      if(!Array.isArray(rows))throw new Error('La API de clubes devolvió un formato inesperado.');
      clubs=rows;
      const q=new URLSearchParams(location.search).get('club');
      const remembered=sessionStorage.getItem('pgo-booking-club');
      const initial=clubs.find(c=>c.id===q||c.slug===q)||clubs.find(c=>c.id===remembered)||clubs[0];
      clubId=initial?.id||'';
      const ds=durations();
      duration=ds.includes(90)?90:(ds[0]||90);
      await loadAvailability();
    }catch(e){
      if(e?.status===401){PGOApi.loginRedirect();return;}
      error=e?.message||'No pudimos cargar la reserva.';
      loading=false;render();
    }
  }

  async function loadAvailability(){
    const ticket=++requestId;
    loading=true;error='';selectedTime='';selected=null;render();
    if(!clubId){slots=[];error='No hay clubes disponibles para reservar. Contacta a PGO para habilitar un club.';loading=false;render();return;}
    if(!durations().length){slots=[];loading=false;render();return;}
    try{
      const range=W.range(rangeStart,limaToday());
      if(!range)throw new Error('Elige una semana dentro de los próximos 90 días.');
      const rows=await PGOApi.api(`/api/clubs/${encodeURIComponent(clubId)}/availability?from=${range.from}&to=${range.to}&duration=${duration}`);
      if(ticket!==requestId)return;
      slots=W.normalize(rows);

      // A reservation starts only after an explicit selection in the table.
    }catch(e){
      if(ticket!==requestId)return;
      if(e.status===401){PGOApi.loginRedirect();return;}
      slots=[];error=e instanceof TypeError?'No pudimos conectar con PGO. Reintenta la consulta.':e?.message||'No pudimos consultar la disponibilidad.';
    }finally{if(ticket===requestId){loading=false;render();}}
  }

  function draft(){
    const c=club();
    if(!c||!selected)return null;
    return {
      userId:(user?.user||user)?.id,
      clubId:c.id,
      clubName:c.name||'Club PGO',
      district:c.district||'',
      courtId:selected.courtId,
      courtName:selected.courtName,
      courtMeta:selected.court?.surface||(selected.court?.indoor===true?'Techada':selected.court?.indoor===false?'Exterior':'Superficie no indicada'),
      date:selectedDate,
      dateLabel:longDate(selectedDate),
      time:selectedTime,
      startAt:selected.startAt,
      endAt:selected.endAt,
      durationMinutes:duration,
      price:Number(selected.price||0)
    };
  }

  function render(){
    const c=club(),durs=durations(),d=draft(),week=days();
    app.className='figma-booking-page week-booking-page';
    app.innerHTML=`<section class="figma-booking-body">
      <h1>¿Cuándo quieres jugar?</h1><p class="figma-booking-subtitle">Elige un horario disponible y continúa con tu reserva.</p>
      ${error?`<div class="figma-inline-error" role="alert">${U.esc(error)} <button type="button" class="btn btn-outline" id="booking-retry">Reintentar</button></div>`:''}
      <div class="figma-booking-grid"><div class="figma-booking-form">
        <div class="week-tools"><label class="week-club"><span>Club</span><select id="booking-club" ${!clubs.length?'disabled':''}>${!clubs.length?'<option value="">Sin clubes disponibles</option>':''}${clubs.map(x=>`<option value="${U.esc(x.id)}" ${x.id===clubId?'selected':''}>${U.esc(x.name||'Club PGO')}</option>`).join('')}</select></label>
        ${durs.length>1?`<label class="week-duration"><span>Duración</span><select id="booking-duration" ${!clubId?'disabled':''}>${durs.map(x=>`<option value="${x}" ${duration===x?'selected':''}>${x} minutos</option>`).join('')}</select></label>`:`<span class="week-duration-copy">${durs.length?duration+' minutos':'Sin duraciones publicadas'}</span>`}</div>
        <div class="week-navigation"><div><strong>${U.esc(longDate(week[0]))} – ${U.esc(longDate(week[6]))}</strong><small>Disponibilidad semanal · lunes a domingo</small></div><div class="week-navigation-actions"><button type="button" data-week="-1" aria-label="Semana anterior" ${!W.range(addDays(rangeStart,-7),limaToday())?'disabled':''}>‹</button><button type="button" id="week-today">Esta semana</button><button type="button" data-week="1" aria-label="Semana siguiente" ${!W.range(addDays(rangeStart,7),limaToday())?'disabled':''}>›</button></div></div>
        ${scheduleTable()}${courtPicker()}
      </div><aside class="figma-booking-summary" aria-label="Resumen de tu reserva"><h2>Tu reserva</h2><strong>${U.esc(c?.name||'Selecciona un club')}</strong><div class="week-summary-details" aria-live="polite" aria-atomic="true">${d?`<p>${U.esc(longDate(selectedDate))}</p><p><b>${selectedTime}–${W.time(selected.endAt)}</b> · ${duration} minutos</p><p>${U.esc(selected.courtName)}</p>`:selectedTime?`<p>${U.esc(longDate(selectedDate))} · ${selectedTime}</p><p>Elige una cancha para este turno.</p>`:'<p>Selecciona un horario verde en el calendario.</p>'}</div><hr><div class="figma-total-row"><span>Total</span><b>${d?U.money(d.price):'—'}</b></div><button type="button" id="booking-continue" class="figma-large-primary" ${!d||loading?'disabled':''}>Continuar con esta reserva</button><small>La reserva se confirma en el siguiente paso. Disponibilidad sujeta a confirmación.</small></aside></div>
    </section>`;
    bind();
    const chip=[...document.querySelectorAll('[data-date]')].find(b=>b.dataset.date===selectedDate);
    if(chip?.getClientRects?.().length)chip.scrollIntoView({block:'nearest',inline:'nearest'});
  }
  function chooseTurn(value){
    const [day,time]=value.split('|');
    if(!validDay(day))return;
    const g=W.group(slots,day,time);if(!g.available.length||loading)return;
    selectedDate=day;selectedTime=time;selected=g.available.length===1?g.available[0]:null;render();
    if(g.available.length>1)document.querySelector('#week-court-title')?.focus();else focusMatch('[data-turn]','turn',value);
  }
  function changeWeek(start){
    if(!W.range(start,limaToday()))return;
    rangeStart=start;selectedDate=days().includes(limaToday())?limaToday():days().find(validDay);loadAvailability();
  }
  function bind(){
    document.querySelector('#booking-retry')?.addEventListener('click',()=>{if(clubs.length)loadAvailability();else init()});
    document.querySelectorAll('[data-turn]').forEach(b=>b.addEventListener('click',()=>chooseTurn(b.dataset.turn)));
    document.querySelectorAll('[data-court-choice]').forEach(b=>b.addEventListener('click',()=>{
      const g=W.group(slots,selectedDate,selectedTime),slot=g.available[Number(b.dataset.courtChoice)];if(!slot||loading)return;selected=slot;render();focusMatch('[data-court-choice]','courtChoice',b.dataset.courtChoice);
    }));
    document.querySelector('#booking-club')?.addEventListener('change',e=>{
      clubId=e.target.value;sessionStorage.setItem('pgo-booking-club',clubId);
      const ds=durations();duration=ds.includes(90)?90:(ds[0]||90);selectedDate=limaToday();rangeStart=W.monday(limaToday());loadAvailability();
    });
    document.querySelectorAll('[data-date]').forEach(b=>b.addEventListener('click',()=>{if(!validDay(b.dataset.date)||loading)return;selectedDate=b.dataset.date;selectedTime='';selected=null;render();focusMatch('[data-date]','date',selectedDate)}));
    document.querySelectorAll('[data-week]').forEach(b=>b.addEventListener('click',()=>changeWeek(addDays(rangeStart,Number(b.dataset.week)*7))));
    document.querySelector('#week-today')?.addEventListener('click',()=>changeWeek(W.monday(limaToday())));
    document.querySelector('#booking-duration')?.addEventListener('change',e=>{const value=Number(e.target.value);if(!durations().includes(value))return;duration=value;loadAvailability();});
    document.querySelector('#booking-continue')?.addEventListener('click',()=>{
      const d=draft();if(!d||loading||!selectable(selected))return;
      sessionStorage.setItem(DRAFT_KEY,JSON.stringify(d));location.href='/reservar-cancha/checkout/';
    });
  }
  window.addEventListener('pageshow',e=>{if(e.persisted){selectedDate=limaToday();rangeStart=W.monday(limaToday());init()}});
  init();
});
