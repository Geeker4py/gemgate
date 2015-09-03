module Gemgate
  module RubygemsDependency

    class << self

      def for(*gems)
        resource = "/api/v1/dependencies.json?gems=#{gems.map(&:to_s).join(',')}"
        conn = client.get(resource)
        conn.body
      end

      private

      def client
        conn = Faraday.new(url: rubygems_uri) do |conn|
          conn.request  :url_encoded
          conn.response :json
          conn.adapter  Faraday.default_adapter
        end
      end

      def rubygems_uri
        "https://bundler.rubygems.org"
      end
    end
  end
end
