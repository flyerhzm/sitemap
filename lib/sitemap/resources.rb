module ActionController
  module Resources
    alias_method :origin_action_options_for, :action_options_for

    def action_options_for(action, resource, method = nil, resource_options = {})
      options = origin_action_options_for(action, resource, method, resource_options)
      resource.options.reject {|k, v| !['priority', 'changefreq'].include? k.to_s}.merge(options)
    end
  end
end
