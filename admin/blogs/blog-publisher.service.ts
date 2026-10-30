import { Injectable, ConflictException, InternalServerErrorException, NotFoundException } from '@nestjs/common';
import { S3Client, GetObjectCommand, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminAuditService } from '../audit/admin-audit.service';
import type { CurrentAdmin } from '../auth/admin-auth.types';

const escapeHtml = (s: string) => String(s ?? '').replace(/[&<>"']/g, c => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' }[c]!));
const BUCKET = 'www.chapatupremio.com';
const ORIGIN = 'https://www.pgoapp.com';

@Injectable()
export class BlogPublisherService {
  private readonly s3 = new S3Client({region: 'us-east-1'});
  constructor(private readonly prisma:PrismaService, private readonly audit:AdminAuditService){}
  private async fetch(key:string) {
    try {const obj = await this.s3.send(new GetObjectCommand({Bucket:BUCKET, Key:key}));return await obj.Body!.transformToString();}
    catch(e:any){if(e?.name==='NoSuchKey'||e?.name==='NotFound'||e?.$metadata?.httpStatusCode===404)return null;throw e;}
  }
  private async write(key:string, body:string, type:string) {
    await this.s3.send(new PutObjectCommand({Bucket:BUCKET,Key:key,Body:Buffer.from(body,'utf8'),ContentType:type,CacheControl:'no-cache, max-age=0'}));
  }
  private render(a:any) {
    const url=`${ORIGIN}/blog/${a.slug}/`;
    const title=a.seoTitle||a.title;
    const description=a.seoDescription||a.excerpt;
    // Allow only structural, attribute-free tags from the CMS editor.
    const safeContent=escapeHtml(a.contentHtml).replace(/&lt;(\/?)(p|h2|h3|h4|ul|li|strong|em)&gt;/gi, '<$1$2>');
    const json=JSON.stringify({'@context':'https://schema.org','@type':'BlogPosting',headline:a.title,description,mainEntityOfPage:url,inLanguage:'es-PE',publisher:{'@type':'Organization',name:'PGO',url:ORIGIN}}).replace(/</g,'\\u003c');
    return `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escapeHtml(title)}</title><meta name="description" content="${escapeHtml(description)}"><link rel="canonical" href="${url}"><meta property="og:type" content="article"><meta property="og:title" content="${escapeHtml(a.title)}"><meta property="og:description" content="${escapeHtml(description)}"><meta property="og:url" content="${url}"><link rel="stylesheet" href="/assets/css/styles.css"><link rel="stylesheet" href="/assets/css/blog-editorial.css"><link rel="stylesheet" href="/assets/css/pgo-managed-article.css"><script src="/assets/js/config.js" defer></script><script src="/assets/js/api.js" defer></script><script src="/assets/js/utils.js" defer></script><script type="application/ld+json">${json}</script></head><body><div data-site-header></div><main class="container pgo-managed-article"><article><div class="eyebrow">${escapeHtml(a.category)}</div><h1>${escapeHtml(a.title)}</h1><p class="pgo-managed-excerpt">${escapeHtml(a.excerpt)}</p><img class="pgo-managed-cover" src="/assets/landing/padel-court.webp" alt="Cancha de pádel" loading="eager"><div class="pgo-managed-body">${safeContent}</div></article><p><a class="btn btn-primary" href="/blog/">Volver al blog</a></p></main><div data-site-footer></div><script src="/assets/js/site.js" defer></script><script src="/assets/js/session-ui.js" defer></script></body></html>`;
  }
  private async feed() {
    const content=await this.fetch('blog/cms-feed.json');
    if(!content) return [] as any[];
    const data=JSON.parse(content);
    if(!Array.isArray(data))throw new ConflictException('Índice CMS inválido; publicación detenida');
    return data;
  }
  private async refreshFeed() {
    const items=await this.prisma.blogArticle.findMany({where:{status:'PUBLISHED',deletedAt:null},orderBy:{updatedAt:'desc'}});
    const data=items.map(a=>({id:a.id,slug:a.slug,url:`/blog/${a.slug}/`,title:a.title,excerpt:a.excerpt,category:a.category,image:'/assets/landing/padel-court.webp',publishedAt:a.createdAt.toISOString(),updatedAt:a.updatedAt.toISOString()}));
    await this.write('blog/cms-feed.json',JSON.stringify(data,null,2),'application/json; charset=utf-8');
    return data;
  }
  async publish(id:string, admin:CurrentAdmin) {
    const article=await this.prisma.blogArticle.findFirst({where:{id,deletedAt:null}});
    if(!article)throw new NotFoundException('Artículo no encontrado');
    if(!article.contentHtml?.trim()||!article.seoDescription?.trim())throw new ConflictException('Completa contenido y SEO antes de publicar');
    const key=`blog/${article.slug}/index.html`;
    const previous=await this.fetch(key);
    // Existing public articles not previously managed by this CMS cannot be overwritten.
    if(previous!==null && article.status!=='PUBLISHED')throw new ConflictException('La URL ya existe en S3. No se sobrescriben artículos ajenos al CMS');
    const backup=previous===null?null:`blog/cms-backups/${article.id}/${Date.now()}.html`;
    if(backup)await this.write(backup,previous!,'text/html; charset=utf-8');
    await this.write(key,this.render(article),'text/html; charset=utf-8');
    try {
      await this.prisma.blogArticle.update({where:{id},data:{status:'PUBLISHED',updatedByAdminId:admin.id}});
      await this.refreshFeed();
      await this.audit.log({adminUserId:admin.id,action:'BLOG_PUBLISHED',entityType:'BLOG',entityId:id,metadata:{slug:article.slug,backup}});
    }catch(e){throw new InternalServerErrorException('HTML publicado, pero no se completó la sincronización del catálogo. Requiere reconciliación');}
    return {id,status:'PUBLISHED',url:`${ORIGIN}/blog/${article.slug}/`,backup};
  }
  async unpublish(id:string,admin:CurrentAdmin) {
    const a=await this.prisma.blogArticle.findFirst({where:{id,deletedAt:null}});
    if(!a)throw new NotFoundException('Artículo no encontrado');
    if(a.status!=='PUBLISHED')throw new ConflictException('Este artículo no está publicado por el CMS');
    const key=`blog/${a.slug}/index.html`;
    const previous=await this.fetch(key);
    const backup=previous===null?null:`blog/cms-backups/${a.id}/${Date.now()}.html`;
    if(backup)await this.write(backup,previous!,'text/html; charset=utf-8');
    await this.s3.send(new DeleteObjectCommand({Bucket:BUCKET,Key:key}));
    await this.prisma.blogArticle.update({where:{id},data:{status:'DRAFT',updatedByAdminId:admin.id}});
    await this.refreshFeed();
    await this.audit.log({adminUserId:admin.id,action:'BLOG_UNPUBLISHED',entityType:'BLOG',entityId:id,metadata:{slug:a.slug,backup}});
    return {id,status:'DRAFT',backup};
  }
}
