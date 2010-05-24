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
      
      def load_data
        YAML.load(configuration_data)
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