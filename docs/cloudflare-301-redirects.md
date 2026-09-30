# Real 301s for the old root URLs (Cloudflare)

## Why this exists

GitHub Pages serves static files only, so `https://saonbd1.github.io/tools/…` can
answer with a 0-second `meta refresh` plus `rel=canonical` (what
`scripts/make_root_redirects.rb` generates) but never with an HTTP 301. Google
honours a 0-second refresh and consolidates through the canonical, but a real 301
is faster and unambiguous.

To emit a 301 something must sit in front of the host — and Cloudflare can only
proxy a domain **you own** (`saonbd1.github.io` belongs to GitHub and cannot be
added to Cloudflare).

**Prerequisite: a domain of your own** (e.g. `lightseotools.com`), plus admin
rights on both GitHub repositories.

## What changes once the domain is attached

GitHub's docs: *"if you set a custom domain for a user site … that same custom
domain will be used for all project sites owned by the same account"*. So:

| Before | After |
| --- | --- |
| `https://saonbd1.github.io/` | `https://<domain>/` |
| `https://saonbd1.github.io/light-seo-tools/` | `https://<domain>/light-seo-tools/` |
| `https://saonbd1.github.io/tools/x.html` | `https://<domain>/tools/x.html` → **301** → `https://<domain>/light-seo-tools/tools/x.html` |

Canonicals, Open Graph, JSON-LD, the sitemap and `robots.txt` are all built from
`url:` in `_config.yml`, so that value has to change as well. Hence the order
below.

## Step 1 — add the domain to Cloudflare

Free plan is enough:

| | Free | Pro | Business | Enterprise |
| --- | --- | --- | --- | --- |
| Bulk Redirects | Yes (15 rules / 5 lists / 10,000 redirects) | Yes | Yes | Yes |
| Single Redirects | Yes (10 rules, wildcard support) | Yes | Yes | Yes |

Change the registrar's nameservers to the ones Cloudflare assigns, and wait until
the zone status is **Active**.

## Step 2 — DNS records (proxied)

| Type | Name | Content | Proxy status |
| --- | --- | --- | --- |
| `CNAME` | `@` | `saonbd1.github.io` | Proxied |
| `CNAME` | `www` | `saonbd1.github.io` | Proxied |

Cloudflare flattens a CNAME at the apex; do not point A records at GitHub's IPs.

## Step 3 — attach the domain to the user site

`saonbd1/saonbd1.github.io` → **Settings → Pages → Custom domain** → `<domain>` → Save.

- GitHub commits a `CNAME` file to the repository root — keep it, it is what serves
  the domain.
- Tick **Enforce HTTPS**; certificate issuance can take a while.
- Cloudflare → SSL/TLS → Overview → mode **Full (strict)**.

## Step 4 — repoint the site's own URLs (do this before step 5)

1. Tools repository (`light-seo-tools-site`): `_config.yml` → `url: "https://<domain>"`
   (leave `baseurl: "/light-seo-tools"` alone — the guard workflow pins it).
2. Root repository (`saonbd1-root-site`): regenerate the stubs against the new host
   ```powershell
   ruby scripts/make_root_redirects.rb <domain>
   ```
3. Commit and push both repositories. The guard workflows must stay green.

## Step 5 — create the 301 rule in Cloudflare

**Recommended: one dynamic Single Redirect rule** (covers all 41 tool pages *and*
the top-level pages, and any old tool URL you may have forgotten).

Rules → **Redirect Rules** → Create rule

*When incoming requests match* → Custom filter expression:

```
(http.host eq "<domain>" and (http.request.uri.path eq "/" or http.request.uri.path in {"/about/" "/contact.html" "/request.html" "/legal.html" "/terms.html" "/privacy-policy.html" "/disclosure.html" "/admin.html" "/login.html"} or starts_with(http.request.uri.path, "/tools/")))
```

*Then* → URL redirect:

- Type: **Dynamic**
- Expression:

```
concat("https://<domain>/light-seo-tools", http.request.uri.path)
```

- Status code: **301**
- Preserve query string: **on**

Notes:

- Use a literal `<domain>` in the expression (not `http.host`) so a `www` hit still
  lands on the canonical host. If you keep both hosts live, add
  `or http.host eq "www.<domain>"` to the filter.
- `"/"` is in the list only while the root is empty — **remove it** when the new
  root site goes live, otherwise the rule keeps redirecting your homepage.
- New paths (`/light-seo-tools/...`) are not matched, so the tools site is untouched.
- Keep the meta-refresh stubs in the root repository: they are the fallback if
  Cloudflare is ever removed, and harmless while the 301 fires first.

**Alternative: Bulk Redirects from a CSV** (static list, easiest to eyeball/verify):

```powershell
ruby scripts/make_cloudflare_redirects.rb <domain> docs/cloudflare/bulk-redirects-<domain>.csv
```

Rules → Redirect Rules → **Bulk Redirects** → Create list → **Import CSV** → then
create a Bulk Redirect rule that references the list. The CSV has no header row and
`301` with query-string preservation, as Cloudflare requires.

## Step 6 — verify

```powershell
curl -I https://<domain>/tools/duplicate-url-finder.html   # 301 -> /light-seo-tools/tools/duplicate-url-finder.html
curl -I https://<domain>/contact.html                      # 301 -> /light-seo-tools/contact.html
curl -I https://<domain>/light-seo-tools/                  # 200
curl -I https://saonbd1.github.io/light-seo-tools/          # GitHub redirects to the custom domain
curl -s https://<domain>/light-seo-tools/sitemap.xml | head -3
curl -s https://<domain>/light-seo-tools/tools/tools-overview.html | grep -o '<link rel="canonical"[^>]*>'
```

Everything must show the new host in canonicals.

## Step 7 — Search Console

- Add the new domain as a property (DNS verification is easiest through Cloudflare).
- Submit `https://<domain>/light-seo-tools/sitemap.xml`.
- Keep the old `saonbd1.github.io` property for a few months to watch the transition.

## Step 8 — if you ever change the domain again

`url:` in `_config.yml` → `ruby scripts/make_root_redirects.rb <new-host>` →
`ruby scripts/make_cloudflare_redirects.rb <new-host>` → update the rule filter.
