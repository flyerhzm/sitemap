require 'builder'

namespace :sitemap do
  desc "generate sitemap.xml"
  task :generate => :environment do
    sitemap_configure_file = File.join(RAILS_ROOT, 'config/sitemap.rb')
    sitemap_result_file = File.join(RAILS_ROOT, 'public/sitemap.xml')
    load(sitemap_configure_file)
    Sitemap::Routes.generate(sitemap_result_file)
  end

  desc "ping search engine to update sitemap.xml (or specify SEARCH_ENGINE=names, splitted by comma)"
  task :ping => :generate do
    engines = ENV['SEARCH_ENGINE'].nil? ? ['google', 'bing', 'yahoo', 'ask'] : ENV['SEARCH_ENGINE'].split(',')
    engines.each do |engine|
      Sitemap::SearchEngine.send("ping_#{engine}")
    end
  end
end
