require 'active_support'
require 'action_controller'
require 'sitemap/resources'
require 'zlib'

module Sitemap
  class Routes
    cattr_accessor :host
    cattr_writer :priority
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

      def add_result(result)
        @@results << result
      end

      def generate_xml
        parse
        
        sitemap_result_file = File.join(RAILS_ROOT, 'public/sitemap.xml')  
        File.open(sitemap_result_file, 'w') do |file|
          to_xml(file)
        end
      end
      
      def generate_xml_gz
        parse
        
        sitemap_result_file = File.join(RAILS_ROOT, 'public/sitemap.xml.gz')
        File.open(sitemap_result_file, 'w') do |f|
          gz = Zlib::GzipWriter.new(f)
          to_xml(gz)
          gz.close
        end
      end
      
      def to_xml(target)
        xml = Builder::XmlMarkup.new(:target => target, :indent => 2)
        xml.instruct!
        xml.urlset(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9") do
          @@results.each do |result|
            xml.url do
              xml.loc(@@host + result[:location])
              xml.priority result[:priority]
              xml.lastmod((result[:lastmod] || Time.now).strftime("%Y-%m-%d"))
            end
          end
        end
      end

      def parse
        @@results = []
        @@routes.each do |route|
          if route[:options][:substitution]
            parse_path_with_substitution(route[:path], route[:options])
          else
            parse_path_without_substitution(route[:path], route[:options], '', nil)
          end
        end
        @@results.uniq!
      end
      
      # Parse path without substitution option. It checks url two by two (split by '/') from left to right recursively.
      # If the second item starts with ':' and ends with 'id', replace it with the to_param of the model object.
      # For example, the path is /categories/:category_id/posts/:id, 
      # :category_id is replaced by category.to_param and :id is replaced by post.to_param.
      def parse_path_without_substitution(path, options, prefix, parent)
        begin
          items = path.split('/')
          if items[2].nil?
            # only one item, stop parsing.
            add_result :location => prefix + path, :changefreq => options[:changefreq], :priority => options[:priority] || @@priority
          elsif items[2] =~ /^:.*id$/
            # second item is an 'id', replace it.
            objects = parent.nil? ? Object.const_get(items[1].singularize.camelize).all : parent.send(items[1])
            objects.each do |obj|
              if items.size > 3
                parse_path_without_substitution('/' + items[3..-1].join('/'), options, "#{prefix}/#{items[1]}/#{obj.to_param}", obj)
              else
                add_result :location => "#{prefix}/#{items[1]}/#{obj.to_param}", :changefreq => options[:changefreq], :priority => options[:priority] || @@priority, :lastmod => (obj.respond_to?(:updated_at) ? obj.updated_at : nil)
              end
            end
            return nil
          else
            # the path is like '/posts/pages/:page_id', second item is not an 'id', continue to parse.
            if items.size > 2
              parse_path_without_substitution('/' + items[2..-1].join('/'), options, "#{prefix}/#{items[1]}", nil)
            else
              add_result :location => prefix + path, :changefreq => options[:changefreq], :priority => options[:priority] || @@priority
            end
          end
        rescue
          puts "can't parse prefix: #{prefix}, path: #{path}, parent: #{parent}"
        end
      end
      
      # Parse connect path or named route path who has a substitution option, such as: 
      # map.connect 'posts/:year/:month/:day', :substitution => {:model => 'Post', :year => year, :month => month, :day => day} or
      # map.connect 'posts/:locale, :substitution => {:locale => ['en', 'zh', 'fr']}
      def parse_path_with_substitution(path, options)
        begin
          substitution = options[:substitution]
          model_name = substitution.delete(:model)
          if model_name.nil?
            key = substitution.keys.first
            substitution.values.first.each do |value|
              path_dup = path.dup
              path_dup.gsub!(':' + key.to_s, value)
              add_result :location => path_dup, :changefreq => options[:changefreq], :priority => options[:priority] || @@priority
            end
          else
            klazz = Object.const_get(model_name)
            klazz.all.each do |obj|
              path_dup = path.dup
              substitution.each do |key, value|
                path_dup.gsub!(':' + key.to_s, obj.send(value).to_s)
              end
              add_result :location => path_dup, :changefreq => options[:changefreq], :priority => options[:priority] || @@priority
            end
          end
        rescue
          puts "can't parse prefix: #{prefix}, path: #{path}, parent: #{parent}"
        end
      end
    end
  end

  class ChangeFreq
    %w(always hourly daily weekly monthly yearly never).each do |const|
      const_set(const.upcase, const)
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
      add_route('', options)
    end

    def connect(path, options = {})
      add_route(path, options)
    end

    def add_route(path, options = {})
      path = '/' + path if path != '' and !path.start_with?('/')
      Routes.add_route(path, options)
    end

    def method_missing(route_name, *args, &proc)
      add_route(*args)
    end
  end
end
