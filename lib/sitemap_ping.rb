require 'net/http'
require 'uri'
require 'cgi'

module Sitemap
  
  class SearchEngine
    GOOGLE = 'http://www.google.com/webmasters/tools/ping?sitemap='
    BING = 'http://com.bing.com/webmaster/ping.aspx?siteMap='
    YAHOO = 'http://search.yahooapis.com/SiteExplorerService/V1/ping?sitemap='
    ASK = 'http://submissions.ask.com/ping?sitemap='

    class <<self
      def ping(engine, format)
        url = case engine
              when 'google'
                GOOGLE
              when 'bing'
                BING
              when 'yahoo'
                YAHOO
              when 'ask'
                ASK
              end
        sitemap_file = (format == 'gzip' ?  '/sitemap.xml.gz' : '/sitemap.xml')
        Net::HTTP.get_print URI.parse(url + CGI::escape(Sitemap::Routes.host + sitemap_file))
      end
    end
  end
end
