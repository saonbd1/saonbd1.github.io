# saonbd1.github.io — root site

This repository publishes the **root** of <https://saonbd1.github.io/>.

The free SEO tools site no longer lives here. It has its own repository and is
published as a *project site* one level down, which is what puts it back at the
subpath it used to live on:

- source: <https://github.com/saonbd1/light-seo-tools>
- published at: <https://saonbd1.github.io/light-seo-tools/>
- local preview: `cd light-seo-tools-site; bundle exec jekyll serve` → <http://127.0.0.1:4000/light-seo-tools/>

## What is in this repository now

| Path | Purpose |
| --- | --- |
| `index.html` | interim redirect to `/light-seo-tools/` — replace it with the new root site when ready |
| `tools/<slug>.html` | redirect stubs: old `/tools/…` URLs → `/light-seo-tools/tools/…` |
| `about/index.html`, `contact.html`, `request.html`, `legal.html`, `terms.html`, `privacy-policy.html`, `disclosure.html`, `admin.html`, `login.html` | redirect stubs for the old root pages |
| `googleb05f2511ab0eee73.html` | Google Search Console verification file — **must stay at the domain root** |
| `robots.txt` | root robots.txt (crawlers only read this one); points at the new sitemap |
| `404.html` | simple not-found page linking to the tools site |
| `scripts/make_root_redirects.rb` | regenerates the redirect stubs |
| `_config.yml` | keeps `scripts/` and this README out of the published site |

## Notes

- GitHub Pages only serves static files, so real HTTP 301s are not possible: the
  stubs use `meta refresh` + `rel=canonical` + `noindex`, the same technique
  `jekyll-redirect-from` uses.
- The stubs are intentionally `noindex` and are not listed in any sitemap.
- Plain `.html` files in this repository have no YAML front matter on purpose:
  Jekyll then copies them verbatim instead of rendering them.
- Search Console is verified at the root, so that verification file must not move.
