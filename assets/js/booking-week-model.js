/* Shared calendar rules: no network calls and no invented availability. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.PGOBookingWeek=factory();})(typeof window!=='undefined'?window:globalThis,function(){
  const addDays=(day,n)=>{const d=new Date(day+'T12:00:00Z');d.setUTCDate(d.getUTCDate()+n);return d.toISOString().slice(0,10)};
  const monday=day=>addDays(day,-((new Date(day+'T12:00:00Z').getUTCDay()+6)%7));
  const days=start=>Array.from({length:7},(_,i)=>addDays(start,i));
  const date=v=>new Intl.DateTimeFormat('en-CA',{timeZone:'America/Lima',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(v));
  const time=v=>new Intl.DateTimeFormat('es-PE',{timeZone:'America/Lima',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).format(new Date(v));
  const labels={PRICE_NOT_CONFIGURED:'Sin tarifa',MAINTENANCE:'Mantenimiento',BLOCKED:'Bloqueado',OCCUPIED:'Ocupado',PAST:'Pasado',CLOSED:'Cerrado'};
  function normalize(rows){
    if(!Array.isArray(rows))throw new Error('Respuesta de disponibilidad inválida.');
    return rows.map(s=>{
      const courtId=s.court?.id||s.courtId,price=Number(s.price);
      if(!courtId||!Number.isFinite(Date.parse(s.startAt))||!Number.isFinite(Date.parse(s.endAt))||Date.parse(s.endAt)<=Date.parse(s.startAt))throw new Error('El club devolvió un turno incompleto. Reintenta la consulta.');
      const validPrice=Number.isFinite(price)&&price>0;
      return {...s,courtId,courtName:s.court?.name||s.courtName||'Cancha',date:date(s.startAt),time:time(s.startAt),price,available:s.available===true&&validPrice&&s.court?.status!=='MAINTENANCE',reason:s.court?.status==='MAINTENANCE'?'MAINTENANCE':s.reason||(s.available===true&&!validPrice?'PRICE_NOT_CONFIGURED':null)};
    });
  }
  const selectable=(slot,now=Date.now())=>slot.available===true&&Number.isFinite(slot.price)&&slot.price>0&&Date.parse(slot.startAt)>Number(now);
  function group(slots,day,hour,now=Date.now()){
    const all=slots.filter(s=>s.date===day&&s.time===hour);
    const available=[...new Map(all.filter(s=>selectable(s,now)).map(s=>[s.courtId,s])).values()].sort((a,b)=>a.price-b.price||a.courtName.localeCompare(b.courtName));
    const reasons=[...new Set(all.map(s=>Date.parse(s.startAt)<=Number(now)?'PAST':s.reason||'UNAVAILABLE'))];
    return {all,available,price:available.length?Math.min(...available.map(s=>s.price)):null,label:all.length?(reasons.length===1?labels[reasons[0]]||'No disponible':'No disponible'):'Sin turnos',detail:reasons.map(r=>labels[r]||'No disponible').join(' · ')};
  }
  function range(start,today){const week=days(start),from=week[0]<today?today:week[0],limit=addDays(today,90),to=week[6]>limit?limit:week[6];return from<=to?{from,to}:null;}
  return {addDays,monday,days,date,time,normalize,selectable,group,range};
});
