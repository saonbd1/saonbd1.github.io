# Generates a Cloudflare Bulk Redirects CSV for the legacy root URLs, so they can
# answer with a real HTTP 301 once the domain is behind Cloudflare.
#
# Usage:
#   ruby scripts/make_cloudflare_redirects.rb <domain> [output.csv]
#   ruby scripts/make_cloudflare_redirects.rb lightseotools.com
#   ruby scripts/make_cloudflare_redirects.rb www.lightseotools.com docs/cloudflare/bulk-redirects.csv
#
# Output rows follow Cloudflare's CSV format:
#   <SOURCE_URL>,<TARGET_URL>[,<STATUS_CODE>,<PRESERVE_QUERY_STRING>,...]
# with no header row (Cloudflare rejects one) and status 301.
#
# See docs/cloudflare-301-redirects.md for the full runbook.

require "fileutils"

host = ARGV[0].to_s.strip.sub(%r{\Ahttps?://}, "").sub(%r{/\z}, "")
if host.empty?
  abort "Usage: ruby scripts/make_cloudflare_redirects.rb <domain> [output.csv]\n" \
        "Example: ruby scripts/make_cloudflare_redirects.rb lightseotools.com"
end
out = ARGV[1] || "docs/cloudflare/bulk-redirects-#{host}.csv"

SUB = "/light-seo-tools"

# 1) Tool pages: one redirect per stub in tools/.
slugs = Dir.glob("tools/*.html").map { |file| File.basename(file, ".html") }
slugs.reject! { |slug| slug.casecmp("README").zero? }
if slugs.empty?
  abort "No tools/*.html stubs found. Run this from the repository root."
end

pairs = slugs.sort.map { |slug| ["/tools/#{slug}.html", "#{SUB}/tools/#{slug}.html"] }

# 2) Top-level pages of the old site. "/" is temporary: drop it once the new root
#    site is live (see the runbook).
pairs += [
  ["/",                  "#{SUB}/"],
  ["/about/",            "#{SUB}/about/"],
  ["/contact.html",      "#{SUB}/contact.html"],
  ["/request.html",      "#{SUB}/request.html"],
  ["/legal.html",        "#{SUB}/legal.html"],
  ["/terms.html",        "#{SUB}/terms.html"],
  ["/privacy-policy.html", "#{SUB}/privacy-policy.html"],
  ["/disclosure.html",   "#{SUB}/disclosure.html"],
  ["/admin.html",        "#{SUB}/admin.html"],
  ["/login.html",        "#{SUB}/login.html"]
]

FileUtils.mkdir_p(File.dirname(out))
File.open(out, "w:UTF-8") do |file|
  pairs.each do |from, to|
    # SOURCE,TARGET,301,PRESERVE_QUERY_STRING
    file.puts "https://#{host}#{from},https://#{host}#{to},301,TRUE"
  end
end

puts "Wrote #{pairs.size} redirects for #{host} to #{out}"
