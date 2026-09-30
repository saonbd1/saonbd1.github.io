# Adds `redirect_from` front-matter to every page so old /light-seo-tools/... URLs
# soft-redirect (via jekyll-redirect-from) to their current root URLs.
# UTF-8 safe (unlike the earlier PowerShell attempt).

require 'fileutils'

root = File.expand_path('..', __dir__)

def inject_redirect(path, old_urls)
  content = File.read(path, encoding: 'UTF-8')
  unless content.lstrip.start_with?('---')
    puts "SKIP (no front matter): #{path}"
    return
  end
  if content =~ /^redirect_from:/i
    puts "KEEP (already has redirect): #{path}"
    return
  end

  list = old_urls.map { |u| "  - #{u}" }.join("\n")
  inject = "redirect_from:\n#{list}\n\n"
  new_content = content.sub(/\A---\r?\n/, "---\n" + inject)
  File.write(path, new_content, encoding: 'UTF-8')
  puts "ADDED: #{path}"
rescue => e
  puts "ERR #{path}: #{e.message}"
end

# Tool pages
Dir.glob(File.join(root, 'tools', '*.md')).each do |f|
  next if File.basename(f) == 'README.md'
  name = File.basename(f, '.md')
  inject_redirect(f, [
    "/light-seo-tools/#{name}/",
    "/light-seo-tools/tools/#{name}.html"
  ])
end

# Top-level pages
pages = {
  'index.md'          => ['/light-seo-tools/'],
  'request.html'      => ['/light-seo-tools/request.html'],
  'contact.html'      => ['/light-seo-tools/contact.html'],
  'about.markdown'    => ['/light-seo-tools/about/'],
  'legal.html'        => ['/light-seo-tools/legal.html'],
  'terms.html'        => ['/light-seo-tools/terms.html'],
  'privacy-policy.html' => ['/light-seo-tools/privacy-policy.html'],
  'disclosure.html'   => ['/light-seo-tools/disclosure.html'],
  'admin.html'        => ['/light-seo-tools/admin.html'],
  'login.html'        => ['/light-seo-tools/login.html'],
}
pages.each do |f, olds|
  p = File.join(root, f)
  inject_redirect(p, olds) if File.exist?(p)
end

puts 'Done.'