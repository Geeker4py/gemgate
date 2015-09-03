require "sinatra/base"

module Gemgate
  class Web < Sinatra::Base

    class << self
      attr_accessor :repository
    end

    def self.env!(name)
      ENV[name] or raise "ENV[#{name}] must be set"
    end

    use Gemgate::Bartender

    configure :test do
      enable :raise_errors
    end

    disable :show_exceptions

    get "/api/v1/dependencies" do
      query_gems.any? ? Marshal.dump(combined_gem_list) : 200
    end

    post "/" do
      repository.add_gem(params[:file][:tempfile].path)

      status 200
    end

    private

    def repository
      @repository ||= self.class.repository || Repository.new
    end

    def query_gems
      params[:gems].to_s.split(',')
    end

    def all_gems
      all_gems_with_duplicates.inject(:|)
    end

    def all_gems_with_duplicates
      specs_files_paths.map do |specs_file_path|
        if File.exists?(specs_file_path)
          Marshal.load(Gem.gunzip(Gem.read_binary(specs_file_path)))
        else
          []
        end
      end
    end

    def specs_file_types
      [:specs, :prerelease_specs]
    end

    def specs_files_paths
      specs_file_types.map do |specs_file_type|
        File.join(File.dirname(__FILE__), spec_file_name(specs_file_type))
      end
    end

    def spec_file_name(specs_file_type)
      [specs_file_type, Gem.marshal_version, 'gz'].join('.')
    end

    def load_gems
      @loaded_gems ||= Gemgate::GemVersionCollection.new(all_gems)
    end

    def local_gem_list
      query_gems.map{|query_gem| gem_dependencies(query_gem) }.flatten(1)
    end

    def remote_gem_list
      RubygemsDependency.for(*query_gems)
    end

    def combined_gem_list
      GemListMerge.from(local_gem_list, remote_gem_list)
    end

    def gem_dependencies(gem_name)
      dependency_cache.marshal_cache(gem_name) do
        load_gems.
          select { |gem| gem_name == gem.name }.
          map    { |gem| [gem, spec_for(gem.name, gem.number, gem.platform)] }.
          reject { |(_, spec)| spec.nil? }.
          map do |(gem, spec)|
            {
              :name => gem.name,
              :number => gem.number.version,
              :platform => gem.platform,
              :dependencies => runtime_dependencies(spec)
            }
          end
      end
    end

    def dependency_cache
      @dependency_cache ||= Gemgate::DiskCache.new(File.join(File.dirname(__FILE__), "_cache"))
    end

    def runtime_dependencies(spec)
      spec.
        dependencies.
        select { |dep| dep.type == :runtime }.
        map    { |dep| name_and_requirements_for(dep) }
    end

    def name_and_requirements_for(dep)
      name = dep.name.kind_of?(Array) ? dep.name.first : dep.name
      [name, dep.requirement.to_s]
    end

  end
end
