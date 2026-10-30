window.PGOUtil={
 esc(v){return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));},
 money(v){return `S/ ${Number(v||0).toFixed(2)}`;},
 date(v){try{return new Date(v).toLocaleString('es-PE',{timeZone:'America/Lima'});}catch{return v||'';}},
 initials(name){return String(name||'PG').trim().split(/\s+/).slice(0,2).map(x=>x[0]?.toUpperCase()).join('')||'PG';},
 qs(s){return document.querySelector(s);}, qsa(s){return [...document.querySelectorAll(s)]}
};