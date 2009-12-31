require 'yaml'

class WhiskeyDisk
  class Config
    class << self
      def environment_name
        (ENV['to'] && ENV['to'] != '') ? ENV['to'] : false
      end
      
      def contains_rakefile?(path)
        File.exists?(File.expand_path(File.join(path, 'Rakefile')))
      end
      
      def base_path
        while (!contains_rakefile?(Dir.pwd))
          raise "Could not find Rakefile in the current directory tree!" if Dir.pwd == '/'
          Dir.chdir('..')
        end
        Dir.pwd
      end
      
      def main_configuration_file
        File.expand_path(File.join(base_path, 'config', 'deploy.yml'))
      end
      
      def main_configuration_data
        raise "Main configuration file [#{main_configuration_file}] not found!" unless File.exists?(main_configuration_file)
        File.read(main_configuration_file)
      end
      
      def environment_configuration_file
        raise "Cannot determine current environment -- try rake ... to=staging, for example." unless environment_name
        File.expand_path(File.join(base_path, 'config', "deploy-#{environment_name}.yml"))
      end
      
      def environment_configuration_data
        File.exists?(environment_configuration_file) ? File.read(environment_configuration_file) : nil
      rescue Exception => e
        raise %Q{Could not read configuration file [#{environment_configuration_file}] for environment [#{environment_name}]: "#{e}"}
      end
      
      def project_name(config)
        return '' unless config['repository'] and config['repository'] != ''
        config['repository'].sub(%r{^.*[/:]}, '').sub(%r{\.git$}, '')
      end
      
      def load_main_data
        YAML.load(main_configuration_data)
      rescue Exception => e
        raise %Q{Error reading configuration file [#{main_configuration_file}]: "#{e}"}
      end
      
      def load_environment_data        
        begin
          env = environment_configuration_data ? YAML.load(environment_configuration_data) : nil
        rescue Exception => e
          raise %Q{Error reading configuration file [#{environment_configuration_file}]: "#{e}"}
        end
        raise "Configuration file [#{environment_configuration_file}] does not define data for environment [#{environment_name}]" if env and !env[environment_name]
        env || {}
      end
      
      def fetch
        raise "Cannot determine current environment -- try rake ... to=staging, for example." unless environment_name
        main, env = load_main_data, load_environment_data
        raise "No configuration file defined data for environment [#{environment_name}]" unless main[environment_name] or env[environment_name]
        config = (main[environment_name] || {}).merge(env[environment_name] || {}).merge({'environment' => environment_name})
        { 'project' => project_name(config) }.merge(config)
      end
    
      def filenames
        raise "Cannot determine current environment -- try rake ... to=staging, for example." unless environment_name
        [ main_configuration_file, environment_configuration_file ]
      end
    end
  end
end