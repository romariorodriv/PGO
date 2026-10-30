"""Validate local public SEO without dependencies or network access."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit, unquote
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ORIGIN = 'https://pgoapp.com'


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.tags = []
        self.feed(path.read_text(encoding='utf-8'))

    def handle_starttag(self, tag, attrs):
        self.tags.append((tag, dict(attrs)))


def file_for(url):
    path = unquote(urlsplit(url).path).lstrip('/')
    return ROOT / path / 'index.html' if not Path(path).suffix else ROOT / path


def canonical(page):
    return [a['href'] for t, a in page.tags if t == 'link' and a.get('rel') == 'canonical']


def alternates(page):
    return {a['hreflang']: a['href'] for t, a in page.tags if t == 'link' and 'hreflang' in a}


ns = {'s': 'http://www.sitemaps.org/schemas/sitemap/0.9'}
urls = [n.text for n in ET.parse(ROOT / 'sitemap.xml').findall('.//s:loc', ns)]
assert len(urls) == len(set(urls)), 'Duplicate sitemap entries'
assert not any(urlsplit(u).path.split('/')[1] in {'perfil', 'mis-reservas', 'login', 'registro', 'admin', 'club-manager'} for u in urls)
for url in urls:
    assert url.startswith(ORIGIN + '/'), url
    path = file_for(url)
    assert path.is_file(), url
    page = Page(path)
    assert canonical(page) == [url], (url, canonical(page))
    assert sum(t == 'h1' for t, _ in page.tags) == 1, url
    assert any(t == 'title' for t, _ in page.tags), url
    assert any(t == 'meta' and a.get('name') == 'description' and a.get('content') for t, a in page.tags), url
    assert not any(t == 'meta' and a.get('name') == 'robots' and any(x in a.get('content', '').lower() for x in ['noindex', 'none']) for t, a in page.tags), url
    for tag, attrs in page.tags:
        href = attrs.get('href', '')
        if tag != 'a' or not href or href.startswith(('mailto:', 'tel:')):
            continue
        target = urlsplit(href)
        if target.netloc and target.netloc != 'pgoapp.com':
            assert target.netloc != 'www.pgoapp.com', (url, href)
            continue
        dest = path if not target.path else file_for(href if target.path.startswith('/') else url + href)
        assert dest.is_file(), (url, href)
        if target.fragment:
            assert any(a.get('id') == unquote(target.fragment) for _, a in Page(dest).tags), (url, href)

cluster = {lang: ORIGIN + route for lang, route in [('es', '/'), ('en', '/en/'), ('pt', '/pt/'), ('fr', '/fr/'), ('it', '/it/')]}
for lang, url in cluster.items():
    page = Page(file_for(url))
    links = alternates(page)
    assert all(links.get(k) == v for k, v in cluster.items()), url
    assert canonical(page) == [url], url
    assert any(t == 'html' and a.get('lang') == lang for t, a in page.tags), url
for entry in ET.parse(ROOT / 'sitemap-idiomas.xml').getroot():
    assert entry.find('s:loc', ns).text in cluster.values()
    links = {n.attrib['hreflang']: n.attrib['href'] for n in entry if n.tag.endswith('link')}
    assert links == cluster

source = (ROOT / 'blog/index.html').read_text(encoding='utf-8')
seed = json.loads(source.split('<script id="pgo-blog-seed" type="application/json">')[1].split('</script>')[0])
initial_grid = source.split('<div id="blog-grid" class="blog-grid">')[1].split('<div id="blog-empty"')[0]
for article in seed:
    assert file_for(article['url']).is_file()
    assert article['url'] in initial_grid
assert f'{len(seed)} art' in source
print(f'PASS: {len(urls)} public URLs; metadata, H1, canonical, links/anchors, reciprocal hreflang, XML and {len(seed)} initial blog cards.')
