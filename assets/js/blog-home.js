(()=>{'use strict';
const root=document.getElementById('pgo-home-blog');if(!root)return;
const escape=s=>String(s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const local=[...root.querySelectorAll('article')].map((n,i)=>({title:n.querySelector('h3 a')?.textContent||'',url:n.querySelector('h3 a')?.getAttribute('href')||'',excerpt:n.querySelector('p')?.textContent||'',category:n.querySelector('.pgo-blog-tag')?.textContent||'BLOG PGO',image:'',sort:-i-1}));
const safePath=value=>{try{const u=new URL(value,location.origin);return u.origin===location.origin&&/^\/blog\/[a-z0-9-]+\/$/.test(u.pathname)?u.pathname:null}catch{return null}};
function draw(feed){const map=new Map();local.forEach(a=>{const url=safePath(a.url);if(url)map.set(url,{...a,url})});feed.forEach(a=>{const url=safePath(a.url);if(url&&a.title)map.set(url,{...map.get(url),...a,url,sort:Date.parse(a.publishedAt||a.updatedAt||0)||0})});const items=[...map.values()].sort((a,b)=>b.sort-a.sort).slice(0,4);
root.innerHTML=items.map(a=>`<article class="pgo-blog-card">${a.image?`<a href="${escape(a.url)}" class="pgo-blog-image"><img src="${escape(a.image)}" alt="" loading="lazy" decoding="async"></a>`:''}<span class="pgo-blog-tag">${escape(a.category||'BLOG PGO')}</span><h3><a href="${escape(a.url)}">${escape(a.title)}</a></h3><p>${escape(a.excerpt||'')}</p><a class="pgo-blog-read" href="${escape(a.url)}">Leer artículo →</a></article>`).join('');}
fetch('/blog/cms-feed.json',{cache:'no-store'}).then(r=>{if(!r.ok)throw Error('HTTP '+r.status);return r.json()}).then(d=>{if(!Array.isArray(d))throw Error('Feed inválido');draw(d)}).catch(e=>{console.warn('Blog CMS no disponible',e);draw([])});
})();
