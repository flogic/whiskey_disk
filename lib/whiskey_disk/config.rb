require 'yaml'

class WhiskeyDisk
  class Config
    class << self
      def environment_name
        (ENV['to'] && ENV['to'] != '') ? ENV['to'] : false
      end
      
      def path
        (ENV['path'] && ENV['path'] != '') ? ENV['path'] : false
      end
      
      def project
        'whiskey_disk'
      end
      
      def contains_rakefile?(path)
        File.exists?(File.expand_path(File.join(path, 'Rakefile')))
      end
      
      def find_rakefile_from_current_path
        while (!contains_rakefile?(Dir.pwd))
          raise "Could not find Rakefile in the current directory tree!" if Dir.pwd == '/'
          Dir.chdir('..')
        end
        File.join(Dir.pwd, 'config')
      end
      
      def base_path
        return path if path
        find_rakefile_from_current_path
      end
      
      def configuration_file
        return path if path and File.file?(path)
        
        [ 
          File.join(base_path, 'deploy', "#{environment_name}.yml"),
          File.join(base_path, "#{environment_name}.yml"), 
          File.join(base_path, 'deploy.yml') 
        ].each { |file|  return file if File.exists?(file) }
        
        raise "Could not locate configuration file in path [#{base_path}]"
      end
      
      def configuration_data
        raise "Configuration file [#{configuration_file}] not found!" unless File.exists?(configuration_file)
        File.read(configuration_file)
      end
      
      def project_name(config)
        return '' unless config['repository'] and config['repository'] != ''
        config['repository'].sub(%r{^.*[/:]}, '').sub(%r{\.git$}, '')
      end
      
      def has_repository_data?(data)
        raise "Expected configuration data to be a hash!" unless data.respond_to?(:has_key?)
        data.has_key?('repository') and !data['repository'].respond_to?(:keys)
      end
      
      # is this data hash a bottom-level data hash without an environment name?
      def needs_environment_scoping?(data)
        has_repository_data?(data)
      end
      
      # is this data hash an environment data hash without a project name?
      def needs_project_scoping?(data)
        has_repository_data?(data.values.first)
      end

      def normalize_data(original_data)
        data = original_data.clone
        data = { environment_name => data } if needs_environment_scoping?(data)
        data = { project => data }          if needs_project_scoping?(data)
        data
      end      
      
      def load_data
        normalize_data(YAML.load(configuration_data))
      rescue Exception => e
        raise %Q{Error reading configuration file [#{configuration_file}]: "#{e}"}
      end
      
      def fetch
        raise "Cannot determine current environment -- try rake ... to=staging, for example." unless environment_name
        data = load_data
        raise "No configuration file defined data for environment [#{environment_name}]" unless data[environment_name]
        config = (data[environment_name] || {}).merge({'environment' => environment_name})
        { 'project' => project_name(config) }.merge(config)
      end
    end
  end
end