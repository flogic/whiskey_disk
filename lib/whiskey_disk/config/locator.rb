class WhiskeyDisk
  class Config
    class Locator
      attr_reader :env
  
      def initialize(env)
        @env = env
      end
  
      def path
        env.path
      end
  
      def specified_project_name
        env.specified_project_name
      end

      def environment_name
        env.environment_name
      end

      def location
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
    end
  end
end
