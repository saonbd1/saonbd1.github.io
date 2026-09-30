# Creates the root-level soft-redirect stubs that keep the OLD root URLs alive
# after the Light SEO Tools site moved to https://saonbd1.github.io/light-seo-tools/
#
#   /tools/<slug>.html  ->  /light-seo-tools/tools/<slug>.html
#   /about/             ->  /light-seo-tools/about/
#   /contact.html       ->  /light-seo-tools/contact.html   (and the other pages)
#   /                   ->  /light-seo-tools/               (interim; replace index.html
#                                                           with the real root site later)
#
# Run from the root repository (saonbd1/saonbd1.github.io) while tools/*.md still
# exist, because the tool slugs are read from that folder:
#
#   ruby scripts/make_root_redirects.rb
#
# GitHub Pages cannot send real HTTP 301s, so these stubs use the same technique
# jekyll-redirect-from uses: meta refresh + canonical + noindex.

require "fileutils"

SITE = "https://saonbd1.github.io"
SUB  = "/light-seo-tools"

def write_stub(relative_path, target)
  FileUtils.mkdir_p(File.dirname(relative_path))
  File.write(relative_path, <<~HTML, encoding: "UTF-8")
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>Redirecting&hellip;</title>
    <link rel="canonical" href="#{target}">
    <meta http-equiv="refresh" content="0; url=#{target}">
    <meta name="robots" content="noindex">
    </head>
    <body>
    <h1>Redirecting&hellip;</h1>
    <p><a href="#{target}">Click here if you are not redirected.</a></p>
    </body>
    </html>
  HTML
  puts "wrote #{relative_path} -> #{target}"
end

# 1) Tool pages: read the slugs from tools/*.md (before the site moved out) or
#    from the existing stubs (so the script stays re-runnable afterwards).
slugs = Dir.glob("tools/*.md").map { |file| File.basename(file, ".md") }
slugs = Dir.glob("tools/*.html").map { |file| File.basename(file, ".html") } if slugs.empty?
slugs.reject! { |slug| slug.casecmp("README").zero? }
if slugs.empty?
  abort "No tools/*.md or tools/*.html found. Run this from the repository root."
end
slugs.sort.each do |slug|
  write_stub("tools/#{slug}.html", "#{SITE}#{SUB}/tools/#{slug}.html")
end

# 2) Top-level pages of the old site.
{
  "index.html"          => "/",
  "about/index.html"    => "/about/",
  "contact.html"        => "/contact.html",
  "request.html"        => "/request.html",
  "legal.html"          => "/legal.html",
  "terms.html"          => "/terms.html",
  "privacy-policy.html" => "/privacy-policy.html",
  "disclosure.html"     => "/disclosure.html",
  "admin.html"          => "/admin.html",
  "login.html"          => "/login.html"
}.each { |relative_path, path| write_stub(relative_path, "#{SITE}#{SUB}#{path}") }

puts "Done. #{slugs.size + 10} stub(s)."
