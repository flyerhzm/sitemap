require 'builder'

namespace :sitemap do
  desc "generate sitemap.xml (or specify FORMAT=gzip to generate sitemap.xml.gz)"
  task :generate => :environment do
    sitemap_configure_file = File.join(RAILS_ROOT, 'config/sitemap.rb')
    load(sitemap_configure_file)
    if ENV['FORMAT'].nil? || ENV['FORMAT'] == 'xml'
      Sitemap::Routes.generate_xml
    elsif ENV['FORMAT'] == 'gzip'
      Sitemap::Routes.generate_xml_gz
    end      
  end

  desc "ping search engine to update sitemap.xml (or specify SEARCH_ENGINE=names, splitted by comma)"
  task :ping => :environment do
    sitemap_configure_file = File.join(RAILS_ROOT, 'config/sitemap.rb')
    load(sitemap_configure_file)
    engines = ENV['SEARCH_ENGINE'].nil? ? %w(google bing yahoo ask) : ENV['SEARCH_ENGINE'].split(',')
    engines.each do |engine|
      Sitemap::SearchEngine.send("ping", engine, ENV['FORMAT'] || 'xml')
    end
  end
end
