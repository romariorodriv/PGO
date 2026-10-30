(() => {
  const menuButton=document.querySelector('.menu-toggle'),nav=document.getElementById('main-nav');
  const lang=document.documentElement.lang||'es';
  const txt=(key)=>window.PGO_I18N?.[lang]?.[key]||window.PGO_I18N?.es?.[key]||key;
  const closeMenu=()=>{nav?.classList.remove('open');menuButton?.setAttribute('aria-expanded','false');menuButton?.setAttribute('aria-label',txt('Abrir menú'));};
  menuButton?.addEventListener('click',()=>{const open=nav.classList.toggle('open');menuButton.setAttribute('aria-expanded',String(open));menuButton.setAttribute('aria-label',open?txt('Cerrar menú'):txt('Abrir menú'));});
  nav?.querySelectorAll('a').forEach(a=>a.addEventListener('click',closeMenu));
  document.addEventListener('keydown',e=>{if(e.key==='Escape')closeMenu();});
  window.addEventListener('resize',()=>{if(window.innerWidth>800)closeMenu();});
  const year=document.getElementById('year');if(year)year.textContent=String(new Date().getFullYear());
  const dialog=document.getElementById('demo-dialog'),form=document.getElementById('demo-form'),feedback=document.getElementById('demo-feedback'),ready=document.getElementById('demo-ready');
  let opener=null,message='';
  document.querySelectorAll('[data-demo]').forEach(link=>link.addEventListener('click',e=>{
    if(typeof dialog?.showModal!=='function')return;
    e.preventDefault();opener=link;const product=document.getElementById('demo-product');if(product)product.value=link.dataset.plan||'';closeMenu();dialog.showModal();
  }));
  dialog?.querySelector('.dialog-close')?.addEventListener('click',()=>dialog.close());
  dialog?.addEventListener('close',()=>opener?.focus());
  form?.addEventListener('submit',e=>{
    e.preventDefault();feedback.textContent='';if(!form.reportValidity())return;
    const data=Object.fromEntries(new FormData(form));
    const product=String(data.product||'').trim(),name=String(data.name||'').trim(),club=String(data.club||'').trim(),city=String(data.city||'').trim(),email=String(data.email||'').trim(),phone=String(data.phone||'').trim(),courts=Number(data.courts);
    if([name,club,city].some(v=>v.length<2)||!Number.isInteger(courts)||courts<1||courts>100){feedback.textContent=txt('validation');return;}
    message=txt('emailTemplate')({product,name,club,email,phone,city,courts});
    const href='mailto:soporte@pgoapp.com?subject='+encodeURIComponent(txt('emailSubject')+' — '+club)+'&body='+encodeURIComponent(message);
    document.getElementById('demo-mail-link').href=href;
    document.getElementById('demo-message').value=message;
    form.hidden=true;ready.hidden=false;document.getElementById('demo-mail-link').focus();
  });
  document.getElementById('copy-demo')?.addEventListener('click',async e=>{
    const button=e.currentTarget;
    try{if(!navigator.clipboard?.writeText)throw Error('Clipboard unavailable');await navigator.clipboard.writeText(message);button.textContent=txt('copied');}
    catch{const text=document.getElementById('demo-message');text.focus();text.select();button.textContent=txt('selectCopy');}
  });
})();

(() => {
  if('IntersectionObserver' in window&&!window.matchMedia('(prefers-reduced-motion: reduce)').matches){
    const observer=new IntersectionObserver(entries=>entries.forEach(entry=>{
      if(entry.isIntersecting){entry.target.classList.add('visible');observer.unobserve(entry.target);}
    }),{threshold:.08});
    document.querySelectorAll('.reveal').forEach(item=>observer.observe(item));
    document.body.classList.add('motion-ready');
  }
})();
