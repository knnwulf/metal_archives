require 'faraday'

module MetalArchives
  class << self
    ##
    # Retrieve a rdoc-ref:HTTPClient instance
    #
    def client
      @client ||= HTTPClient.new
    end
  end

  ##
  # HTTP request client
  #
  class HTTPClient # :nodoc:
    ##
    # Get a http client
    #
    def http
      raise MetalArchives::Errors::InvalidConfigurationError, 'Not configured yet' unless MetalArchives.config

      @faraday ||= Faraday.new do |f|
        f.request   :url_encoded            # form-encode POST params
        f.adapter   Faraday.default_adapter
        f.response  :logger if !!MetalArchives.config.debug      # log requests to STDOUT
        f.use       MetalArchives::Middleware
      end
    end
  end

  ##
  # Faraday middleware
  #
  class Middleware < Faraday::Middleware # :nodoc:
    def call(env)
      env[:request_headers].merge!(
        'User-Agent'  => user_agent_string,
        'Via'         => via_string,
        'Accept'      => accept_string
      )
      @app.call(env)
    end

    private
      def user_agent_string
        "#{MetalArchives.config.app_name}/#{MetalArchives.config.app_version} ( #{MetalArchives.config.app_contact} )"
      end

      def accept_string
        'application/json'
      end

      def via_string
        "gem metal_archives/#{VERSION}"
      end
  end
end
