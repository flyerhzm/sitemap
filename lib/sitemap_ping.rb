require 'net/http'
require 'uri'
require 'cgi'

module Sitemap
  
  class SearchEngine
    GOOGLE = 'http://www.google.com/webmasters/tools/ping?sitemap='
    BING = 'http://cn.bing.com/webmaster/ping.aspx?siteMap='
    YAHOO = 'http://search.yahooapis.com/SiteExplorerService/V1/ping?sitemap='
    ASK = 'http://submissions.ask.com/ping?sitemap='

    class <<self
      def ping_google
        ping(GOOGLE)
      end
    
      def ping_bing
        ping(BING)
      end
    
      def ping_yahoo
        ping(YAHOO)
      end
    
      def ping_ask
        ping(ASK)
      end
    
      def ping(url)
        Net::HTTP.get_print URI.parse(url + CGI::escape(Sitemap::Routes.host + '/sitemap.xml'))
      end
    end
  end
end
