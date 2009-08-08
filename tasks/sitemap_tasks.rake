require 'builder'

namespace :sitemap do
  desc "generate sitemap"
  task :generate => :environment do
    sitemap_configure_file = File.join(RAILS_ROOT, 'config/sitemap.rb')
    sitemap_result_file = File.join(RAILS_ROOT, 'public/sitemap.xml')
    load(sitemap_configure_file)
    Sitemap::Routes.generate(sitemap_result_file)
  end
end
