require 'active_support'
require 'action_controller'

module Sitemap
  class Routes
    cattr_writer :host
    cattr_reader :paths

    class << self
      include ActiveSupport::Inflector
    end

    def self.draw
      @@routes = []
      yield Mapper.new(self)
    end

    def self.named_routes
      {}
    end

    def self.add_route(path, options)
      @@routes ||= []
      @@routes << {:path => path, :options => options}
    end

    def self.generate(sitemap_result_file)
      parse

      File.open(sitemap_result_file, 'w') do |file|
        xml = Builder::XmlMarkup.new(:target => file, :indent => 2)
        xml.instruct!
        xml.urlset(:xmlns => "http://www.sitemaps.org/schema/sitemap/0.9") do
          @@paths.each do |path|
            xml.url do
              xml.loc(@@host + path)
            end
          end
        end
      end
    end

    def self.parse
      @@paths = []
      @@routes.each do |route|
        parse_path(route[:path], '', nil)
      end
    end

    def self.parse_path(path, prefix, parent)
      items = path.split('/')
      if items[2].nil?
        @@paths << prefix + path
      elsif items[2].start_with?(':')
        objects = parent.nil? ? Object.const_get(items[1].singularize.camelize).all : parent.send(items[1])
        objects.each do |obj|
          if items.size > 3
            parse_path('/' + items[3..-1].join('/'), "#{prefix}/#{items[1]}/#{obj.to_param}", obj)
          else
            @@paths << "#{prefix}/#{items[1]}/#{obj.to_param}"
          end
        end
        return nil
      else
        if items.size > 2
          parse_path('/' + items[2..-1].join('/'), "#{prefix}/#{items[1]}", nil)
        else
          @@paths << prefix + path
        end
      end
    end
  end

  class Mapper
    include ActionController::Resources

    def initialize(set)
      @set = set
    end

    def connect(path, options = {})
      add_route(path, options)
    end

    def named_route(name, path, options = {})
      path.gsub!('.:format', '')
      if options[:conditions][:method] == :get and !['new', 'create', 'edit', 'update', 'destroy'].include?(options[:action].to_s)
        add_route(path, options)
      end
    end

    def root(options = {})
      add_route('')
    end

    def add_route(path, options = {})
      Sitemap::Routes.add_route(path, options)
    end
  end
end
