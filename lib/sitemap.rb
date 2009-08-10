require 'active_support'
require 'action_controller'

module Sitemap
  class Routes
    cattr_writer :host, :priority
    cattr_reader :results
    @@priority = 1.0

    class << self
      include ActiveSupport::Inflector

      def draw
        @@routes = []
        yield Mapper.new(self)
      end

      def named_routes
        {}
      end

      def add_route(path, options)
        @@routes ||= []
        @@routes << {:path => path, :options => options}
      end

      def generate(sitemap_result_file)
        parse

        File.open(sitemap_result_file, 'w') do |file|
          xml = Builder::XmlMarkup.new(:target => file, :indent => 2)
          xml.instruct!
          xml.urlset(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9") do
            now = Time.now.strftime("%Y-%m-%d")
            @@results.each do |result|
              xml.url do
                xml.loc(@@host + result[:location])
                xml.priority result[:priority]
                xml.lastmod now
              end
            end
          end
        end
      end

      def parse
        @@results = []
        @@routes.each do |route|
          parse_path(route[:path], route[:options], '', nil)
        end
        @@results.uniq!
      end

      def parse_path(path, options, prefix, parent)
        priority = options[:priority] || @@priority
        begin
          if options[:substitution]
            substitution = options[:substitution]
            model_name = substitution.delete(:model)
            klazz = Object.const_get(model_name)
            klazz.all.each do |obj|
              path_dup = path.dup
              substitution.each do |key, value|
                path_dup.gsub!(':' + key.to_s, obj.send(value).to_s)
              end
              @@results << {:location => path_dup, :priority => priority}
            end
          else
            items = path.split('/')
            if items[2].nil?
              @@results << {:location => prefix + path, :priority => priority}
            elsif items[2] =~ /^:.*id$/
              objects = parent.nil? ? Object.const_get(items[1].singularize.camelize).all : parent.send(items[1])
              objects.each do |obj|
                if items.size > 3
                  parse_path('/' + items[3..-1].join('/'), options, "#{prefix}/#{items[1]}/#{obj.to_param}", obj)
                else
                  @@results << {:location => "#{prefix}/#{items[1]}/#{obj.to_param}", :priority => priority}
                end
              end
              return nil
            else
              if items.size > 2
                parse_path('/' + items[2..-1].join('/'), options, "#{prefix}/#{items[1]}", nil)
              else
                @@results << {:location => prefix + path, :priority => priority}
              end
            end
          end
        rescue
          puts "can't parse prefix: #{prefix}, path: #{path}, parent: #{parent}"
        end
      end
    end
  end

  class Mapper
    include ActionController::Resources

    def initialize(set)
      @set = set
    end

    def named_route(name, path, options = {})
      path.gsub!('.:format', '')
      if options[:conditions][:method] == :get and !['new', 'create', 'edit', 'update', 'destroy'].include?(options[:action].to_s)
        add_route(path, options)
      end
    end

    def namespace(name, &block)
      with_options({:path_prefix => name, :name_prefix => "#{name}_", :namespace => "#{name}/"}, &block)
    end

    def root(options = {})
      add_route('')
    end

    def connect(path, options = {})
      add_route(path, options)
    end

    def add_route(path, options = {})
      path = '/' + path if path != '' and !path.start_with?('/')
      Sitemap::Routes.add_route(path, options)
    end

    def method_missing(route_name, *args, &proc)
      add_route(*args)
    end
  end
end
