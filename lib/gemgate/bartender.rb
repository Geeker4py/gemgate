require "sinatra/base"

module Gemgate
  class Bartender < Sinatra::Base

    %w[/specs.4.8.gz
       /latest_specs.4.8.gz
       /prerelease_specs.4.8.gz
       /quick/Marshal.4.8/*.gemspec.rz
       /gems/*.gem
    ].each do |index|
      get index do
        redirect to transfered_index(index)
      end
    end

    private

    def transfered_index(index)
      if splat = params["splat"]
        index.sub!(/\*/, splat[0])
      end

      File.join storage.get_path, index
    end

    def storage
      @storage ||= Storage::S3.new
    end

  end
end
