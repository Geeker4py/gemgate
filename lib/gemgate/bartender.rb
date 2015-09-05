require "sinatra/base"

module Gemgate
  class Bartender < Sinatra::Base

    %w[/specs.4.8.gz
       /latest_specs.4.8.gz
       /prerelease_specs.4.8.gz
       /quick/Marshal.4.8/*.gemspec.rz
    ].each do |index|
      get index do
        redirect transfered_index(index)
      end
    end

    get "/gems/*.gem" do
      redirect source_on_rubygems
    end

    private

    def transfered_index(index)
      if splat = params["splat"]
        index.sub!(/\*/, splat[0])
      end

      File.join storage.get_path, index
    end

    def source_on_rubygems
      File.join rubygems_uri, *request.path_info
    end

    def rubygems_uri
      "https://d2chzxaqi4y7f8.cloudfront.net"
    end

    def storage
      @storage ||= Storage::S3.new
    end

  end
end
