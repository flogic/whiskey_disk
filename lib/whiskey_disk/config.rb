require 'yaml'
require 'uri'
require 'open-uri'
require 'whiskey_disk/filter'

class WhiskeyDisk
  class Config
    def fetch
      raise "Cannot determine current environment -- try rake ... to=staging, for example." unless environment_name
      filter_data(load_data)
    end

    def debug?
      env_flag_is_true?('debug')
    end
    
    def domain_limit
      env_key_or_false?('only')
    end
    
    def check_staleness?
      env_flag_is_true?('check')
    end
    
    def configuration_file
      return path if valid_path?(path)
      
      files = []

      files += [
        File.join(base_path, 'deploy', specified_project_name, "#{environment_name}.yml"),  # /deploy/foo/staging.yml
        File.join(base_path, 'deploy', "#{specified_project_name}.yml") # /deploy/foo.yml
      ] if specified_project_name

      files += [
        File.join(base_path, 'deploy', "#{environment_name}.yml"),  # /deploy/staging.yml
        File.join(base_path, "#{environment_name}.yml"), # /staging.yml
        File.join(base_path, 'deploy.yml') # /deploy.yml
      ]

      files.each { |file|  return file if File.exists?(file) }

      raise "Could not locate configuration file in path [#{base_path}]"
    end

    def environment_name
      return false unless env_has_key?('to')
      return ENV['to'] unless ENV['to'] =~ /:/
      ENV['to'].split(/:/)[1]
    end

    def specified_project_name
      return false unless env_has_key?('to')
      return false unless ENV['to'] =~ /:/
      ENV['to'].split(/:/).first
    end
    
    def contains_rakefile?(path)
      File.exists?(File.expand_path(File.join(path, 'Rakefile')))
    end

    def find_rakefile_from_current_path
      original_path = Dir.pwd
      while (!contains_rakefile?(Dir.pwd))
        return File.join(original_path, 'config') if Dir.pwd == '/'
        Dir.chdir('..')
      end
      File.join(Dir.pwd, 'config')
    ensure
      Dir.chdir(original_path)
    end

    def base_path
      path || find_rakefile_from_current_path
    end

    def valid_path?(path)
      return false unless path
      uri = URI.parse(path)
      return path if uri.scheme
      return path if File.file?(path)
    end

    def project_name
      specified_project_name || 'unnamed_project'
    end

    # called only by #load_data
    def configuration_data
      open(configuration_file) {|f| f.read }
    end

    # called only by #fetch
    def load_data
      YAML.load(configuration_data)
    rescue Exception => e
      raise %Q{Error reading configuration file [#{configuration_file}]: "#{e}"}
    end
    
    def add_environment_name(data)
      data.merge( { 'environment' => environment_name } )
    end

    def add_project_name(data)
      data.merge( { 'project' => project_name } )
    end

    def default_config_target(data)
      return data if data['config_target']
      data.merge( { 'config_target' => environment_name })
    end
    
    def filter
      @filter ||= WhiskeyDisk::Config::Filter.new(self)
    end
    
    # called only by #fetch
    def filter_data(data)
      filter.filter_data(data)
    end

  private

    def path
      env_key_or_false?('path')
    end

    def env_has_key?(key)
      ENV[key] && ENV[key] != ''
    end

    def env_flag_is_true?(key)
      !!(env_has_key?(key) && ENV[key] =~ /^(?:t(?:rue)?|y(?:es)?|1)$/)
    end

    def env_key_or_false?(key)
      env_has_key?(key) ? ENV[key] : false
    end  
  end
end
