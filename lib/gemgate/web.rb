require "sinatra/base"

module Gemgate
  class Web < Sinatra::Base

    class << self
      attr_accessor :repository
    end

    def self.env!(name)
      ENV[name] or raise "ENV[#{name}] must be set"
    end


    configure :test do
      enable :raise_errors
    end

    disable :show_exceptions

    post "/" do
      repository.add_gem(params[:file][:tempfile].path)

      status 200
    end

    private

    def repository
      @repository ||= self.class.repository || Repository.new
    end

  end
end
